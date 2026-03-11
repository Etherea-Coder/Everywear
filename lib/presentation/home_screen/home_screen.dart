import 'package:flutter/material.dart';
import '../daily_log/daily_log.dart';
import '../wardrobe_management/wardrobe_management.dart';
import '../smart_suggestions/smart_suggestions.dart';
import '../purchase_tracking/purchase_tracking.dart';
import '../settings_profile/settings_profile.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Home Screen - Main navigation hub for the Everywear app
/// 
/// Uses IndexedStack for preserving state across tabs.
/// Navigation structure (5 tabs):
/// - Index 0: Today (Daily Log)
/// - Index 1: Wardrobe (Wardrobe Management)
/// - Index 2: Style (Smart Suggestions)
/// - Index 3: Purchases (Purchase Tracking)
/// - Index 4: Profile (Settings & Insights)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// Screens for each tab - Insights moved to Profile screen
  /// for better organization and to reduce nav bar clutter
  final List<Widget> _screens = [
    const DailyLog(),           // Index 0: Today
    const WardrobeManagement(), // Index 1: Wardrobe
    const SmartSuggestions(),   // Index 2: Style
    const PurchaseTracking(),   // Index 3: Purchases
    const SettingsProfile(),    // Index 4: Profile (includes Insights link)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
