import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../ads/ad_interstitial_logic.dart';

/// Provider for the AdService singleton
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

/// Provider for premium status
final isPremiumProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for ads enabled status
final adsEnabledProvider = StateProvider<bool>((ref) {
  return true;
});

/// Provider for current action count (for debugging/UI)
final adActionCountProvider = StateProvider<int>((ref) {
  return AdInterstitialLogic.actionCount;
});

/// Provider for actions until next ad
final actionsUntilAdProvider = StateProvider<int>((ref) {
  return AdInterstitialLogic.actionsUntilAd;
});

/// Notifier for managing ad state
class AdStateNotifier extends StateNotifier<AdState> {
  AdStateNotifier() : super(const AdState());

  /// Initialize ad service
  Future<void> initialize({
    bool testMode = true,
    int actionsPerInterstitial = 4,
  }) async {
    await AdService.instance.initialize(
      testMode: testMode,
      actionsPerInterstitial: actionsPerInterstitial,
    );
    state = state.copyWith(isInitialized: true);
  }

  /// Set premium status
  void setPremium(bool isPremium) {
    AdService.instance.setPremium(isPremium);
    state = state.copyWith(isPremium: isPremium);
  }

  /// Track an action
  void trackAction(AdActionType actionType) {
    AdService.instance.trackAction(actionType);
    state = state.copyWith(
      actionCount: AdInterstitialLogic.actionCount,
    );
  }

  /// Track generic action
  void trackGenericAction() {
    AdService.instance.trackGenericAction();
    state = state.copyWith(
      actionCount: AdInterstitialLogic.actionCount,
    );
  }

  /// Show app open ad
  Future<bool> showAppOpenAd() async {
    return await AdService.instance.showAppOpenAd();
  }
}

/// State class for ad management
class AdState {
  final bool isInitialized;
  final bool isPremium;
  final bool adsEnabled;
  final int actionCount;

  const AdState({
    this.isInitialized = false,
    this.isPremium = false,
    this.adsEnabled = true,
    this.actionCount = 0,
  });

  AdState copyWith({
    bool? isInitialized,
    bool? isPremium,
    bool? adsEnabled,
    int? actionCount,
  }) {
    return AdState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPremium: isPremium ?? this.isPremium,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      actionCount: actionCount ?? this.actionCount,
    );
  }

  bool get shouldShowAds => adsEnabled && !isPremium;
}

/// Provider for AdStateNotifier
final adStateProvider = StateNotifierProvider<AdStateNotifier, AdState>((ref) {
  return AdStateNotifier();
});
