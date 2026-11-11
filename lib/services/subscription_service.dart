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
  static bool _storeOperationInProgress = false;

  @visibleForTesting
  static bool acceptsVerifiedResult({
    required String expectedUserId,
    required String? currentUserId,
    required String? revenueCatUserId,
    required int responseStatus,
    required dynamic responseBody,
  }) =>
      expectedUserId == currentUserId &&
      expectedUserId == revenueCatUserId &&
      responseStatus == 200 &&
      responseBody is Map &&
      responseBody['success'] == true;

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
    if (_storeOperationInProgress) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Another purchase or restore is already in progress.',
      );
    }
    _storeOperationInProgress = true;
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.unavailable,
          'Sign in again before purchasing.',
        );
      }
      final result = await RevenueCatService.runForCurrentUser(userId, () async {
        final purchase = await Purchases.purchasePackage(package);
        if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
          return const SubscriptionActionResult(
            SubscriptionActionStatus.verificationFailed,
            'Your account changed during the purchase. Sign in and restore purchases.',
          );
        }
        if (!_hasPaidEntitlement(purchase.customerInfo)) {
          return const SubscriptionActionResult(
            SubscriptionActionStatus.noEntitlement,
            'The store purchase did not activate the required entitlement.',
          );
        }
        if (!await _verifyWithBackend(userId)) {
          return const SubscriptionActionResult(
            SubscriptionActionStatus.verificationFailed,
            'The purchase could not be verified with Everywear.',
          );
        }
        return const SubscriptionActionResult(SubscriptionActionStatus.success);
      });
      return result ??
          const SubscriptionActionResult(
            SubscriptionActionStatus.verificationFailed,
            'Your account changed during the purchase. Sign in and restore purchases.',
          );
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
    } finally {
      _storeOperationInProgress = false;
    }
  }

  Future<SubscriptionActionResult> restorePurchases() async {
    if (!RevenueCatService.isConfigured) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.unavailable,
        'Purchases are not configured for this build.',
      );
    }
    if (_storeOperationInProgress) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Another purchase or restore is already in progress.',
      );
    }
    _storeOperationInProgress = true;
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.unavailable,
          'Sign in again before restoring purchases.',
        );
      }
      final result = await RevenueCatService.runForCurrentUser(
        userId,
        () async {
          final restored = await Purchases.restorePurchases();
          if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
            return const SubscriptionActionResult(
              SubscriptionActionStatus.verificationFailed,
              'Your account changed during restore. Please try again.',
            );
          }
          if (!_hasPaidEntitlement(restored)) {
            return const SubscriptionActionResult(
              SubscriptionActionStatus.noEntitlement,
              'No active subscription was found for the required entitlement.',
            );
          }
          if (!await _verifyWithBackend(userId)) {
            return const SubscriptionActionResult(
              SubscriptionActionStatus.verificationFailed,
              'The restored purchase could not be verified with Everywear.',
            );
          }
          return const SubscriptionActionResult(
            SubscriptionActionStatus.success,
          );
        },
      );
      return result ??
          const SubscriptionActionResult(
            SubscriptionActionStatus.verificationFailed,
            'Your account changed during restore. Please try again.',
          );
    } catch (e) {
      if (kDebugMode) debugPrint('Restore purchases failed: $e');
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Restore failed.',
      );
    } finally {
      _storeOperationInProgress = false;
    }
  }

  bool _hasPaidEntitlement(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[RevenueCatService.entitlementId];
    return entitlement != null && entitlement.isActive;
  }

  Future<bool> _verifyWithBackend(String expectedUserId) async {
    try {
      if (SupabaseService.instance.client.auth.currentUser?.id !=
          expectedUserId) {
        return false;
      }
      final response = await SupabaseService.instance.client.functions.invoke(
        'verify-purchase',
      );
      final storeUserId = await Purchases.appUserID;
      return acceptsVerifiedResult(
        expectedUserId: expectedUserId,
        currentUserId: SupabaseService.instance.client.auth.currentUser?.id,
        revenueCatUserId: storeUserId,
        responseStatus: response.status,
        responseBody: response.data,
      );
    } catch (error) {
      if (kDebugMode)
        debugPrint('Backend purchase verification failed: $error');
      return false;
    }
  }
}
