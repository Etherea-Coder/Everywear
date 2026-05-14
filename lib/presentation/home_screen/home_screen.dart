import 'package:flutter/material.dart';
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
  final Set<int> _initializedTabs = {0};

  Widget _buildScreen(int index) {
    if (!_initializedTabs.contains(index)) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (index) {
      case 0: return const InsightsDashboard();
      case 1: return const WardrobeManagement();
      case 2: return const OutfitCaptureFlow();
      case 3: return const SmartSuggestions();
      case 4: return const SettingsProfile();
      default: return const InsightsDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (i) => _buildScreen(i)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _initializedTabs.add(index);
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
