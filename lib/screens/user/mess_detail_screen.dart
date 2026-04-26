// lib/screens/user/mess_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/mess.dart';
import '../../models/menu.dart';
import '../../providers/mess_provider.dart';
import '../../services/mess_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class MessDetailScreen extends ConsumerWidget {
  final String messId;
  const MessDetailScreen({super.key, required this.messId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messAsync = ref.watch(messDetailProvider(messId));

    return Scaffold(
      body: messAsync.when(
        data: (mess) {
          if (mess == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.restaurant_outlined,
                        size: 40, color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 16),
                  Text('Mess not found',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 18)),
                ],
              ),
            );
          }
          return _MessDetailBody(mess: mess);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MessDetailBody extends ConsumerStatefulWidget {
  final Mess mess;
  const _MessDetailBody({required this.mess});

  @override
  ConsumerState<_MessDetailBody> createState() => _MessDetailBodyState();
}

class _MessDetailBodyState extends ConsumerState<_MessDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Menu> _menus = [];
  bool _loadingMenus = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    final menus = await MessService().getMenuForMess(widget.mess.id);
    if (mounted) setState(() { _menus = menus; _loadingMenus = false; });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _todayName {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mess;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Premium App Bar ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  m.messName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Icon(Icons.restaurant_rounded,
                            size: 200, color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.restaurant_rounded,
                                  size: 44, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            if (m.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${m.rating!.toStringAsFixed(1)} (${m.totalReviews ?? 0})',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address + distance
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            m.address,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (m.distanceText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              m.distanceText,
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (m.isSoldOut) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.errorColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Sold out for today',
                              style: GoogleFonts.inter(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Price cards
                    Row(
                      children: [
                        Expanded(child: _PriceCard(
                            label: '☀️ Lunch',
                            price: m.oneTimeLunchPrice,
                            cutoff: m.lunchCutoff)),
                        const SizedBox(width: 14),
                        Expanded(child: _PriceCard(
                            label: '🌙 Dinner',
                            price: m.oneTimeDinnerPrice,
                            cutoff: m.dinnerCutoff)),
                      ],
                    ),

                    if (m.offersDelivery) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delivery_dining,
                                  color: AppTheme.secondaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delivery available · ₹${m.deliveryCharge}',
                              style: GoogleFonts.inter(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Google Maps preview
                    if (m.latitude != 0 && m.longitude != 0) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Location',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 160,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(m.latitude, m.longitude),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('mess'),
                                position: LatLng(m.latitude, m.longitude),
                                infoWindow: InfoWindow(title: m.messName),
                              ),
                            },
                            liteModeEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.softShadow,
                        ),
                        indicatorPadding: const EdgeInsets.all(4),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: "Today's Menu"),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _loadingMenus
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primaryColor))
                              : _TodayMenuView(
                                  menus: _menus, today: _todayName),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 40,
                                    color: AppTheme.textLight),
                                const SizedBox(height: 12),
                                Text(
                                  'Reviews available after ordering',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer for bottom bar
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Floating Order Bar ──
        if (!m.isSoldOut)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order Now',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Starting ₹${m.oneTimeLunchPrice}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _OrderButton(
                    label: '☀️ Lunch',
                    onTap: () => context.push(
                        '/checkout/${m.id}?meal=${AppConstants.mealTypeLunch}'),
                  ),
                  const SizedBox(width: 8),
                  _OrderButton(
                    label: '🌙 Dinner',
                    onTap: () => context.push(
                        '/checkout/${m.id}?meal=${AppConstants.mealTypeDinner}'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OrderButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final int price;
  final String? cutoff;
  const _PriceCard({required this.label, required this.price, this.cutoff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '₹$price',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          if (cutoff != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text('Cutoff: $cutoff',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayMenuView extends StatelessWidget {
  final List<Menu> menus;
  final String today;
  const _TodayMenuView({required this.menus, required this.today});

  @override
  Widget build(BuildContext context) {
    final todayMenus = menus.where((m) => m.dayOfWeek == today).toList();
    if (todayMenus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 40, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text("No menu listed for today",
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView(
      children: todayMenus.map((menu) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menu.mealType == 'lunch' ? '☀️ Lunch' : '🌙 Dinner',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: menu.items
                    .map((item) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
