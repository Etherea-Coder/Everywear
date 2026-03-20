import 'package:flutter/foundation.dart';

/// Interstitial ad logic with action counter
///
/// Tracks user actions and triggers interstitial ad after N actions.
/// Currently placeholder - will be connected to AdMob later.
///
/// Usage:
/// ```dart
/// // Call this after any meaningful user action
/// AdInterstitialLogic.registerAction();
///
/// // Check if ad should be shown
/// if (AdInterstitialLogic.shouldShowAd) {
///   // Show interstitial (placeholder for now)
///   await AdInterstitialLogic.showInterstitialIfReady(context);
/// }
/// ```
class AdInterstitialLogic {
  AdInterstitialLogic._();

  /// Number of actions before showing an interstitial
  static int _actionsPerAd = 4;

  /// Current action counter
  static int _actionCounter = 0;

  /// Whether ads are enabled (can be disabled for premium users)
  static bool _adsEnabled = true;

  /// Callback for when ad should be shown (set by AdService)
  static VoidCallback? onAdTriggered;

  /// Get current action count (for debugging/UI)
  static int get actionCount => _actionCounter;

  /// Get actions needed until next ad
  static int get actionsUntilAd => _actionsPerAd - _actionCounter;

  /// Check if ad should be shown
  static bool get shouldShowAd =>
      _actionCounter >= _actionsPerAd && _adsEnabled;

  /// Check if ads are enabled
  static bool get adsEnabled => _adsEnabled;

  /// Configure actions per ad (default: 4)
  static void configure({int actionsPerAd = 4}) {
    _actionsPerAd = actionsPerAd;
    _actionCounter = 0;
  }

  /// Enable or disable ads (for premium users)
  static void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
    if (!enabled) {
      _actionCounter = 0;
    }
  }

  /// Register a user action
  ///
  /// Call this after meaningful actions like:
  /// - Adding a wardrobe item
  /// - Logging an outfit
  /// - Viewing suggestions
  /// - Making a purchase entry
  /// - Navigating to a new major section
  static void registerAction() {
    if (!_adsEnabled) return;

    _actionCounter++;
    if (kDebugMode) debugPrint('📱 Ad action count: $_actionCounter/$_actionsPerAd');

    if (_actionCounter >= _actionsPerAd) {
      _triggerAd();
    }
  }

  /// Force reset the counter (useful after showing an ad)
  static void resetCounter() {
    _actionCounter = 0;
    if (kDebugMode) debugPrint('📱 Ad counter reset');
  }

  /// Trigger the ad callback
  static void _triggerAd() {
    if (kDebugMode) debugPrint('📺 Interstitial ad triggered!');

    // Call the registered callback (will show real ad when integrated)
    if (onAdTriggered != null) {
      onAdTriggered!();
    }

    // Reset counter after triggering
    _actionCounter = 0;
  }

  /// Show interstitial if ready (placeholder for now)
  ///
  /// When you integrate AdMob, this will:
  /// 1. Check if ad is loaded
  /// 2. Show the interstitial
  /// 3. Preload next ad
  static Future<bool> showInterstitialIfReady() async {
    if (!_adsEnabled) return false;

    // Placeholder: just log and return
    if (kDebugMode) debugPrint('📺 Would show interstitial ad here (placeholder)');

    // TODO: When integrating AdMob:
    // if (_interstitialAd != null) {
    //   await _interstitialAd!.show();
    //   _interstitialAd = null;
    //   _loadInterstitial(); // Preload next
    //   return true;
    // }

    return false;
  }
}

/// Types of actions that can trigger ad counter
///
/// Use these to categorize actions for analytics and future targeting
enum AdActionType {
  /// Wardrobe actions (add, edit, delete items)
  wardrobe,

  /// Outfit logging actions
  outfitLog,

  /// Viewing AI suggestions
  suggestions,

  /// Purchase tracking actions
  purchase,

  /// Navigation to major sections
  navigation,

  /// Achievement/badge unlocks
  achievement,
}

/// Extension to easily register typed actions
extension AdActionTypeExtension on AdActionType {
  /// Register this action type with the ad counter
  void register() {
    if (kDebugMode) debugPrint('📱 Ad action: $name');
    AdInterstitialLogic.registerAction();
  }
}
