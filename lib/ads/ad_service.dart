import 'package:flutter/foundation.dart';

import 'ad_interstitial_logic.dart';
import 'ad_app_open_logic.dart';

/// Central Ad Service - Manages all ad types for the Everywear app
///
/// This service coordinates:
/// - Banner ads (shown at top of screens)
/// - Interstitial ads (shown every N actions)
/// - App open ads (shown after splash screen)
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// await AdService.instance.initialize();
///
/// // Check if user is premium
/// AdService.instance.setPremium(user.isPremium);
///
/// // Track actions for interstitial
/// AdService.instance.trackAction(AdActionType.wardrobe);
/// ```
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Whether the service is initialized
  bool _initialized = false;

  /// Whether user is premium (no ads)
  bool _isPremium = false;

  /// Whether ads are globally enabled
  bool _adsEnabled = true;

  /// Test mode - uses test ad IDs (IMPORTANT: Always use in development!)
  bool _testMode = true;

  // ============================================
  // GETTERS
  // ============================================

  bool get isInitialized => _initialized;
  bool get isPremium => _isPremium;
  bool get adsEnabled => _adsEnabled;
  bool get testMode => _testMode;
  bool get shouldShowAds => _adsEnabled && !_isPremium;

  // ============================================
  // CONFIGURATION
  // ============================================

  /// Initialize the ad service
  ///
  /// Call this in main.dart before running the app
  Future<void> initialize({
    bool testMode = true,
    int actionsPerInterstitial = 4,
  }) async {
    if (_initialized) {
      debugPrint('📱 AdService already initialized');
      return;
    }

    _testMode = testMode;

    // Configure interstitial frequency
    AdInterstitialLogic.configure(actionsPerAd: actionsPerInterstitial);

    // Set up callback for when interstitial should show
    AdInterstitialLogic.onAdTriggered = _onInterstitialTriggered;

    // Set up callback for app open ad
    AdAppOpenLogic.onShowAdRequested = _onShowAppOpenRequested;

    _initialized = true;

    debugPrint('📱 AdService initialized (testMode: $testMode)');
  }

  /// Set premium status (disables all ads)
  void setPremium(bool isPremium) {
    _isPremium = isPremium;

    // Update all ad components
    AdInterstitialLogic.setAdsEnabled(!isPremium);
    AdAppOpenLogic.setAdsEnabled(!isPremium);

    debugPrint('📱 Premium status: $isPremium (ads: ${!isPremium})');
  }

  /// Enable or disable ads globally
  void setAdsEnabled(bool enabled) {
    _adsEnabled = enabled;
    AdInterstitialLogic.setAdsEnabled(enabled);
    AdAppOpenLogic.setAdsEnabled(enabled);

    debugPrint('📱 Ads enabled: $enabled');
  }

  // ============================================
  // ACTION TRACKING
  // ============================================

  /// Track a user action for interstitial ad counter
  void trackAction(AdActionType actionType) {
    if (!shouldShowAds) return;

    debugPrint('📱 Tracking action: ${actionType.name}');
    actionType.register();
  }

  /// Track a generic action
  void trackGenericAction() {
    if (!shouldShowAds) return;

    AdInterstitialLogic.registerAction();
  }

  // ============================================
  // APP OPEN ADS
  // ============================================

  /// Show app open ad (typically after splash screen)
  Future<bool> showAppOpenAd() async {
    if (!shouldShowAds) return false;

    return await AdAppOpenLogic.showAppOpenAd();
  }

  /// Preload app open ad (call when app goes to background)
  void preloadAppOpenAd() {
    if (!shouldShowAds) return;

    AdAppOpenLogic.preloadAd();
  }

  // ============================================
  // INTERNAL CALLBACKS
  // ============================================

  void _onInterstitialTriggered() {
    debugPrint('📱 Interstitial triggered via action counter');

    // TODO: Show actual interstitial when AdMob is integrated
    // For now, just log
    _showPlaceholderInterstitial();
  }

  Future<bool> _onShowAppOpenRequested() async {
    debugPrint('📱 App open ad requested');

    // TODO: Show actual app open ad when AdMob is integrated
    // For now, just return false (no ad shown)
    return false;
  }

  void _showPlaceholderInterstitial() {
    debugPrint('📺 [PLACEHOLDER] Would show interstitial ad here');
    debugPrint('📺 In production, this would show a real AdMob interstitial');
  }

  // ============================================
  // AD UNIT IDS (Configure when integrating AdMob)
  // ============================================

  /// Test ad unit IDs (safe for development)
  static const Map<String, String> testAdUnitIds = {
    'banner': 'ca-app-pub-3940256099942544/6300978111',
    'interstitial': 'ca-app-pub-3940256099942544/1033173712',
    'appOpen': 'ca-app-pub-3940256099942544/9257395921',
    'rewarded': 'ca-app-pub-3940256099942544/5224354917',
  };

  /// Production ad unit IDs (replace with your actual IDs)
  /// TODO: Replace these with your real AdMob ad unit IDs
  static const Map<String, String> productionAdUnitIds = {
    'banner': 'ca-app-pub-YOUR-ID/YOUR-BANNER-ID',
    'interstitial': 'ca-app-pub-YOUR-ID/YOUR-INTERSTITIAL-ID',
    'appOpen': 'ca-app-pub-YOUR-ID/YOUR-APP-OPEN-ID',
    'rewarded': 'ca-app-pub-YOUR-ID/YOUR-REWARDED-ID',
  };

  /// Get the appropriate ad unit ID based on test mode
  String getAdUnitId(String adType) {
    if (_testMode) {
      return testAdUnitIds[adType] ?? '';
    }
    return productionAdUnitIds[adType] ?? '';
  }
}
