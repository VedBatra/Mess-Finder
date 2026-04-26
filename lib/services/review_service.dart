// lib/services/review_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all reviews for a mess
  Future<List<Review>> getReviewsForMess(String messId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, profiles(full_name)')
        .eq('mess_id', messId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  /// Create a review (only for completed orders)
  Future<Review> createReview({
    required String userId,
    required String messId,
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    // Verify the order belongs to this user and is completed
    final order = await _supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('user_id', userId)
        .eq('status', 'completed')
        .maybeSingle();

    if (order == null) {
      throw Exception(
          'You can only review a mess after your order is completed.');
    }

    // Check if review already exists for this order
    final existing = await _supabase
        .from('reviews')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You have already reviewed this order.');
    }

    final data = await _supabase
        .from('reviews')
        .insert({
          'user_id': userId,
          'mess_id': messId,
          'order_id': orderId,
          'rating': rating,
          'comment': comment,
        })
        .select()
        .single();

    return Review.fromJson(data);
  }

  /// Delete a review (admin only)
  Future<void> deleteReview(String reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }

  /// Calculate average rating for a mess
  Future<double> getAverageRating(String messId) async {
    final data = await _supabase
        .from('reviews')
        .select('rating')
        .eq('mess_id', messId);

    final reviews = data as List;
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold<double>(
      0,
      (sum, r) => sum + (r['rating'] as num).toDouble(),
    );
    return total / reviews.length;
  }
}
