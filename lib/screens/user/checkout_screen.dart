// lib/screens/user/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mess.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String messId;
  final String mealType;

  const CheckoutScreen({
    super.key,
    required this.messId,
    required this.mealType,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedFulfillment;
  late String _selectedMeal;
  String _selectedPayment = AppConstants.paymentUpi;
  bool _isLoading = false;
  late AnimationController _animController;
  DateTime _selectedDate = DateTime.now();

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  bool _isPastCutoff(Mess mess, String mealType, DateTime date) {
    if (!_isToday(date)) return false;

    final cutoffStr = mealType == AppConstants.mealTypeLunch ? mess.lunchCutoff : mess.dinnerCutoff;
    if (cutoffStr == null || cutoffStr.isEmpty) return false;

    try {
      String cleanStr = cutoffStr.toUpperCase().replaceAll(' ', '');
      bool isPM = cleanStr.contains('PM');
      bool isAM = cleanStr.contains('AM');
      cleanStr = cleanStr.replaceAll('PM', '').replaceAll('AM', '');

      final parts = cleanStr.split(':');
      int h = int.parse(parts[0].trim());
      int m = parts.length > 1 ? int.parse(parts[1].trim()) : 0;

      if (isPM && h < 12) h += 12;
      if (isAM && h == 12) h = 0;

      final now = DateTime.now();
      final cutoffTime = DateTime(now.year, now.month, now.day, h, m);
      return now.isAfter(cutoffTime);
    } catch (_) {
      return false; // ignore parse errors and allow
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedFulfillment = AppConstants.fulfillmentDineIn;
    _selectedMeal = widget.mealType;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int _calculateTotal(Mess mess) {
    int base = _selectedMeal == AppConstants.mealTypeLunch
        ? mess.oneTimeLunchPrice
        : mess.oneTimeDinnerPrice;
    if (_selectedFulfillment == AppConstants.fulfillmentDelivery) {
      base += mess.deliveryCharge + mess.packagingCharge;
    }
    return base;
  }

  Future<void> _placeOrder(Mess mess) async {
    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;

    if (_isPastCutoff(mess, _selectedMeal, _selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cutoff time for ${_selectedMeal.capitalize()} has passed for today. Please select tomorrow.', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final total = _calculateTotal(mess);

      if (_selectedPayment == AppConstants.paymentUpi) {
        if (mess.upiId == null || mess.upiId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI not configured. Use cash.')),
          );
          setState(() => _isLoading = false);
          return;
        }
        final launched = await PaymentService().launchUpiPayment(
          upiId: mess.upiId!,
          payeeName: mess.messName,
          amountInRupees: total,
          transactionNote:
              '${_selectedMeal.capitalize()} order at ${mess.messName}',
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No UPI app found. Use cash.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final order = await OrderService().createOrder(
        userId: profile.id,
        messId: mess.id,
        mealType: _selectedMeal,
        fulfillmentType: _selectedFulfillment,
        totalAmount: total,
        paymentMethod: _selectedPayment,
        orderDate: _selectedDate,
      );

      if (mounted) context.go('/tracking/${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messDetailProvider(widget.messId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Checkout',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: messAsync.when(
        data: (mess) {
          if (mess == null) return const Center(child: Text('Mess not found'));
          return _buildBody(mess);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(Mess mess) {
    final total = _calculateTotal(mess);
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mess info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(mess.address,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Selection
                  _SectionTitle(title: 'Select Date', icon: Icons.calendar_today_rounded),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionCard(
                          label: 'Today',
                          subtitle: _formatDate(DateTime.now()),
                          selected: _isToday(_selectedDate),
                          onTap: () => setState(() => _selectedDate = DateTime.now()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OptionCard(
                          label: 'Tomorrow',
                          subtitle: _formatDate(DateTime.now().add(const Duration(days: 1))),
                          selected: !_isToday(_selectedDate),
                          onTap: () => setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meal type
                  _SectionTitle(title: 'Select Meal', icon: Icons.restaurant_menu_rounded),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionCard(
                          label: '☀️ Lunch',
                          subtitle: '₹${mess.oneTimeLunchPrice}',
                          selected: _selectedMeal == AppConstants.mealTypeLunch,
                          onTap: () => setState(
                              () => _selectedMeal = AppConstants.mealTypeLunch),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OptionCard(
                          label: '🌙 Dinner',
                          subtitle: '₹${mess.oneTimeDinnerPrice}',
                          selected: _selectedMeal == AppConstants.mealTypeDinner,
                          onTap: () => setState(
                              () => _selectedMeal = AppConstants.mealTypeDinner),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Fulfillment
                  _SectionTitle(title: 'How would you like it?', icon: Icons.local_shipping_rounded),
                  _OptionRow(
                    icon: Icons.restaurant_rounded,
                    label: 'Dine-in',
                    subtitle: 'Eat at the mess',
                    selected: _selectedFulfillment == AppConstants.fulfillmentDineIn,
                    onTap: () => setState(() =>
                        _selectedFulfillment = AppConstants.fulfillmentDineIn),
                  ),
                  _OptionRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Takeaway',
                    subtitle: 'Pick up your order',
                    selected: _selectedFulfillment == AppConstants.fulfillmentTakeaway,
                    onTap: () => setState(() =>
                        _selectedFulfillment = AppConstants.fulfillmentTakeaway),
                  ),
                  if (mess.offersDelivery)
                    _OptionRow(
                      icon: Icons.delivery_dining,
                      label: 'Delivery',
                      subtitle: '+₹${mess.deliveryCharge + mess.packagingCharge} extra',
                      selected: _selectedFulfillment == AppConstants.fulfillmentDelivery,
                      onTap: () => setState(() =>
                          _selectedFulfillment = AppConstants.fulfillmentDelivery),
                    ),
                  const SizedBox(height: 24),

                  // Payment
                  _SectionTitle(title: 'Payment Method', icon: Icons.payment_rounded),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionCard(
                          label: '📱 UPI',
                          subtitle: 'Pay instantly',
                          selected: _selectedPayment == AppConstants.paymentUpi,
                          onTap: () => setState(
                              () => _selectedPayment = AppConstants.paymentUpi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OptionCard(
                          label: '💵 Cash',
                          subtitle: 'Pay at counter',
                          selected: _selectedPayment == AppConstants.paymentCash,
                          onTap: () => setState(
                              () => _selectedPayment = AppConstants.paymentCash),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Premium Bottom Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(
                      '₹$total',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.primaryShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _placeOrder(mess),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _selectedPayment == AppConstants.paymentUpi
                                  ? 'Pay via UPI'
                                  : 'Place Order',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard(
      {required this.label,
      required this.subtitle,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppTheme.softShadow : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow(
      {required this.icon,
      required this.label,
      this.subtitle = '',
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppTheme.softShadow : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (selected ? AppTheme.primaryColor : AppTheme.textLight)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryColor
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
