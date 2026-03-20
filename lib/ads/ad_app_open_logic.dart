import 'package:flutter/foundation.dart';

/// App Open ad logic - manages video ad shown after splash screen
///
/// Shows a video ad ~2-3 seconds after splash, for ~10 seconds max.
/// This is a placeholder structure ready for AdMob integration.
///
/// Typical flow:
/// 1. Splash screen shows
/// 2. After splash, app open ad shows for 10 seconds
/// 3. User can skip after 5 seconds
/// 4. Ad dismisses, user enters main app
class AdAppOpenLogic {
  AdAppOpenLogic._();

  /// Whether ads are enabled
  static bool _adsEnabled = true;

  /// Whether an app open ad is currently showing
  static bool _isShowing = false;

  /// Minimum time before showing app open ad after launch (seconds)
  static const int delayAfterSplash = 2;

  /// Maximum duration of app open ad (seconds)
  static const int maxAdDuration = 10;

  /// Time before user can skip the ad (seconds)
  static const int skipAfterSeconds = 5;

  /// Callback when ad should be shown
  static Future<bool> Function()? onShowAdRequested;

  /// Callback when ad is dismissed
  static VoidCallback? onAdDismissed;

  /// Check if app open ads are enabled
  static bool get adsEnabled => _adsEnabled;

  /// Check if an ad is currently showing
  static bool get isShowing => _isShowing;

  /// Enable or disable app open ads
  static void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
  }

  /// Show app open ad after splash screen
  ///
  /// Returns true if ad was shown, false otherwise
  static Future<bool> showAppOpenAd() async {
    if (!_adsEnabled || _isShowing) {
      if (kDebugMode) debugPrint('📺 App open ad skipped (disabled or already showing)');
      return false;
    }

    _isShowing = true;
    if (kDebugMode) debugPrint('📺 Showing app open ad...');

    // Call the registered callback
    if (onShowAdRequested != null) {
      final shown = await onShowAdRequested!();
      _isShowing = false;
      return shown;
    }

    // Placeholder behavior
    if (kDebugMode) debugPrint('📺 Would show app open ad (placeholder)');
    _isShowing = false;
    return false;
  }

  /// Called when ad is dismissed
  static void dismissAd() {
    _isShowing = false;
    if (kDebugMode) debugPrint('📺 App open ad dismissed');

    if (onAdDismissed != null) {
      onAdDismissed!();
    }
  }

  /// Preload next app open ad (call this when app moves to background)
  static void preloadAd() {
    if (!_adsEnabled) return;

    if (kDebugMode) debugPrint('📺 Preloading app open ad...');

    // TODO: When integrating AdMob:
    // AppOpenAd.load(
    //   adUnitId: 'ca-app-pub-xxxxx/xxxxx',
    //   request: AdRequest(),
    //   orientation: AppOpenAd.orientationPortrait,
    //   onAdLoaded: (ad) => _appOpenAd = ad,
    //   onAdFailedToLoad: (error) => print('Failed to load: $error'),
    // );
  }
}
