import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service for email/password auth
class AuthService {
  final SupabaseClient _client;

  AuthService() : _client = SupabaseService.instance.client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Register a new user with email and password
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Logout current user
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
