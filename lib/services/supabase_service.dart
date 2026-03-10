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

  // Defensive cleaning to handle potential injection issues (quotes, etc)
  static String _clean(String value) {
    return value.trim().replaceAll('"', '').replaceAll("'", "");
  }

  static String get cleanSupabaseUrl => _clean(supabaseUrl);
  static String get cleanSupabaseAnonKey => _clean(supabaseAnonKey);

  // Helper to mask sensitive values for logging
  static String _mask(String value) {
    final cleaned = _clean(value);
    if (cleaned.isEmpty) return "MISSING";
    if (cleaned.length <= 8) return "****";
    return "${cleaned.substring(0, 4)}...${cleaned.substring(cleaned.length - 4)}";
  }

  // Initialize Supabase - call this in main()
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    print('📡 Initializing Supabase...');
    print('   URL: ${_mask(supabaseUrl)}');
    print('   Key: ${_mask(supabaseAnonKey)}');

    final url = cleanSupabaseUrl;
    final anonKey = cleanSupabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      print('❌ SUPABASE_URL or SUPABASE_ANON_KEY is missing/empty. Please configure environment variables.');
      return false;
    }

    if (url.contains('$') || anonKey.contains('$')) {
      print('❌ ERROR: Environment variables contain unresolved placeholders (detecting $). Check your CI configuration.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: url, 
        anonKey: anonKey,
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

  // Check if we're in demo mode (always false for production)
  static bool get isDemoMode => false;
}
