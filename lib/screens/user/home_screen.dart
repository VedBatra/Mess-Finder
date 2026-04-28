// lib/screens/user/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/mess_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).valueOrNull;
    final messesAsync = ref.watch(nearbyMessesProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(nearbyMessesProvider);
        },
        child: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 24),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.fullName ?? 'Foodie',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Profile avatar
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search for mess, area...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.textLight,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textLight),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppTheme.textLight, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category Chips ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  _CategoryChip(
                      icon: Icons.restaurant_rounded,
                      label: 'All',
                      selected: true),
                  const SizedBox(width: 10),
                  _CategoryChip(
                      icon: Icons.wb_sunny_rounded,
                      label: 'Lunch',
                      selected: false),
                  const SizedBox(width: 10),
                  _CategoryChip(
                      icon: Icons.nightlight_rounded,
                      label: 'Dinner',
                      selected: false),
                  const SizedBox(width: 10),
                  _CategoryChip(
                      icon: Icons.delivery_dining,
                      label: 'Delivery',
                      selected: false),
                ],
              ),
            ),
          ),

          // ── Section Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                children: [
                  Text(
                    'Nearby Messes',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📍 3km',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Mess List ──
          messesAsync.when(
            data: (messes) {
              final filtered = _searchQuery.isEmpty
                  ? messes
                  : messes
                      .where((m) =>
                          m.messName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          m.address
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.search_off_rounded,
                                size: 40, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No messes found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try changing your search or location',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => MessCard(
                    mess: filtered[i],
                    onTap: () => context.push('/mess/${filtered[i].id}'),
                  ),
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => _ShimmerCard(),
                childCount: 4,
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(nearbyMessesProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryColor
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected ? AppTheme.primaryShadow : AppTheme.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
