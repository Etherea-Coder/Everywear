import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  Future<bool> purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final result = await Purchases.restorePurchases();
      return result.entitlements.active.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('Restore purchases failed: $e');
      return false;
    }
  }
}
