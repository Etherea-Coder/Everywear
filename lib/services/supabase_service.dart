import 'package:flutter/foundation.dart';
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

  // Helper to mask sensitive values for logging
  static String _mask(String value) {
    if (value.isEmpty) return "MISSING";
    if (value.length <= 8) return "****";
    return "${value.substring(0, 4)}...${value.substring(value.length - 4)}";
  }

  // Initialize Supabase - call this in main()
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    print('📡 Initializing Supabase...');
    print('   URL: ${_mask(supabaseUrl)}');
    print('   Key: ${_mask(supabaseAnonKey)}');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print('⚠️ SUPABASE_URL or SUPABASE_ANON_KEY is empty. App will run in offline mode.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl, 
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      print('✅ Supabase initialized successfully.');
      return true;
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      return false;
    }
  }

  // Get Supabase client
  SupabaseClient get client {
    if (!_isInitialized) {
      String reason;
      if (supabaseUrl.isEmpty && supabaseAnonKey.isEmpty) {
        reason = 'BOTH SUPABASE_URL and SUPABASE_ANON_KEY are missing from environment.';
      } else if (supabaseUrl.isEmpty) {
        reason = 'SUPABASE_URL is missing from environment.';
      } else if (supabaseAnonKey.isEmpty) {
        reason = 'SUPABASE_ANON_KEY is missing from environment.';
      } else {
        reason = 'Initialization failed or was never called successfully.';
      }
      throw StateError('Supabase Client Access Error: $reason\n'
          'Verify these are set in Codemagic environment variables and injected via env.json.');
    }
    return Supabase.instance.client;
  }
}
