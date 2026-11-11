import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import './supabase_service.dart';

class RevenueCatService {
  static const _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
  );
  static bool _initialized = false;
  static Future<void>? _initializing;

  static bool get isConfigured {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return false;
    final key = Platform.isAndroid ? _androidKey : _iosKey;
    return key.isNotEmpty && entitlementId.isNotEmpty;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing != null) return _initializing;
    final operation = _configure();
    _initializing = operation;
    try {
      await operation;
    } finally {
      _initializing = null;
    }
  }

  static Future<void> _configure() async {
    // RevenueCat only supports iOS and Android
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      if (kDebugMode)
        debugPrint(
          '📱 RevenueCat: Platform not supported, skipping initialization',
        );
      return;
    }
    if (!isConfigured) {
      if (kDebugMode)
        debugPrint('RevenueCat is not configured; purchases are disabled');
      return;
    }
    final apiKey = Platform.isAndroid ? _androidKey : _iosKey;

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RevenueCat configuration failed: $e');
    }
  }

  /// Log in to RevenueCat with the Supabase user ID
  static Future<void> logIn(String supabaseUserId) async {
    await initialize();
    if (!_initialized) return;
    try {
      await Purchases.logIn(supabaseUserId);
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat login failed: $e');
    }
  }

  /// Purchase/restore callers must establish identity successfully themselves;
  /// startup login is only best effort and can race with authentication.
  static Future<bool> ensureCurrentUser() async {
    if (!isConfigured) return false;
    await initialize();
    if (!_initialized) return false;
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await Purchases.logIn(userId);
      return SupabaseService.instance.client.auth.currentUser?.id == userId &&
          await Purchases.appUserID == userId;
    } catch (error) {
      if (kDebugMode) debugPrint('Unable to bind purchase identity: $error');
      return false;
    }
  }

  /// Log out from RevenueCat (when user signs out)
  static Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat logout failed: $e');
    }
  }
}
