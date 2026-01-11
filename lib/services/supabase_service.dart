import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

/// Singleton service for Supabase operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  /// Get the singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Get the Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize Supabase with configuration
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client?.auth.currentUser != null;

  /// Get current user
  User? get currentUser => _client?.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client?.auth.currentSession;
}
