// lib/screens/user/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  Order? _order;
  bool _loading = true;
  RealtimeChannel? _channel;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await OrderService().getOrderById(widget.orderId);
    if (mounted) {
      setState(() { _order = order; _loading = false; });
      _subscribeRealtime();
    }
  }

  void _subscribeRealtime() {
    _channel = OrderService().subscribeToOrder(
      widget.orderId,
      (payload) {
        if (mounted) {
          setState(() {
            _order = _order?.copyWith(
                status: payload['status'] as String? ?? _order!.status);
          });
        }
      },
    );
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(color: AppTheme.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      await OrderService().updateOrderStatus(order.id, AppConstants.statusCancelled);
      if (mounted) {
        setState(() {
          _order = _order?.copyWith(status: AppConstants.statusCancelled);
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Track Order',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final order = _order!;
    final steps = [
      AppConstants.statusPending,
      AppConstants.statusAccepted,
      AppConstants.statusReady,
      AppConstants.statusCompleted,
    ];
    final currentStep = order.status == AppConstants.statusCancelled
        ? -1
        : steps.indexWhere((s) => s == order.status).clamp(0, steps.length);
    final statusColor = AppTheme.getStatusColor(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID
          Text(
            'Order #${order.id.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${order.mealDisplay} · ${order.fulfillmentDisplay}',
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹${order.totalAmount}  ·  ${order.paymentMethod.toUpperCase()}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // Status stepper
          if (order.status != AppConstants.statusCancelled)
            _StatusStepper(steps: steps, currentStep: currentStep),

          const SizedBox(height: 36),

          // Current status card
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = order.status != AppConstants.statusCompleted && 
                            order.status != AppConstants.statusCancelled
                  ? 0.85 + (_pulseController.value * 0.15)
                  : 1.0;
              return Transform.scale(
                scale: pulse,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      AppTheme.getStatusIcon(order.status),
                      size: 36,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusTitle(order.status),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage(order.status),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (order.status == AppConstants.statusPending) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _cancelOrder,
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                label: Text(
                  'Cancel Order',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],

          if (order.status == AppConstants.statusCompleted) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/mess/${order.messId}'),
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: Text('Rate Your Experience',
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

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_rounded),
              label: Text('Back to Home',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'pending': return 'Order Placed!';
      case 'accepted': return 'Confirmed! 🎉';
      case 'ready': return 'Food Ready! 🍽️';
      case 'completed': return 'Completed! 🥳';
      case 'cancelled': return 'Cancelled ❌';
      default: return status;
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'pending': return 'Waiting for the owner to confirm your order.';
      case 'accepted': return 'Your food is being prepared with care.';
      case 'ready': return 'Please collect your food or it\'s on the way!';
      case 'completed': return 'Thank you! Hope you enjoyed your meal.';
      case 'cancelled': return 'This order has been cancelled.';
      default: return 'Status: $status';
    }
  }
}

class _StatusStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  const _StatusStepper({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: stepIndex < currentStep
                    ? AppTheme.primaryColor
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        } else {
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                width: isCurrent ? 32 : 24,
                height: isCurrent ? 32 : 24,
                decoration: BoxDecoration(
                  gradient: isDone || isCurrent
                      ? AppTheme.primaryGradient
                      : null,
                  color: isDone || isCurrent
                      ? null
                      : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent ? AppTheme.primaryShadow : [],
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : isCurrent
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
              const SizedBox(height: 6),
              Text(
                _stepLabel(steps[stepIndex]),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDone || isCurrent
                      ? AppTheme.primaryColor
                      : AppTheme.textLight,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  String _stepLabel(String s) {
    return s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
  }
}
