import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daily_log/daily_log.dart';
import '../wardrobe_management/wardrobe_management.dart';
import '../smart_suggestions/smart_suggestions.dart';
import '../purchase_tracking/purchase_tracking.dart';
import '../settings_profile/profile_screen.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../layout/ad_layout.dart';
import '../../providers/ad_providers.dart';

/// Home Screen - Main navigation hub for the Everywear app
///
/// Uses IndexedStack for preserving state across tabs.
/// Includes AdLayout wrapper for banner ad space.
///
/// Navigation structure (5 tabs):
/// - Index 0: Today (Daily Log)
/// - Index 1: Wardrobe (Wardrobe Management)
/// - Index 2: Style (Smart Suggestions)
/// - Index 3: Purchases (Purchase Tracking)
/// - Index 4: Profile (Settings & Insights)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 2;

  /// Screens for each tab - Insights moved to Profile screen
  /// for better organization and to reduce nav bar clutter
  final List<Widget> _screens = [
    const DailyLog(),           // Index 0: Today
    const WardrobeManagement(), // Index 1: Wardrobe
    const SmartSuggestions(),   // Index 2: Style
    const PurchaseTracking(),   // Index 3: Purchases
    const ProfileScreen(),    // Index 4: Profile (includes Insights link)
  ];

  /// Track navigation as actions for interstitial ads
  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      // Track navigation action for interstitial ad counter
      // Only count major section changes, not just tab switches
      // Uncomment below if you want navigation to count as actions
      // ref.read(adStateProvider.notifier).trackAction(AdActionType.navigation);

      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get premium status from provider
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      // AdLayout wraps the body to add banner space at top
      body: AdLayout(
        isPremium: isPremium,
        showDebugBackground: true, // Set to false in production
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
