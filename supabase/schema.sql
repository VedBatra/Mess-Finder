-- ============================================================
-- MESS FINDER - Supabase Database Schema
-- Run this entire script in Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable PostGIS for location search
create extension if not exists postgis;

-- ============================================================
-- TABLE: profiles
-- ============================================================
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  role       text not null default 'user' check (role in ('user', 'owner', 'admin')),
  full_name  text not null default '',
  phone      text,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- TABLE: messes
-- ============================================================
create table if not exists public.messes (
  id                    uuid primary key default gen_random_uuid(),
  owner_id              uuid not null references public.profiles(id) on delete cascade,
  mess_name             text not null,
  address               text not null default '',
  latitude              double precision not null default 0,
  longitude             double precision not null default 0,
  location              geography(Point, 4326),
  lunch_cutoff          time,
  dinner_cutoff         time,
  one_time_lunch_price  integer not null default 0,
  one_time_dinner_price integer not null default 0,
  offers_delivery       boolean not null default false,
  delivery_charge       integer not null default 0,
  packaging_charge      integer not null default 0,
  upi_id                text,
  status                text not null default 'approved' check (status in ('pending', 'approved', 'rejected')),
  is_sold_out           boolean not null default false,
  image_url             text,
  created_at            timestamptz not null default now()
);

-- Sync geography column from lat/lng
create or replace function public.sync_mess_location()
returns trigger language plpgsql as $$
begin
  if new.latitude is not null and new.longitude is not null then
    new.location := st_setsrid(st_makepoint(new.longitude, new.latitude), 4326)::geography;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_location on public.messes;
create trigger sync_location
  before insert or update on public.messes
  for each row execute procedure public.sync_mess_location();

-- Index for fast spatial search
create index if not exists messes_location_idx on public.messes using gist(location);

-- ============================================================
-- TABLE: menus
-- ============================================================
create table if not exists public.menus (
  id          uuid primary key default gen_random_uuid(),
  mess_id     uuid not null references public.messes(id) on delete cascade,
  day_of_week text not null,
  meal_type   text not null check (meal_type in ('lunch', 'dinner')),
  items       text[] not null default '{}',
  created_at  timestamptz not null default now(),
  unique(mess_id, day_of_week, meal_type)
);

-- ============================================================
-- TABLE: orders
-- ============================================================
create table if not exists public.orders (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  mess_id          uuid not null references public.messes(id) on delete cascade,
  meal_type        text not null check (meal_type in ('lunch', 'dinner')),
  order_date       date not null default current_date,
  fulfillment_type text not null check (fulfillment_type in ('dine-in', 'takeaway', 'delivery')),
  total_amount     integer not null default 0,
  payment_method   text not null check (payment_method in ('upi', 'cash')),
  status           text not null default 'pending'
                   check (status in ('pending', 'accepted', 'ready', 'completed', 'cancelled')),
  created_at       timestamptz not null default now()
);

-- Index for fast owner queries
create index if not exists orders_mess_id_idx on public.orders(mess_id, order_date);
create index if not exists orders_user_id_idx on public.orders(user_id);

-- ============================================================
-- TABLE: reviews
-- ============================================================
create table if not exists public.reviews (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  mess_id     uuid not null references public.messes(id) on delete cascade,
  order_id    uuid not null references public.orders(id) on delete cascade,
  rating      integer not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now(),
  unique(order_id) -- one review per order
);

-- ============================================================
-- RPC: get_nearby_messes
-- Returns approved messes within radius_meters of (user_lat, user_lng)
-- with distance_meters calculated
-- ============================================================
create or replace function public.get_nearby_messes(
  user_lat      double precision,
  user_lng      double precision,
  radius_meters double precision default 3000
)
returns table (
  id                    uuid,
  owner_id              uuid,
  mess_name             text,
  address               text,
  latitude              double precision,
  longitude             double precision,
  lunch_cutoff          time,
  dinner_cutoff         time,
  one_time_lunch_price  integer,
  one_time_dinner_price integer,
  offers_delivery       boolean,
  delivery_charge       integer,
  packaging_charge      integer,
  upi_id                text,
  status                text,
  is_sold_out           boolean,
  image_url             text,
  created_at            timestamptz,
  distance_meters       double precision,
  rating                double precision,
  total_reviews         bigint
)
language plpgsql security definer as $$
declare
  user_point geography;
begin
  user_point := st_setsrid(st_makepoint(user_lng, user_lat), 4326)::geography;
  return query
  select
    m.id, m.owner_id, m.mess_name, m.address,
    m.latitude, m.longitude,
    m.lunch_cutoff, m.dinner_cutoff,
    m.one_time_lunch_price, m.one_time_dinner_price,
    m.offers_delivery, m.delivery_charge, m.packaging_charge,
    m.upi_id, m.status, m.is_sold_out, m.image_url, m.created_at,
    st_distance(m.location, user_point) as distance_meters,
    avg(r.rating)::double precision as rating,
    count(r.id) as total_reviews
  from public.messes m
  left join public.reviews r on r.mess_id = m.id
  where
    m.status = 'approved'
    and st_dwithin(m.location, user_point, radius_meters)
  group by m.id
  order by distance_meters asc;
end;
$$;


-- ============================================================
-- RPC: is_admin (Security Definer)
-- Used to prevent infinite recursion in RLS policies
-- ============================================================
create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ============================================================
-- ROW LEVEL SECURITY POLICIES

-- ============================================================

-- profiles
alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles"
  on public.profiles for select
  using (
    public.is_admin()
  );

-- messes
alter table public.messes enable row level security;

drop policy if exists "Anyone can read approved messes" on public.messes;
create policy "Anyone can read approved messes"
  on public.messes for select
  using (status = 'approved');

drop policy if exists "Owners can read own mess" on public.messes;
create policy "Owners can read own mess"
  on public.messes for select
  using (owner_id = auth.uid());

drop policy if exists "Owners can insert own mess" on public.messes;
create policy "Owners can insert own mess"
  on public.messes for insert
  with check (owner_id = auth.uid());

drop policy if exists "Owners can update own mess" on public.messes;
create policy "Owners can update own mess"
  on public.messes for update
  using (owner_id = auth.uid());

drop policy if exists "Admins have full mess access" on public.messes;
create policy "Admins have full mess access"
  on public.messes for all
  using (
    public.is_admin()
  );

-- menus
alter table public.menus enable row level security;

drop policy if exists "Anyone can read menus" on public.menus;
create policy "Anyone can read menus"
  on public.menus for select using (true);

drop policy if exists "Owners can manage own mess menus" on public.menus;
create policy "Owners can manage own mess menus"
  on public.menus for all
  using (
    exists (
      select 1 from public.messes m
      where m.id = mess_id and m.owner_id = auth.uid()
    )
  );

-- orders
alter table public.orders enable row level security;

drop policy if exists "Users can see own orders" on public.orders;
create policy "Users can see own orders"
  on public.orders for select
  using (user_id = auth.uid());

drop policy if exists "Users can insert own orders" on public.orders;
create policy "Users can insert own orders"
  on public.orders for insert
  with check (user_id = auth.uid());

drop policy if exists "Owners can see their mess orders" on public.orders;
create policy "Owners can see their mess orders"
  on public.orders for select
  using (
    exists (
      select 1 from public.messes m
      where m.id = mess_id and m.owner_id = auth.uid()
    )
  );

drop policy if exists "Owners can update order status" on public.orders;
create policy "Owners can update order status"
  on public.orders for update
  using (
    exists (
      select 1 from public.messes m
      where m.id = mess_id and m.owner_id = auth.uid()
    )
  );

drop policy if exists "Admins have full order access" on public.orders;
create policy "Admins have full order access"
  on public.orders for all
  using (
    public.is_admin()
  );

-- reviews
alter table public.reviews enable row level security;

drop policy if exists "Anyone can read reviews" on public.reviews;
create policy "Anyone can read reviews"
  on public.reviews for select using (true);

drop policy if exists "Users can insert own reviews" on public.reviews;
create policy "Users can insert own reviews"
  on public.reviews for insert
  with check (user_id = auth.uid());

drop policy if exists "Admins can delete reviews" on public.reviews;
create policy "Admins can delete reviews"
  on public.reviews for delete
  using (
    public.is_admin()
  );

-- ============================================================
-- REALTIME: enable realtime for orders table
-- ============================================================
DO $$
BEGIN
    if not exists (
        select 1 from pg_publication_tables 
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders'
    ) then
        alter publication supabase_realtime add table public.orders;
    end if;
END
$$;

-- ============================================================
-- DONE!
-- After running this script:
-- 1. Go to Supabase → Authentication → Settings
--    Enable "Email" provider
-- 2. Create an admin user manually:
--    Insert into profiles (id, role, full_name)
--    using your admin user's UUID
-- ============================================================
