// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current authenticated user (nullable)
  User? get currentUser => _supabase.auth.currentUser;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email & password, then create a profile
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }
    final userId = response.user!.id;

    // Use update since the trigger already created the profile row
    await _supabase.from('profiles').update({
      'full_name': fullName,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    }).eq('id', userId);

    return Profile(
      id: userId,
      role: role,
      fullName: fullName,
      phone: phone,
      createdAt: DateTime.now(),
    );
  }

  /// Sign in with email & password
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign in failed. Check your credentials.');
    }
    return response.user!;
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    // 1. Initialize Google Sign In
    // TODO: The webClientId and iosClientId must be configured properly here or from Google-Services files.
    // For web/Android/iOS cross platform, Supabase has native signInWithOAuth but google_sign_in provides native flows.
    const webClientId = '991646199587-v5jksh5712bnjnjpum64a0ear4d97v9r.apps.googleusercontent.com';
    const iosClientId = '991646199587-v5jksh5712bnjnjpum64a0ear4d97v9r.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : iosClientId,
      serverClientId: kIsWeb ? null : webClientId,
    );

    // 2. Start the sign-in process
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In was aborted.');
    }

    // 3. Obtain auth details
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Failed to retrieve ID token from Google.');
    }

    // 4. Sign in to Supabase using the Google ID Token
    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Fetch profile for the current user
  Future<Profile?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// Update profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
    if (updates.isEmpty) return;
    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
