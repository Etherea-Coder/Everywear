import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import './revenuecat_service.dart';
import './supabase_service.dart';

enum SubscriptionActionStatus {
  success,
  cancelled,
  unavailable,
  noEntitlement,
  verificationFailed,
  failed,
}

class SubscriptionActionResult {
  final SubscriptionActionStatus status;
  final String? message;

  const SubscriptionActionResult(this.status, [this.message]);
  bool get isSuccess => status == SubscriptionActionStatus.success;
}

class SubscriptionService {
  Future<Offerings?> getOfferings() async {
    if (!RevenueCatService.isConfigured) return null;
    try {
      await RevenueCatService.initialize();
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  Future<SubscriptionActionResult> purchase(Package package) async {
    if (!RevenueCatService.isConfigured) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.unavailable,
        'Purchases are not configured for this build.',
      );
    }
    try {
      if (!await RevenueCatService.ensureCurrentUser()) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.unavailable,
          'Sign in again before purchasing.',
        );
      }
      final userId = SupabaseService.instance.client.auth.currentUser!.id;
      final result = await Purchases.purchasePackage(package);
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'Your account changed during the purchase. Sign in and restore purchases.',
        );
      }
      if (!_hasPaidEntitlement(result.customerInfo)) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.noEntitlement,
          'The store purchase did not activate the required entitlement.',
        );
      }
      if (!await _verifyWithBackend()) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'The purchase could not be verified with Everywear.',
        );
      }
      return const SubscriptionActionResult(SubscriptionActionStatus.success);
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.cancelled,
          'Purchase cancelled.',
        );
      }
      if (kDebugMode) debugPrint('Purchase failed: $error');
      return SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        error.message ?? 'Purchase failed.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Purchase failed: $e');
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Purchase failed.',
      );
    }
  }

  Future<SubscriptionActionResult> restorePurchases() async {
    if (!RevenueCatService.isConfigured) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.unavailable,
        'Purchases are not configured for this build.',
      );
    }
    try {
      if (!await RevenueCatService.ensureCurrentUser()) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.unavailable,
          'Sign in again before restoring purchases.',
        );
      }
      final userId = SupabaseService.instance.client.auth.currentUser!.id;
      final result = await Purchases.restorePurchases();
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'Your account changed during restore. Please try again.',
        );
      }
      if (!_hasPaidEntitlement(result)) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.noEntitlement,
          'No active subscription was found for the required entitlement.',
        );
      }
      if (!await _verifyWithBackend()) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'The restored purchase could not be verified with Everywear.',
        );
      }
      return const SubscriptionActionResult(SubscriptionActionStatus.success);
    } catch (e) {
      if (kDebugMode) debugPrint('Restore purchases failed: $e');
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Restore failed.',
      );
    }
  }

  bool _hasPaidEntitlement(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[RevenueCatService.entitlementId];
    return entitlement != null && entitlement.isActive;
  }

  Future<bool> _verifyWithBackend() async {
    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'verify-purchase',
      );
      return response.status == 200 && response.data?['success'] == true;
    } catch (error) {
      if (kDebugMode)
        debugPrint('Backend purchase verification failed: $error');
      return false;
    }
  }
}
