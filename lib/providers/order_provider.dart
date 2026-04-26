// lib/providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

/// Orders for current user
final userOrdersProvider =
    FutureProvider.family<List<Order>, String>((ref, userId) async {
  return ref.read(orderServiceProvider).getOrdersForUser(userId);
});

/// Today's orders for a mess (owner)
final messOrdersProvider =
    FutureProvider.family<List<Order>, String>((ref, messId) async {
  return ref.read(orderServiceProvider).getOrdersForMess(messId);
});

/// Single order by ID
final orderDetailProvider =
    FutureProvider.family<Order?, String>((ref, orderId) async {
  return ref.read(orderServiceProvider).getOrderById(orderId);
});

/// Today's analytics for a mess
final messAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, messId) async {
  return ref.read(orderServiceProvider).getTodayAnalytics(messId);
});
