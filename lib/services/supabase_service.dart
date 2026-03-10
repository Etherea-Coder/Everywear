import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String _clean(String value) => value.trim().replaceAll('"', '').replaceAll("'", "");
  static String get cleanSupabaseUrl => _clean(supabaseUrl);
  static String get cleanSupabaseAnonKey => _clean(supabaseAnonKey);

  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    final url = cleanSupabaseUrl;
    final anonKey = cleanSupabaseAnonKey;
    if (url.isEmpty || anonKey.isEmpty) return false;
    try {
      await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  SupabaseClient get client => Supabase.instance.client;
  static bool get isDemoMode => false;
}
