import 'package:flutter/material.dart';
import '../daily_log/daily_log.dart';
import '../wardrobe_management/wardrobe_management.dart';
import '../smart_suggestions/smart_suggestions.dart';
import '../insights_dashboard/insights_dashboard.dart';
import '../purchase_tracking/purchase_tracking.dart';
import '../settings_profile/settings_profile.dart';
import '../../widgets/custom_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DailyLog(),
    const WardrobeManagement(),
    const SmartSuggestions(),
    const InsightsDashboard(),
    const PurchaseTracking(),
    const SettingsProfile(),
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
