import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../insights_dashboard/insights_dashboard.dart';
import '../wardrobe_management/wardrobe_management.dart';
import '../outfit_capture_flow/outfit_capture_flow.dart';
import '../smart_suggestions/smart_suggestions.dart';
import '../settings_profile/settings_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InsightsDashboard(),
    const WardrobeManagement(),
    const OutfitCaptureFlow(),
    const SmartSuggestions(),
    const SettingsProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get localizations
    // ignore: unused_local_variable
    final theme = Theme.of(context);

    // If localizations are needed for tab labels, we would access them here
    // final l10n = AppLocalizations.of(context)!; 

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline), // Or auto_awesome
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Ideas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
