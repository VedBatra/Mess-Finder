// lib/utils/constants.dart
class AppConstants {
  // Mess discovery radius in meters
  static const double discoveryRadiusMeters = 3000.0;

  // Order meal types
  static const String mealTypeLunch = 'lunch';
  static const String mealTypeDinner = 'dinner';

  // Fulfillment types
  static const String fulfillmentDineIn = 'dine-in';
  static const String fulfillmentTakeaway = 'takeaway';
  static const String fulfillmentDelivery = 'delivery';

  // Payment methods
  static const String paymentUpi = 'upi';
  static const String paymentCash = 'cash';

  // Order statuses
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // User roles
  static const String roleUser = 'user';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';

  // Mess approval status
  static const String messStatusPending = 'pending';
  static const String messStatusApproved = 'approved';
  static const String messStatusRejected = 'rejected';

  // Days of the week
  static const List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyAjxW_zNjAAVy4CQnGKkGiDcZi1jH_EXLg';
}
