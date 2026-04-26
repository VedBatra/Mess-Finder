// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mess.dart';
import '../../providers/auth_provider.dart';
import '../../services/mess_service.dart';
import '../../utils/app_theme.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Mess> _pendingMesses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPending();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final messes = await MessService().getPendingMesses();
    if (mounted) {
      setState(() { _pendingMesses = messes; _loading = false; });
    }
  }

  Future<void> _approve(String messId) async {
    await MessService().updateMessStatus(messId, 'approved');
    setState(() => _pendingMesses.removeWhere((m) => m.id == messId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mess approved! ✅',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _reject(String messId) async {
    await MessService().updateMessStatus(messId, 'rejected');
    setState(() => _pendingMesses.removeWhere((m) => m.id == messId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Mess rejected.', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 20),
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
                          'Admin Panel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 18),
                        label: Text('Logout',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_pendingMesses.length} pending approvals',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tabs ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
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
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Pending Messes'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab Body ──
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending messes
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor))
                    : _pendingMesses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 40,
                                      color: AppTheme.successColor),
                                ),
                                const SizedBox(height: 16),
                                Text('All caught up! ✨',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18)),
                                const SizedBox(height: 6),
                                Text('No pending approvals',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.primaryColor,
                            onRefresh: _loadPending,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              itemCount: _pendingMesses.length,
                              itemBuilder: (context, index) {
                                final mess = _pendingMesses[index];
                                return _AdminMessCard(
                                  mess: mess,
                                  onApprove: () => _approve(mess.id),
                                  onReject: () => _reject(mess.id),
                                );
                              },
                            ),
                          ),

                // Settings tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.settings_rounded,
                            size: 40, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 16),
                      Text('Coming Soon',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('Admin settings are under development',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMessCard extends StatelessWidget {
  final Mess mess;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminMessCard(
      {required this.mess, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mess.messName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(mess.address,
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                  label: 'Lunch ₹${mess.oneTimeLunchPrice}',
                  color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              _InfoChip(
                  label: 'Dinner ₹${mess.oneTimeDinnerPrice}',
                  color: AppTheme.secondaryColor),
              if (mess.offersDelivery) ...[
                const SizedBox(width: 8),
                _InfoChip(
                    label: '🚗 Delivery',
                    color: AppTheme.successColor),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onApprove,
                    child: Text('Approve ✅',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onReject,
                  child: Text('Reject ❌',
                      style:
                          GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
