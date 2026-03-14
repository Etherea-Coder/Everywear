import 'package:purchases_flutter/purchases_flutter.dart';

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
        rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final result = await Purchases.restorePurchases();
      return result.entitlements.active.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}