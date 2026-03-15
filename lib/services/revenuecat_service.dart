import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {

  static Future<void> initialize() async {

    String apiKey;

    if (Platform.isIOS) {
      apiKey = "test_zLfsCOHvuUGXXJxLixvMbkYPKTA";
    } else if (Platform.isAndroid) {
      apiKey = "test_zLfsCOHvuUGXXJxLixvMbkYPKTA";
    } else {
      throw UnsupportedError("Platform not supported");
    }

    await Purchases.configure(
      PurchasesConfiguration(apiKey),
    );
  }

  /// Log in to RevenueCat with the Supabase user ID
  /// This ensures the webhook can match purchases to Supabase users
  static Future<void> logIn(String supabaseUserId) async {
    try {
      await Purchases.logIn(supabaseUserId);
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
    }
  }

  /// Log out from RevenueCat (when user signs out)
  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout failed: $e');
    }
  }
}
