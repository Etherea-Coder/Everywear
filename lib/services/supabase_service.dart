import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static const String _compileTimeUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _compileTimeAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String _runtimeUrl = '';
  static String _runtimeAnonKey = '';

  static String _clean(String value) {
    return value.trim().replaceAll('"', '').replaceAll("'", "");
  }

  static String get cleanSupabaseUrl => _clean(
        _compileTimeUrl.isNotEmpty ? _compileTimeUrl : _runtimeUrl,
      );
  static String get cleanSupabaseAnonKey => _clean(
        _compileTimeAnonKey.isNotEmpty ? _compileTimeAnonKey : _runtimeAnonKey,
      );

  static String _mask(String value) {
    final cleaned = _clean(value);
    if (cleaned.isEmpty) return "MISSING";
    if (cleaned.length <= 8) return "****";
    return "${cleaned.substring(0, 4)}...${cleaned.substring(cleaned.length - 4)}";
  }

  static Future<bool> _loadEnvJson() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/env.json');
      final env = json.decode(jsonStr) as Map<String, dynamic>;
      _runtimeUrl = env['SUPABASE_URL']?.toString() ?? '';
      _runtimeAnonKey = env['SUPABASE_ANON_KEY']?.toString() ?? '';
      debugPrint('   env.json loaded: URL=${_mask(_runtimeUrl)}, Key=${_mask(_runtimeAnonKey)}');
      return _runtimeUrl.isNotEmpty && _runtimeAnonKey.isNotEmpty;
    } catch (e) {
      debugPrint('   env.json not found or invalid: $e');
      return false;
    }
  }

  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    debugPrint('Initializing Supabase...');
    debugPrint('   Compile-time URL: ${_mask(_compileTimeUrl)}');
    debugPrint('   Compile-time Key: ${_mask(_compileTimeAnonKey)}');

    if (_compileTimeUrl.isEmpty || _compileTimeAnonKey.isEmpty) {
      debugPrint('   Compile-time env vars missing, loading env.json from assets...');
      await _loadEnvJson();
    }

    final url = cleanSupabaseUrl;
    final anonKey = cleanSupabaseAnonKey;

    debugPrint('   Effective URL: ${_mask(url)}');
    debugPrint('   Effective Key: ${_mask(anonKey)}');

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('SUPABASE_URL or SUPABASE_ANON_KEY is missing/empty. '
          'Pass via --dart-define or include env.json in assets.');
      return false;
    }

    if (url.contains('\$') || anonKey.contains('\$')) {
      debugPrint('ERROR: Environment variables contain unresolved placeholders (detecting \$). '
          'Check your CI configuration.');
      return false;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);
      _isInitialized = true;
      debugPrint('Supabase initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
      return false;
    }
  }

  SupabaseClient get client {
    if (!_isInitialized) {
      String reason;
      if (cleanSupabaseUrl.isEmpty && cleanSupabaseAnonKey.isEmpty) {
        reason = 'BOTH SUPABASE_URL and SUPABASE_ANON_KEY are missing. '
            'Pass via --dart-define or include env.json in assets.';
      } else if (cleanSupabaseUrl.isEmpty) {
        reason = 'SUPABASE_URL is missing.';
      } else if (cleanSupabaseAnonKey.isEmpty) {
        reason = 'SUPABASE_ANON_KEY is missing.';
      } else {
        reason = 'Initialization failed or was never called successfully.';
      }
      throw StateError('Supabase Client Access Error: $reason');
    }
    return Supabase.instance.client;
  }

  static bool get isDemoMode => false;
}
