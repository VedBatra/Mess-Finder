// lib/screens/owner/owner_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/mess_service.dart';
import '../../utils/app_theme.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    final ownerMessAsync = ref.watch(ownerMessProvider(profile.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ownerMessAsync.when(
        data: (mess) {
          if (mess == null) {
            return _EmptyMessState(
                onCreateTap: () => context.push('/owner/edit-mess'));
          }

          final analyticsAsync = ref.watch(messAnalyticsProvider(mess.id));

          return CustomScrollView(
            slivers: [
              // ── Gradient Header ──
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, MediaQuery.of(context).padding.top + 16, 24, 28),
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
                            child: Text(
                              'Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await ref.read(authProvider.notifier).signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.restaurant_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mess.messName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mess.address,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mess.status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sold-out toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.no_meals_rounded,
                                  color: AppTheme.errorColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mark as Sold Out',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  Text('Temporarily stop new orders',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: mess.isSoldOut,
                              activeTrackColor: AppTheme.errorColor,
                              onChanged: (v) {
                                MessService().toggleSoldOut(mess.id, v);
                                ref.invalidate(ownerMessProvider(profile.id));
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.receipt_long_rounded,
                              label: 'Orders',
                              color: AppTheme.primaryColor,
                              onTap: () => context.push('/owner/orders'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.edit_rounded,
                              label: 'Edit Mess',
                              color: AppTheme.secondaryColor,
                              onTap: () => context.push('/owner/edit-mess'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.menu_book_rounded,
                              label: 'Menu',
                              color: AppTheme.accentColor,
                              onTap: () => context.push('/owner/menu'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Today's analytics
                      Text(
                        "Today's Analytics",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      analyticsAsync.when(
                        data: (analytics) => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _AnalyticCard(
                                    label: 'Total Orders',
                                    value: '${analytics['total_orders']}',
                                    icon: Icons.receipt_rounded,
                                    gradient: AppTheme.primaryGradient,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AnalyticCard(
                                    label: 'Revenue',
                                    value: '₹${analytics['total_revenue']}',
                                    icon: Icons.currency_rupee_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2EC4B6),
                                        Color(0xFF1FA99C)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                    child: _MiniStat(
                                        icon: Icons.restaurant_rounded,
                                        label: 'Dine-in',
                                        value: '${analytics['dine_in']}',
                                        color: AppTheme.primaryColor)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _MiniStat(
                                        icon: Icons.shopping_bag_rounded,
                                        label: 'Takeaway',
                                        value: '${analytics['takeaway']}',
                                        color: AppTheme.secondaryColor)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _MiniStat(
                                        icon: Icons.delivery_dining_rounded,
                                        label: 'Delivery',
                                        value: '${analytics['delivery']}',
                                        color: AppTheme.successColor)),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryColor)),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EmptyMessState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyMessState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppTheme.primaryShadow,
              ),
              child:
                  const Icon(Icons.store_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text(
              'Set Up Your Mess!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your mess profile to start\nreceiving orders from customers.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text('Create Mess Profile',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient gradient;
  const _AnalyticCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
