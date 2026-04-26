// lib/providers/mess_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mess.dart';
import '../services/mess_service.dart';
import 'location_provider.dart';
import '../utils/constants.dart';

final messServiceProvider = Provider<MessService>((ref) => MessService());

/// Nearby messes based on current location
final nearbyMessesProvider = FutureProvider<List<Mess>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) {
    // No location – fetch all approved messes as fallback
    return ref.read(messServiceProvider).getNearbyMesses(
          latitude: 0,
          longitude: 0,
          radiusMeters: AppConstants.discoveryRadiusMeters,
        );
  }
  return ref.read(messServiceProvider).getNearbyMesses(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: AppConstants.discoveryRadiusMeters,
      );
});

/// Single mess by ID
final messDetailProvider =
    FutureProvider.family<Mess?, String>((ref, messId) async {
  return ref.read(messServiceProvider).getMessById(messId);
});

/// Owner's mess
final ownerMessProvider = FutureProvider.family<Mess?, String>((ref, ownerId) async {
  return ref.read(messServiceProvider).getMessByOwner(ownerId);
});
