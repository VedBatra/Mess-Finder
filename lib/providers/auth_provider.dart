// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

/// Global auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Current Supabase session
final sessionProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // Check for an existing Supabase session on startup
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    // Fetch profile from DB
    final profile = await ref.read(authServiceProvider).getProfile();
    return profile;
  }

  /// Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    final profile = await ref.read(authServiceProvider).signUp(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          phone: phone,
        );
    state = AsyncData(profile);
  }

  /// Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await ref.read(authServiceProvider).signIn(
          email: email,
          password: password,
        );
    final profile = await ref.read(authServiceProvider).getProfile();
    if (profile == null) {
      throw Exception('Profile not found. Please contact support or sign up again.');
    }
    state = AsyncData(profile);
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    final response = await ref.read(authServiceProvider).signInWithGoogle();
    
    // Check if profile exists for this Google user
    var profile = await ref.read(authServiceProvider).getProfile();
    
    // If no profile exists, this is a first-time Google sign-in. Let's create one.
    if (profile == null && response.user != null) {
      final user = response.user!;
      final fullName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'Google User';
      
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'role': 'user', // Default role for Google signups is 'user'
      });
      
      profile = Profile(
        id: user.id,
        role: 'user',
        fullName: fullName,
        createdAt: DateTime.now(),
      );
    }
    
    if (profile == null) {
      throw Exception('Google Sign in failed: Profile could not be resolved.');
    }
    
    state = AsyncData(profile);
  }

  /// Sign out
  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(authServiceProvider).updateProfile(
          userId: current.id,
          fullName: fullName,
          phone: phone,
          avatarUrl: avatarUrl,
        );
    state = AsyncData(current.copyWith(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    ));
  }
}

/// Main auth provider used throughout the app
final authProvider = AsyncNotifierProvider<AuthNotifier, Profile?>(() {
  return AuthNotifier();
});

/// Convenience provider for current user role
final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).valueOrNull?.role;
});

/// Check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
