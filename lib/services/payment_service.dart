// lib/services/payment_service.dart
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  /// Generate a UPI deep link URL
  String generateUpiLink({
    required String upiId,
    required String payeeName,
    required int amountInRupees,
    String? transactionNote,
  }) {
    final note = Uri.encodeComponent(transactionNote ?? 'Mess Order Payment');
    final name = Uri.encodeComponent(payeeName);
    return 'upi://pay?pa=$upiId&pn=$name&am=$amountInRupees&cu=INR&tn=$note';
  }

  /// Launch UPI payment via deep link.
  /// Returns true if the payment app was launched successfully.
  Future<bool> launchUpiPayment({
    required String upiId,
    required String payeeName,
    required int amountInRupees,
    String? transactionNote,
  }) async {
    final upiUrl = generateUpiLink(
      upiId: upiId,
      payeeName: payeeName,
      amountInRupees: amountInRupees,
      transactionNote: transactionNote,
    );

    final uri = Uri.parse(upiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Launch WhatsApp with a pre-filled order message (fallback)
  Future<bool> launchWhatsAppOrder({
    required String phone,
    required String messName,
    required String mealType,
    required String fulfillmentType,
    required int amount,
  }) async {
    final message = Uri.encodeComponent(
      'Hello! I would like to order from $messName.\n'
      '🍽️ Meal: ${mealType[0].toUpperCase()}${mealType.substring(1)}\n'
      '📦 Type: ${fulfillmentType[0].toUpperCase()}${fulfillmentType.substring(1)}\n'
      '💰 Amount: ₹$amount\n\n'
      'Please confirm my order. Thank you!',
    );
    final waUrl = 'https://wa.me/$phone?text=$message';
    final uri = Uri.parse(waUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
