import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/achievement_service.dart';
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
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Consistency',
    'Style',
    'Mindful',
    'Sustainability',
  ];



  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final data = await AchievementService.instance.fetchAchievements();
    if (mounted) setState(() { _achievements = data; _isLoading = false; });
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
      _achievements.isEmpty ? 0 : (_unlockedCount / _achievements.length) * 100;

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

  Map<String, dynamic>? get _nextAchievement {
    final locked = _achievements
        .where((a) => a['isUnlocked'] != true)
        .toList()
      ..sort((a, b) =>
          (b['progress'] as double).compareTo(a['progress'] as double));

    if (locked.isEmpty) return null;
    return locked.first;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RefreshIndicator(
            onRefresh: _refreshAchievements,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(theme),
                  SizedBox(height: 2.h),

                  AchievementStatsWidget(
                    totalAchievements: _achievements.length,
                    unlockedCount: _unlockedCount,
                    completionPercentage: _completionPercentage,
                    rarestBadge: _rarestBadge,
                  ),
                  SizedBox(height: 2.h),

                  _buildSectionHeader('Browse by category', theme),
                  SizedBox(height: 1.h),
                  _buildCategoryFilter(theme),
                  SizedBox(height: 2.h),

                  if (_searchQuery.isNotEmpty)
                    _buildSearchState(theme),

                  _buildAchievementGrid(theme),
                  SizedBox(height: 3.h),
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

  Widget _buildHeroCard(ThemeData theme) {
    final nextAchievement = _nextAchievement;

    String title = 'Your style journey is taking shape';
    String subtitle =
        'Track the milestones that reflect your consistency, creativity, and mindful wardrobe habits.';
    String chip = '$_unlockedCount unlocked';

    if (nextAchievement != null) {
      final progress = ((nextAchievement['progress'] as double) * 100).round();
      title = 'You are close to your next milestone';
      subtitle =
          '${nextAchievement['title']} is $progress% complete. Keep going to unlock your next achievement.';
      chip = 'Next up';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Showing results for "$_searchQuery"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: Text(
                'Clear',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
              Icons.emoji_events_outlined,
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
              _searchQuery.isNotEmpty
                  ? 'Try a different search term or clear your current query.'
                  : 'Try adjusting your category filter to explore more milestones.',
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
    final controller = TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Achievements'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter achievement name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAchievements() async {
    await _loadAchievements();
  }
}
