import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import './revenuecat_service.dart';
import './supabase_service.dart';
import './revenuecat_web_checkout.dart';

enum SubscriptionActionStatus {
  success,
  cancelled,
  unavailable,
  noEntitlement,
  verificationFailed,
  failed,
  checkoutOpened,
}

class SubscriptionActionResult {
  final SubscriptionActionStatus status;
  final String? message;

  const SubscriptionActionResult(this.status, [this.message]);
  bool get isSuccess => status == SubscriptionActionStatus.success;
}

class SubscriptionService {
  static bool _storeOperationInProgress = false;
  SubscriptionService({RevenueCatWebCheckout? webCheckout})
    : _webCheckout = webCheckout ?? RevenueCatWebCheckout.shared;

  final RevenueCatWebCheckout _webCheckout;

  Future<SubscriptionActionResult> startHostedCheckout() async {
    if (!SupabaseService.isInitialized || !RevenueCatService.isConfigured) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.unavailable,
        'Hosted billing is not configured for this build.',
      );
    }
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.unavailable,
        'Sign in again before opening checkout.',
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
      final opened = await RevenueCatService.runForCurrentUser(
        userId,
        () => _webCheckout.openForUser(userId),
      );
      if (opened != true) {
        // The browser may have opened before RevenueCat noticed an account
        // switch. Do not let a later callback verify against a stale account.
        _webCheckout.clearPendingCheckout();
        return const SubscriptionActionResult(
          SubscriptionActionStatus.unavailable,
          'Hosted checkout is not configured or could not be opened.',
        );
      }
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        _webCheckout.clearPendingCheckout();
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'Your account changed while checkout was opening.',
        );
      }
      return const SubscriptionActionResult(
        SubscriptionActionStatus.checkoutOpened,
      );
    } catch (error) {
      _webCheckout.clearPendingCheckout();
      if (kDebugMode) debugPrint('Hosted checkout could not be opened: $error');
      return const SubscriptionActionResult(
        SubscriptionActionStatus.failed,
        'Hosted checkout could not be opened.',
      );
    } finally {
      _storeOperationInProgress = false;
    }
  }

  /// Refreshes the subscription from the protected server verifier after the
  /// customer returns. The callback itself is never evidence of a purchase.
  Future<SubscriptionActionResult> verifyHostedCheckoutReturn(
    String expectedUserId,
  ) async {
    if (!SupabaseService.isInitialized) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.verificationFailed,
        'Subscription verification is unavailable.',
      );
    }
    if (SupabaseService.instance.client.auth.currentUser?.id !=
        expectedUserId) {
      return const SubscriptionActionResult(
        SubscriptionActionStatus.verificationFailed,
        'The signed-in account changed before verification.',
      );
    }
    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'verify-purchase',
      );
      if (SupabaseService.instance.client.auth.currentUser?.id !=
          expectedUserId) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
          'The signed-in account changed during verification.',
        );
      }
      if (acceptsBackendVerification(
        expectedUserId: expectedUserId,
        currentUserId: SupabaseService.instance.client.auth.currentUser?.id,
        responseStatus: response.status,
        responseBody: response.data,
      )) {
        return const SubscriptionActionResult(SubscriptionActionStatus.success);
      }
      if (response.status == 402) {
        return const SubscriptionActionResult(
          SubscriptionActionStatus.noEntitlement,
          'No active subscription was verified for this account.',
        );
      }
      return const SubscriptionActionResult(
        SubscriptionActionStatus.verificationFailed,
        'Subscription status could not be verified.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Hosted subscription verification failed: $error');
      }
      return const SubscriptionActionResult(
        SubscriptionActionStatus.verificationFailed,
        'Subscription status could not be verified.',
      );
    }
  }

  Future<Uri?> getSubscriptionManagementUri() async {
    if (!SupabaseService.isInitialized) return null;
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null || !RevenueCatService.isConfigured) return null;
    try {
      final raw = await RevenueCatService.runForCurrentUser(userId, () async {
        final customerInfo = await Purchases.getCustomerInfo();
        return customerInfo.managementURL;
      });
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        return null;
      }
      return RevenueCatWebCheckout.validatedManagementUri(raw);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to load subscription management URL: $error');
      }
      return null;
    }
  }

  Future<bool> openSubscriptionManagement() async {
    if (!SupabaseService.isInitialized) return false;
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null || !RevenueCatService.isConfigured) return false;
    final opened = await RevenueCatService.runForCurrentUser(userId, () async {
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        return false;
      }
      final customerInfo = await Purchases.getCustomerInfo();
      if (SupabaseService.instance.client.auth.currentUser?.id != userId) {
        return false;
      }
      return _webCheckout.openManagementUrl(customerInfo.managementURL);
    });
    return opened == true;
  }

  @visibleForTesting
  static bool acceptsBackendVerification({
    required String expectedUserId,
    required String? currentUserId,
    required int responseStatus,
    required dynamic responseBody,
  }) =>
      expectedUserId == currentUserId &&
      responseStatus == 200 &&
      responseBody is Map &&
      responseBody['success'] == true;

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
        final purchase = await Purchases.purchase(
          PurchaseParams.package(package),
        );
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
      if (kDebugMode) {
        debugPrint('Backend purchase verification failed: $error');
      }
      return false;
    }
  }
}
