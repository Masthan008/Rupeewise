/// App-wide constants for RupeeWise
library;

/// Supabase configuration
/// These should be replaced with environment variables in production
class SupabaseConstants {
  static const String supabaseUrl = 'https://obvymrjvhnzgbfsodyuv.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9idnltcmp2aG56Z2Jmc29keXV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNTk3MDksImV4cCI6MjA4MzYzNTcwOX0.oe89n3xpUfFo0xD8RiJ40Pmo9KJQBrB5VaYjXoEEVVw';
}

/// App metadata
class AppConstants {
  static const String appName = 'RupeeWise';
  static const String appVersion = '1.0.0';
}
