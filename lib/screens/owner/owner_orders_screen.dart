// lib/screens/owner/owner_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../services/order_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  dynamic _channel;
  String _selectedStatus = 'all';
  String _selectedSort = 'newest';

  List<Order> get _filteredOrders {
    List<Order> filtered = List.from(_orders);

    if (_selectedStatus != 'all') {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    } else {
      filtered = filtered.where((o) => o.status != AppConstants.statusCancelled).toList();
    }

    if (_selectedSort == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;

    final mess =
        await ref.read(messServiceProvider).getMessByOwner(profile.id);
    if (mess == null || !mounted) return;

    final orders = await OrderService().getOrdersForMess(mess.id);
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });

    _channel = OrderService().subscribeToMessOrders(
      mess.id,
      (payload) {
        if (mounted) {
          setState(() {
            final newOrder = Order.fromJson(payload);
            _orders.insert(0, newOrder);
          });
        }
      },
      (payload) {
        if (mounted) {
          setState(() {
            final updated = Order.fromJson(payload);
            final idx = _orders.indexWhere((o) => o.id == updated.id);
            if (idx != -1) _orders[idx] = updated;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await OrderService().updateOrderStatus(orderId, status);
    setState(() {
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) _orders[idx] = _orders[idx].copyWith(status: status);
    });
  }

  Widget _buildFilters() {
    final statuses = ['all', 'pending', 'accepted', 'ready', 'completed'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: statuses.map((status) {
                final isSelected = _selectedStatus == status;
                final label = status == 'all' ? 'All' : '${status[0].toUpperCase()}${status.substring(1)}';
                final color = status == 'all' ? AppTheme.primaryColor : AppTheme.getStatusColor(status);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.2),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = status);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Sort by Date: ',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  items: [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest First', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('Oldest First', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                    }
                  },
                  underline: Container(),
                  icon: const Icon(Icons.sort_rounded, size: 16, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("All Orders",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _loading = true);
              _init();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    size: 40, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(height: 20),
                              Text('No matching orders',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) => _OwnerOrderCard(
                            order: filteredOrders[index],
                            onUpdateStatus: _updateStatus,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _OwnerOrderCard extends StatelessWidget {
  final Order order;
  final Future<void> Function(String orderId, String status) onUpdateStatus;

  const _OwnerOrderCard({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(AppTheme.getStatusIcon(order.status),
                    color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.mealDisplay,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${order.fulfillmentDisplay} · ₹${order.totalAmount}',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Text(
              'Order Date: ${DateFormat('dd MMM yyyy').format(order.orderDate)} · Payment: ${order.paymentMethod.toUpperCase()}',
              style: GoogleFonts.inter(
                  color: AppTheme.textLight, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (order.status == AppConstants.statusPending) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
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
                onPressed: () =>
                    onUpdateStatus(order.id, AppConstants.statusAccepted),
                child: Text('Accept ✓',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.white)),
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
              onPressed: () =>
                  onUpdateStatus(order.id, AppConstants.statusCancelled),
              child: Text('Reject',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    } else if (order.status == AppConstants.statusAccepted) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () =>
              onUpdateStatus(order.id, AppConstants.statusReady),
          child: Text('Mark as Ready 🍽️',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      );
    } else if (order.status == AppConstants.statusReady) {
      return Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppTheme.successGradient,
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
          onPressed: () =>
              onUpdateStatus(order.id, AppConstants.statusCompleted),
          child: Text('Mark Completed ✓',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
