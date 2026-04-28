// lib/services/mess_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mess.dart';
import '../models/menu.dart';

class MessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get nearby messes.
  /// Fetches all approved messes and optionally sorts by distance if location is provided.
  Future<List<Mess>> getNearbyMesses({
    double? latitude,
    double? longitude,
    double radiusMeters = 3000.0,
  }) async {
    try {
      final data = await _supabase
          .from('messes')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      final messes = (data as List).map((e) => Mess.fromJson(e)).toList();

      // If we have a user location, sort by distance (nearest first)
      if (latitude != null && longitude != null) {
        for (int i = 0; i < messes.length; i++) {
          final m = messes[i];
          if (m.latitude != 0 && m.longitude != 0) {
            final dist = _calculateDistance(
                latitude, longitude, m.latitude, m.longitude);
            // Rebuild with distance info using copyWith pattern
            messes[i] = Mess.fromJson({
              ...m.toJson(),
              'distance_meters': dist,
            });
          }
        }
        messes.sort((a, b) =>
            (a.distanceMeters ?? double.infinity)
                .compareTo(b.distanceMeters ?? double.infinity));
      }

      return messes;
    } catch (e) {
      // Log and rethrow so the UI can show an error/retry
      debugPrint('MessService.getNearbyMesses error: $e');
      rethrow;
    }
  }

  /// Haversine distance calculation in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (3.141592653589793 / 180.0);

  /// Get a single mess by ID with rating aggregation
  Future<Mess?> getMessById(String messId) async {
    final data = await _supabase
        .from('messes')
        .select('*, reviews(rating)')
        .eq('id', messId)
        .maybeSingle();

    if (data == null) return null;

    // Calculate average rating
    final reviews = data['reviews'] as List?;
    if (reviews != null && reviews.isNotEmpty) {
      final avg = reviews.fold<double>(
            0,
            (sum, r) => sum + (r['rating'] as num).toDouble(),
          ) /
          reviews.length;
      data['rating'] = avg;
      data['total_reviews'] = reviews.length;
    }
    return Mess.fromJson(data);
  }

  /// Create a new mess profile
  Future<Mess> createMess(Map<String, dynamic> messData) async {
    final data = await _supabase
        .from('messes')
        .insert(messData)
        .select()
        .single();
    return Mess.fromJson(data);
  }

  /// Update an existing mess
  Future<void> updateMess(String messId, Map<String, dynamic> updates) async {
    await _supabase.from('messes').update(updates).eq('id', messId);
  }

  /// Toggle sold-out status
  Future<void> toggleSoldOut(String messId, bool isSoldOut) async {
    await _supabase
        .from('messes')
        .update({'is_sold_out': isSoldOut})
        .eq('id', messId);
  }

  /// Get mess owned by a specific owner
  Future<Mess?> getMessByOwner(String ownerId) async {
    final data = await _supabase
        .from('messes')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (data == null) return null;
    return Mess.fromJson(data);
  }

  /// Get menu for a mess
  Future<List<Menu>> getMenuForMess(String messId) async {
    final data = await _supabase
        .from('menus')
        .select()
        .eq('mess_id', messId)
        .order('day_of_week');
    return (data as List).map((e) => Menu.fromJson(e)).toList();
  }

  /// Upsert (create or update) a menu entry
  Future<void> upsertMenu(Map<String, dynamic> menuData) async {
    await _supabase.from('menus').upsert(menuData);
  }

  /// Get all pending messes (admin only)
  Future<List<Mess>> getPendingMesses() async {
    final data = await _supabase
        .from('messes')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Mess.fromJson(e)).toList();
  }

  /// Approve or reject a mess (admin only)
  Future<void> updateMessStatus(String messId, String status) async {
    await _supabase
        .from('messes')
        .update({'status': status})
        .eq('id', messId);
  }
}
