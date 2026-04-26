// lib/models/order.dart

class Order {
  final String id;
  final String userId;
  final String messId;
  final String? messName; // joined for display
  final String mealType; // lunch or dinner
  final DateTime orderDate;
  final String fulfillmentType; // dine-in, takeaway, delivery
  final int totalAmount;
  final String paymentMethod; // upi, cash
  final String status; // pending, accepted, ready, completed, cancelled
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.messId,
    this.messName,
    required this.mealType,
    required this.orderDate,
    required this.fulfillmentType,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      messId: json['mess_id'] as String,
      messName: json['messes'] != null
          ? (json['messes'] as Map<String, dynamic>)['mess_name'] as String?
          : json['mess_name'] as String?,
      mealType: json['meal_type'] as String? ?? 'lunch',
      orderDate: DateTime.parse(json['order_date'] as String),
      fulfillmentType: json['fulfillment_type'] as String? ?? 'dine-in',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mess_id': messId,
        'meal_type': mealType,
        'order_date': orderDate.toIso8601String().split('T')[0],
        'fulfillment_type': fulfillmentType,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  Order copyWith({String? status}) {
    return Order(
      id: id,
      userId: userId,
      messId: messId,
      messName: messName,
      mealType: mealType,
      orderDate: orderDate,
      fulfillmentType: fulfillmentType,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  /// Human-readable display of fulfillment type
  String get fulfillmentDisplay {
    switch (fulfillmentType) {
      case 'dine-in':
        return '🍽️ Dine-in';
      case 'takeaway':
        return '🛍️ Takeaway';
      case 'delivery':
        return '🛵 Delivery';
      default:
        return fulfillmentType;
    }
  }

  /// Human-readable display of meal type
  String get mealDisplay {
    switch (mealType) {
      case 'lunch':
        return '☀️ Lunch';
      case 'dinner':
        return '🌙 Dinner';
      default:
        return mealType;
    }
  }
}
