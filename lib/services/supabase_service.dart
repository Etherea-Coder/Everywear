import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Initialize Supabase - call this in main()
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      // Log warning instead of crashing - app can still run in offline mode
      print('⚠️ SUPABASE_URL and SUPABASE_ANON_KEY not defined. Running in offline mode.');
      return false;
    }

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      return false;
    }
  }

  // Get Supabase client
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('Supabase has not been initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }
}
