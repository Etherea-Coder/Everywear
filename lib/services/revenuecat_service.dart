import 'dart:io';
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
}
