import 'package:flutter/material.dart';

import '../ads/ad_banner_placeholder.dart';
import '../ads/ad_interstitial_logic.dart';

/// Ad Layout - Wrapper that adds banner space to any screen
///
/// This is the recommended way to add ads to your screens.
/// It automatically reserves space for the banner ad at the top.
///
/// Usage:
/// ```dart
/// // Wrap your screen content
/// Scaffold(
///   body: AdLayout(
///     child: YourScreenContent(),
///   ),
/// )
///
/// // Or with premium mode (no ads)
/// AdLayout(
///   isPremium: userIsPremium,
///   child: YourScreenContent(),
/// )
/// ```
///
/// Result:
/// ┌─────────────────────┐
/// │   AppBar            │
/// ├─────────────────────┤
/// │   [Banner Ad Space] │ ← 50px reserved
/// ├─────────────────────┤
/// │   Page Content      │
/// │                     │
/// ├─────────────────────┤
/// │   Bottom Nav        │
/// └─────────────────────┘
class AdLayout extends StatelessWidget {
  /// The screen content to display below the ad
  final Widget child;

  /// Whether this screen should show ads
  /// Set to true for premium users to hide ads
  final bool isPremium;

  /// Custom height for the banner (default: 50)
  final double bannerHeight;

  /// Whether to show debug background on placeholder
  final bool showDebugBackground;

  /// Optional custom placeholder for testing
  final Widget? customPlaceholder;

  const AdLayout({
    Key? key,
    required this.child,
    this.isPremium = false,
    this.bannerHeight = 50,
    this.showDebugBackground = false,
    this.customPlaceholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Premium users don't see ads
    if (isPremium || !AdInterstitialLogic.adsEnabled) {
      return child;
    }

    return Column(
      children: [
        // Banner ad space at top
        customPlaceholder ??
            AdBannerPlaceholder(
              height: bannerHeight,
              showDebugBackground: showDebugBackground,
            ),

        // Main content takes remaining space
        Expanded(child: child),
      ],
    );
  }
}

/// Ad Scaffold - Complete scaffold with built-in ad space
///
/// Alternative to using AdLayout wrapper.
/// Provides a complete scaffold with ad space included.
///
/// Usage:
/// ```dart
/// return AdScaffold(
///   appBar: AppBar(title: Text('My Screen')),
///   body: MyContent(),
///   bottomNavigationBar: MyBottomNav(),
/// );
/// ```
class AdScaffold extends StatelessWidget {
  /// App bar to display
  final PreferredSizeWidget? appBar;

  /// Main body content
  final Widget body;

  /// Bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Whether user is premium (hides ads)
  final bool isPremium;

  /// Whether to show debug background
  final bool showDebugBackground;

  const AdScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.isPremium = false,
    this.showDebugBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPremium || !AdInterstitialLogic.adsEnabled) {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          AdBannerPlaceholder(
            showDebugBackground: showDebugBackground,
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Mixin for screens that want to track actions for interstitial ads
///
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with AdActionTracker {
///   void _onUserDidSomething() {
///     trackAdAction(AdActionType.wardrobe);
///     // ... rest of logic
///   }
/// }
/// ```
mixin AdActionTracker<T extends StatefulWidget> on State<T> {
  /// Track an action for the interstitial ad counter
  void trackAdAction(AdActionType actionType) {
    actionType.register();
  }

  /// Track a generic action
  void trackAdActionGeneric() {
    AdInterstitialLogic.registerAction();
  }
}
