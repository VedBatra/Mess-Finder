// lib/models/review.dart

class Review {
  final String id;
  final String userId;
  final String messId;
  final String orderId;
  final String? reviewerName; // joined from profiles
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.messId,
    required this.orderId,
    this.reviewerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      messId: json['mess_id'] as String,
      orderId: json['order_id'] as String,
      reviewerName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['full_name'] as String?
          : json['reviewer_name'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 1,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mess_id': messId,
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
