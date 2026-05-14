import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // Replace these with your actual keys from RevenueCat dashboard
  static const _androidTestKey = 'test_zLfsCOHvuUGXXJxLixvMbkYPKTA';
  static const _androidProdKey = 'your_android_prod_key_here';
  static const _iosTestKey = 'test_zLfsCOHvuUGXXJxLixvMbkYPKTA';
  static const _iosProdKey = 'your_ios_prod_key_here';

  static Future<void> initialize() async {
    // RevenueCat only supports iOS and Android
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      if (kDebugMode) debugPrint('📱 RevenueCat: Platform not supported, skipping initialization');
      return;
    }

    String apiKey;
    if (Platform.isIOS) {
      apiKey = kReleaseMode ? _iosProdKey : _iosTestKey;
    } else {
      apiKey = kReleaseMode ? _androidProdKey : _androidTestKey;
    }

    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ RevenueCat configuration failed: $e');
    }
  }

  /// Log in to RevenueCat with the Supabase user ID
  static Future<void> logIn(String supabaseUserId) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await Purchases.logIn(supabaseUserId);
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat login failed: $e');
    }
  }

  /// Log out from RevenueCat (when user signs out)
  static Future<void> logOut() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      if (kDebugMode) debugPrint('RevenueCat logout failed: $e');
    }
  }
}
