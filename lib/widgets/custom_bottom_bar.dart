import 'package:flutter/material.dart';

/// Custom bottom navigation bar for wardrobe analytics app
/// Implements bottom-heavy interaction design with thumb-accessible navigation
///
/// Navigation items based on Mobile Navigation Hierarchy:
/// 1. Daily Log (Today/Camera) - Core daily interaction
/// 2. Wardrobe Management (Closet/Hanger) - Essential wardrobe organization
/// 3. Smart Suggestions (Lightbulb/Sparkle) - AI-powered recommendations
/// 4. Insights Dashboard (Graph/Chart) - Analytics and learning paths
/// 5. Purchase Tracking (Shopping Bag) - Purchase logging and spending analysis
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
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
        items: [
          // Daily Log - Core daily interaction
          BottomNavigationBarItem(
            icon: const Icon(Icons.today_outlined, size: 24),
            activeIcon: const Icon(Icons.today, size: 24),
            label: 'Today',
            tooltip: 'Daily outfit log',
          ),

          // Wardrobe Management - Essential wardrobe organization
          BottomNavigationBarItem(
            icon: const Icon(Icons.checkroom_outlined, size: 24),
            activeIcon: const Icon(Icons.checkroom, size: 24),
            label: 'Wardrobe',
            tooltip: 'Manage wardrobe items',
          ),

          // Smart Suggestions - AI-powered recommendations
          BottomNavigationBarItem(
            icon: const Icon(Icons.lightbulb_outline, size: 24),
            activeIcon: const Icon(Icons.lightbulb, size: 24),
            label: 'Suggestions',
            tooltip: 'Smart outfit suggestions',
          ),

          // Insights Dashboard - Analytics and learning paths
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined, size: 24),
            activeIcon: const Icon(Icons.insights, size: 24),
            label: 'Insights',
            tooltip: 'Analytics and insights',
          ),

          // Purchase Tracking - Purchase logging and spending analysis
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined, size: 24),
            activeIcon: const Icon(Icons.shopping_bag, size: 24),
            label: 'Purchases',
            tooltip: 'Track purchases',
          ),
        ],
      ),
    );
  }
}
