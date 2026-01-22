import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/achievement_badge_card_widget.dart';
import './widgets/achievement_detail_modal_widget.dart';
import './widgets/achievement_stats_widget.dart';
import './widgets/celebration_overlay_widget.dart';

/// Achievement Gallery Screen - Personal progress achievements and milestones
/// Displays earned badges, locked achievements, and personal fashion journey progress
class AchievementGallery extends StatefulWidget {
  const AchievementGallery({Key? key}) : super(key: key);

  @override
  State<AchievementGallery> createState() => _AchievementGalleryState();
}

class _AchievementGalleryState extends State<AchievementGallery>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showCelebration = false;
  late AnimationController _celebrationController;

  final List<String> _categories = [
    'All',
    'Consistency',
    'Style',
    'Mindful',
    'Sustainability',
  ];

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': '1',
      'title': 'First Steps',
      'description': 'Logged your first outfit',
      'category': 'Consistency',
      'icon': 'emoji_events',
      'isUnlocked': true,
      'unlockedDate': DateTime(2026, 1, 5),
      'rarity': 'Common',
      'progress': 1.0,
      'requirement': 'Log 1 outfit',
      'backstory':
          'Every journey begins with a single step. You\'ve started your mindful fashion journey!',
      'relatedChallenges': ['Daily Logger', 'Wardrobe Explorer'],
    },
    {
      'id': '2',
      'title': 'Week Warrior',
      'description': 'Logged outfits for 7 consecutive days',
      'category': 'Consistency',
      'icon': 'local_fire_department',
      'isUnlocked': true,
      'unlockedDate': DateTime(2026, 1, 12),
      'rarity': 'Rare',
      'progress': 1.0,
      'requirement': 'Log outfits for 7 days straight',
      'backstory':
          'Consistency is the foundation of mindful living. Your dedication is inspiring!',
      'relatedChallenges': ['Streak Master', 'Daily Dedication'],
    },
    {
      'id': '3',
      'title': 'Style Innovator',
      'description': 'Created 10 unique outfit combinations',
      'category': 'Style',
      'icon': 'palette',
      'isUnlocked': true,
      'unlockedDate': DateTime(2026, 1, 10),
      'rarity': 'Uncommon',
      'progress': 1.0,
      'requirement': 'Create 10 different outfits',
      'backstory':
          'Creativity flourishes when you explore your wardrobe\'s potential. Keep experimenting!',
      'relatedChallenges': ['Mix Master', 'Creative Dresser'],
    },
    {
      'id': '4',
      'title': 'Mindful Shopper',
      'description': 'Tracked 5 purchases with reflection notes',
      'category': 'Mindful',
      'icon': 'shopping_bag',
      'isUnlocked': true,
      'unlockedDate': DateTime(2026, 1, 8),
      'rarity': 'Uncommon',
      'progress': 1.0,
      'requirement': 'Log 5 purchases with notes',
      'backstory':
          'Mindful consumption starts with awareness. You\'re making intentional choices!',
      'relatedChallenges': ['Thoughtful Buyer', 'Purchase Tracker'],
    },
    {
      'id': '5',
      'title': 'Sustainability Champion',
      'description': 'Achieved 50% cost-per-wear reduction',
      'category': 'Sustainability',
      'icon': 'eco',
      'isUnlocked': false,
      'unlockedDate': null,
      'rarity': 'Epic',
      'progress': 0.35,
      'requirement': 'Reduce cost-per-wear by 50%',
      'backstory':
          'True sustainability means maximizing what you already own. You\'re on the right path!',
      'relatedChallenges': ['Eco Warrior', 'Value Maximizer'],
    },
    {
      'id': '6',
      'title': 'Century Club',
      'description': 'Logged 100 outfits',
      'category': 'Consistency',
      'icon': 'military_tech',
      'isUnlocked': false,
      'unlockedDate': null,
      'rarity': 'Epic',
      'progress': 0.42,
      'requirement': 'Log 100 total outfits',
      'backstory':
          'Persistence creates transformation. You\'re building lasting habits!',
      'relatedChallenges': ['Dedication Master', 'Long Hauler'],
    },
    {
      'id': '7',
      'title': 'Wardrobe Optimizer',
      'description': 'Wore every item at least once',
      'category': 'Style',
      'icon': 'check_circle',
      'isUnlocked': false,
      'unlockedDate': null,
      'rarity': 'Rare',
      'progress': 0.78,
      'requirement': 'Wear all wardrobe items',
      'backstory':
          'Every piece deserves its moment. You\'re maximizing your wardrobe\'s potential!',
      'relatedChallenges': ['Full Utilization', 'No Item Left Behind'],
    },
    {
      'id': '8',
      'title': 'Monthly Milestone',
      'description': 'Completed your first month',
      'category': 'Consistency',
      'icon': 'calendar_month',
      'isUnlocked': true,
      'unlockedDate': DateTime(2026, 1, 5),
      'rarity': 'Uncommon',
      'progress': 1.0,
      'requirement': 'Use app for 30 days',
      'backstory':
          'A month of mindfulness is a powerful achievement. You\'re building lasting change!',
      'relatedChallenges': ['Time Traveler', 'Commitment Champion'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAchievements {
    return _achievements.where((achievement) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          achievement['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          achievement['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          achievement['description'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _unlockedCount =>
      _achievements.where((a) => a['isUnlocked'] == true).length;

  double get _completionPercentage =>
      (_unlockedCount / _achievements.length) * 100;

  String get _rarestBadge {
    final unlocked = _achievements.where((a) => a['isUnlocked'] == true);
    if (unlocked.isEmpty) return 'None yet';

    final rarityOrder = {'Epic': 4, 'Rare': 3, 'Uncommon': 2, 'Common': 1};
    final rarest = unlocked.reduce((a, b) {
      final aRarity = rarityOrder[a['rarity']] ?? 0;
      final bRarity = rarityOrder[b['rarity']] ?? 0;
      return aRarity > bRarity ? a : b;
    });
    return rarest['title'];
  }

  void _showAchievementDetail(Map<String, dynamic> achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AchievementDetailModalWidget(
        achievement: achievement,
        onShare: () => _shareAchievement(achievement),
      ),
    );
  }

  void _shareAchievement(Map<String, dynamic> achievement) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${achievement['title']}" achievement...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Achievement Gallery',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(theme),
            tooltip: 'Search achievements',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshAchievements,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AchievementStatsWidget(
                    totalAchievements: _achievements.length,
                    unlockedCount: _unlockedCount,
                    completionPercentage: _completionPercentage,
                    rarestBadge: _rarestBadge,
                  ),
                  SizedBox(height: 2.h),
                  _buildCategoryFilter(theme),
                  SizedBox(height: 2.h),
                  _buildAchievementGrid(theme),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
          if (_showCelebration)
            CelebrationOverlayWidget(
              controller: _celebrationController,
              onComplete: () => setState(() => _showCelebration = false),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return Container(
      height: 5.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementGrid(ThemeData theme) {
    final filtered = _filteredAchievements;

    if (filtered.isEmpty) {
      return Container(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No achievements found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your filters or search',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 0.85,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final achievement = filtered[index];
          return AchievementBadgeCardWidget(
            achievement: achievement,
            onTap: () => _showAchievementDetail(achievement),
          );
        },
      ),
    );
  }

  void _showSearchDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Achievements'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter achievement name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAchievements() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }
}
