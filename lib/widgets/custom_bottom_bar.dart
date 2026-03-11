import 'package:flutter/material.dart';

/// Custom bottom navigation bar for wardrobe analytics app
/// Implements bottom-heavy interaction design with thumb-accessible navigation
///
/// Reduced to 5 tabs for better UX and to prevent label truncation:
/// 1. Today (Daily Log) - Core daily interaction
/// 2. Wardrobe - Essential wardrobe organization
/// 3. Style (Smart Suggestions) - AI-powered recommendations
/// 4. Purchases - Purchase logging and spending analysis
/// 5. Profile - User profile and settings (includes Insights link)
class CustomBottomBar extends StatelessWidget {
  /// Current selected index (0-4)
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle:
            theme.bottomNavigationBarTheme.unselectedLabelStyle,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          // Daily Log - Core daily interaction
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined, size: 24),
            activeIcon: Icon(Icons.today, size: 24),
            label: 'Today',
            tooltip: 'Daily outfit log',
          ),

          // Wardrobe Management - Essential wardrobe organization
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined, size: 24),
            activeIcon: Icon(Icons.checkroom, size: 24),
            label: 'Wardrobe',
            tooltip: 'Manage wardrobe items',
          ),

          // Smart Suggestions - AI-powered recommendations
          // Shortened from "Suggestions" to "Style" to prevent truncation
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined, size: 24),
            activeIcon: Icon(Icons.auto_awesome, size: 24),
            label: 'Style',
            tooltip: 'Smart outfit suggestions',
          ),

          // Purchase Tracking - Purchase logging and spending analysis
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined, size: 24),
            activeIcon: Icon(Icons.shopping_bag, size: 24),
            label: 'Purchases',
            tooltip: 'Track purchases',
          ),

          // Profile - User profile and settings (includes Insights)
          // Renamed from "Settings" to "Profile" for clearer context
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person, size: 24),
            label: 'Profile',
            tooltip: 'Profile and settings',
          ),
        ],
      ),
    );
  }
}
