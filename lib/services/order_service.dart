// lib/services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order
  Future<Order> createOrder({
    required String userId,
    required String messId,
    required String mealType,
    required String fulfillmentType,
    required int totalAmount,
    required String paymentMethod,
    required DateTime orderDate,
  }) async {
    final data = await _supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'mess_id': messId,
          'meal_type': mealType,
          'order_date': orderDate.toIso8601String().split('T')[0],
          'fulfillment_type': fulfillmentType,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'status': 'pending',
        })
        .select()
        .single();
    return Order.fromJson(data);
  }

  /// Get all orders for the current user
  Future<List<Order>> getOrdersForUser(String userId) async {
    final data = await _supabase
        .from('orders')
        .select('*, messes(mess_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Get today's orders for a mess
  Future<List<Order>> getOrdersForMess(String messId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await _supabase
        .from('orders')
        .select('*, profiles(full_name, phone)')
        .eq('mess_id', messId)
        .eq('order_date', today)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Get a single order by ID
  Future<Order?> getOrderById(String orderId) async {
    final data = await _supabase
        .from('orders')
        .select('*, messes(mess_name)')
        .eq('id', orderId)
        .maybeSingle();
    if (data == null) return null;
    return Order.fromJson(data);
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  /// Subscribe to realtime orders for a mess (owner dashboard)
  RealtimeChannel subscribeToMessOrders(
    String messId,
    void Function(Map<String, dynamic> payload) onInsert,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _supabase
        .channel('orders:mess_id=eq.$messId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mess_id',
            value: messId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'mess_id',
            value: messId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to a single order status change (user tracking)
  RealtimeChannel subscribeToOrder(
    String orderId,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _supabase
        .channel('orders:id=eq.$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Get order analytics for a mess (today)
  Future<Map<String, dynamic>> getTodayAnalytics(String messId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await _supabase
        .from('orders')
        .select('fulfillment_type, meal_type, total_amount, status')
        .eq('mess_id', messId)
        .eq('order_date', today);

    final orders = data as List;
    int totalRevenue = 0;
    int dineInCount = 0;
    int takeawayCount = 0;
    int deliveryCount = 0;
    int lunchCount = 0;
    int dinnerCount = 0;

    for (final o in orders) {
      totalRevenue += (o['total_amount'] as num?)?.toInt() ?? 0;
      if (o['fulfillment_type'] == 'dine-in') dineInCount++;
      if (o['fulfillment_type'] == 'takeaway') takeawayCount++;
      if (o['fulfillment_type'] == 'delivery') deliveryCount++;
      if (o['meal_type'] == 'lunch') lunchCount++;
      if (o['meal_type'] == 'dinner') dinnerCount++;
    }

    return {
      'total_orders': orders.length,
      'total_revenue': totalRevenue,
      'dine_in': dineInCount,
      'takeaway': takeawayCount,
      'delivery': deliveryCount,
      'lunch': lunchCount,
      'dinner': dinnerCount,
    };
  }
}
