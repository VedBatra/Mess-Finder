import re

with open('supabase/schema.sql', 'r') as f:
    content = f.read()

# Add the is_admin function right before ROW LEVEL SECURITY POLICIES
is_admin_func = """
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
"""

content = content.replace("-- ============================================================\n-- ROW LEVEL SECURITY POLICIES", is_admin_func)

# Now replace the inline admin check with public.is_admin()
# The inline check looks like:
#    exists (
#      select 1 from public.profiles p
#      where p.id = auth.uid() and p.role = 'admin'
#    )

admin_check_pattern = r"exists\s*\(\s*select 1 from public\.profiles p\s*where p\.id = auth\.uid\(\) and p\.role = 'admin'\s*\)"

content = re.sub(admin_check_pattern, "public.is_admin()", content)

with open('supabase/schema.sql', 'w') as f:
    f.write(content)
