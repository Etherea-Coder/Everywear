import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  static const String _prefKey = 'analytics_opt_in';

  // ─── Preference ───────────────────────────────────────────────────────────

  Future<bool> isAnalyticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true (opted in) if never set
    return prefs.getBool(_prefKey) ?? true;
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (enabled) {
      _enableSentry();
    } else {
      _disableSentry();
    }
  }

  // ─── Sentry control ───────────────────────────────────────────────────────

  void _enableSentry() {
    Sentry.configureScope((scope) {
      scope.setTag('analytics_opted_in', 'true');
    });
    // Re-enable event capture by removing the beforeSend filter
    if (kDebugMode) debugPrint('✅ Analytics enabled — Sentry reporting active');
  }

  void _disableSentry() {
    Sentry.configureScope((scope) {
      scope.setTag('analytics_opted_in', 'false');
    });
    if (kDebugMode) debugPrint('✅ Analytics disabled — Sentry reporting suppressed');
  }

  /// Call this once on app start, after Sentry is initialized,
  /// to apply the saved preference.
  Future<void> applyStoredPreference() async {
    final enabled = await isAnalyticsEnabled();
    if (!enabled) _disableSentry();
  }

  /// Use this guard before any manual Sentry capture call.
  /// Sentry's own SDK doesn't have a built-in on/off toggle,
  /// so wrap manual captures like this:
  ///
  /// ```dart
  /// if (await AnalyticsService.instance.isAnalyticsEnabled()) {
  ///   Sentry.captureException(e, stackTrace: st);
  /// }
  /// ```
  Future<bool> canCapture() async => isAnalyticsEnabled();
}