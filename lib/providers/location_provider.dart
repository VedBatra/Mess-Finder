// lib/providers/location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Current user position
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    return await ref.read(locationServiceProvider).getCurrentPosition();
  } catch (_) {
    return null;
  }
});
