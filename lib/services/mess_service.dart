// lib/services/mess_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mess.dart';
import '../models/menu.dart';

class MessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get nearby messes using a PostGIS RPC function.
  /// Falls back to fetching all approved messes if RPC is not available.
  Future<List<Mess>> getNearbyMesses({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000.0,
  }) async {
    try {
      final response = await _supabase.rpc('get_nearby_messes', params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_meters': radiusMeters,
      });
      if (response == null) return [];
      return (response as List).map((e) => Mess.fromJson(e)).toList();
    } catch (_) {
      // Fallback: fetch all approved messes without distance filtering
      final data = await _supabase
          .from('messes')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);
      return (data as List).map((e) => Mess.fromJson(e)).toList();
    }
  }

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
