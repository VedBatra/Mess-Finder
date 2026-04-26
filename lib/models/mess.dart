// lib/models/mess.dart

class Mess {
  final String id;
  final String ownerId;
  final String messName;
  final String address;
  final double latitude;
  final double longitude;
  final String? lunchCutoff;
  final String? dinnerCutoff;
  final int oneTimeLunchPrice;
  final int oneTimeDinnerPrice;
  final bool offersDelivery;
  final int deliveryCharge;
  final int packagingCharge;
  final String? upiId;
  final String status; // pending, approved, rejected
  final bool isSoldOut;
  final double? rating;
  final int? totalReviews;
  final double? distanceMeters;
  final String? imageUrl;
  final DateTime createdAt;

  const Mess({
    required this.id,
    required this.ownerId,
    required this.messName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.lunchCutoff,
    this.dinnerCutoff,
    required this.oneTimeLunchPrice,
    required this.oneTimeDinnerPrice,
    this.offersDelivery = false,
    this.deliveryCharge = 0,
    this.packagingCharge = 0,
    this.upiId,
    this.status = 'pending',
    this.isSoldOut = false,
    this.rating,
    this.totalReviews,
    this.distanceMeters,
    this.imageUrl,
    required this.createdAt,
  });

  factory Mess.fromJson(Map<String, dynamic> json) {
    // Parse latitude/longitude from PostGIS geography or plain columns
    double lat = 0.0;
    double lng = 0.0;
    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    }

    return Mess(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      messName: json['mess_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      lunchCutoff: json['lunch_cutoff'] as String?,
      dinnerCutoff: json['dinner_cutoff'] as String?,
      oneTimeLunchPrice: (json['one_time_lunch_price'] as num?)?.toInt() ?? 0,
      oneTimeDinnerPrice: (json['one_time_dinner_price'] as num?)?.toInt() ?? 0,
      offersDelivery: json['offers_delivery'] as bool? ?? false,
      deliveryCharge: (json['delivery_charge'] as num?)?.toInt() ?? 0,
      packagingCharge: (json['packaging_charge'] as num?)?.toInt() ?? 0,
      upiId: json['upi_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      isSoldOut: json['is_sold_out'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      totalReviews: (json['total_reviews'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'mess_name': messName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'lunch_cutoff': lunchCutoff,
        'dinner_cutoff': dinnerCutoff,
        'one_time_lunch_price': oneTimeLunchPrice,
        'one_time_dinner_price': oneTimeDinnerPrice,
        'offers_delivery': offersDelivery,
        'delivery_charge': deliveryCharge,
        'packaging_charge': packagingCharge,
        'upi_id': upiId,
        'status': status,
        'is_sold_out': isSoldOut,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  /// Returns distance in km as a formatted string
  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  Mess copyWith({
    String? messName,
    String? address,
    double? latitude,
    double? longitude,
    String? lunchCutoff,
    String? dinnerCutoff,
    int? oneTimeLunchPrice,
    int? oneTimeDinnerPrice,
    bool? offersDelivery,
    int? deliveryCharge,
    int? packagingCharge,
    String? upiId,
    String? status,
    bool? isSoldOut,
    String? imageUrl,
  }) {
    return Mess(
      id: id,
      ownerId: ownerId,
      messName: messName ?? this.messName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lunchCutoff: lunchCutoff ?? this.lunchCutoff,
      dinnerCutoff: dinnerCutoff ?? this.dinnerCutoff,
      oneTimeLunchPrice: oneTimeLunchPrice ?? this.oneTimeLunchPrice,
      oneTimeDinnerPrice: oneTimeDinnerPrice ?? this.oneTimeDinnerPrice,
      offersDelivery: offersDelivery ?? this.offersDelivery,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      packagingCharge: packagingCharge ?? this.packagingCharge,
      upiId: upiId ?? this.upiId,
      status: status ?? this.status,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      rating: rating,
      totalReviews: totalReviews,
      distanceMeters: distanceMeters,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
