import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import './serial_operation_queue.dart';
import './supabase_service.dart';

class RevenueCatService {
  static const _freeBeta = bool.fromEnvironment(
    'EVERYWEAR_FREE_BETA',
    defaultValue: false,
  );
  static const _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
  );
  static bool _initialized = false;
  static Future<void>? _initializing;
  static final SerialOperationQueue _identityQueue = SerialOperationQueue();

  static bool get isConfigured {
    final supportedPlatform = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
    final key = !supportedPlatform
        ? ''
        : Platform.isAndroid
        ? _androidKey
        : _iosKey;
    return canConfigurePurchases(
      freeBeta: _freeBeta,
      supportedPlatform: supportedPlatform,
      apiKey: key,
      requiredEntitlementId: entitlementId,
    );
  }

  @visibleForTesting
  static bool canConfigurePurchases({
    required bool freeBeta,
    required bool supportedPlatform,
    required String apiKey,
    required String requiredEntitlementId,
  }) =>
      !freeBeta &&
      supportedPlatform &&
      apiKey.isNotEmpty &&
      requiredEntitlementId.isNotEmpty;

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
      await _serializeIdentity(() async {
        final currentUserId =
            SupabaseService.instance.client.auth.currentUser?.id;
        if (currentUserId == null) {
          await Purchases.logOut();
          return;
        }
        // The caller may have become stale while waiting for the SDK. Always
        // bind to the latest authenticated Supabase identity.
        if (currentUserId != supabaseUserId && kDebugMode) {
          debugPrint(
            'RevenueCat login target changed; binding current account',
          );
        }
        await Purchases.logIn(currentUserId);
        final latestUserId =
            SupabaseService.instance.client.auth.currentUser?.id;
        if (latestUserId == null) {
          await Purchases.logOut();
        } else if (latestUserId != currentUserId) {
          await Purchases.logIn(latestUserId);
        }
      });
    } catch (error) {
      if (kDebugMode) debugPrint('RevenueCat login failed: $error');
    }
  }

  /// Purchase/restore callers must establish identity successfully themselves;
  /// startup login is only best effort and can race with authentication.
  static Future<bool> ensureCurrentUser({String? expectedUserId}) async {
    if (!isConfigured) return false;
    await initialize();
    if (!_initialized) return false;
    return _serializeIdentity(() async {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null ||
          (expectedUserId != null && expectedUserId != userId)) {
        return false;
      }
      try {
        await Purchases.logIn(userId);
        return SupabaseService.instance.client.auth.currentUser?.id == userId &&
            await Purchases.appUserID == userId;
      } catch (error) {
        if (kDebugMode) debugPrint('Unable to bind purchase identity: $error');
        return false;
      }
    });
  }

  /// Keeps purchase/restore and account identity changes in one serialized
  /// critical section. A sign-out or account switch cannot rebind the native
  /// RevenueCat singleton while a store transaction is still being verified.
  static Future<T?> runForCurrentUser<T>(
    String expectedUserId,
    Future<T> Function() operation,
  ) async {
    if (!isConfigured) return null;
    await initialize();
    if (!_initialized) return null;
    return _serializeIdentity(() async {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null || userId != expectedUserId) return null;
      try {
        await Purchases.logIn(userId);
        if (SupabaseService.instance.client.auth.currentUser?.id != userId ||
            await Purchases.appUserID != userId) {
          return null;
        }
        final result = await operation();
        if (SupabaseService.instance.client.auth.currentUser?.id != userId ||
            await Purchases.appUserID != userId) {
          return null;
        }
        return result;
      } catch (error) {
        if (kDebugMode)
          debugPrint('RevenueCat account operation failed: $error');
        rethrow;
      }
    });
  }

  /// Log out from RevenueCat (when user signs out)
  static Future<void> logOut() async {
    if (!_initialized) return;
    await _serializeIdentity(() async {
      try {
        final currentUserId =
            SupabaseService.instance.client.auth.currentUser?.id;
        if (currentUserId == null) {
          await Purchases.logOut();
        } else {
          // Ignore a delayed sign-out notification if a newer account already
          // became current.
          await Purchases.logIn(currentUserId);
          return;
        }
        final latestUserId =
            SupabaseService.instance.client.auth.currentUser?.id;
        if (latestUserId != null) await Purchases.logIn(latestUserId);
      } catch (e) {
        if (kDebugMode) debugPrint('RevenueCat logout failed: $e');
      }
    });
  }

  static Future<T> _serializeIdentity<T>(Future<T> Function() operation) {
    return _identityQueue.run(operation);
  }
}
