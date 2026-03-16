import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/streak_hero_widget.dart';
import './widgets/active_challenge_card_widget.dart';
import './widgets/achievement_badge_display_widget.dart';
import './widgets/personal_stats_widget.dart';

/// Personal Progress Dashboard - Central hub for individual achievement tracking
/// Displays current streak, active challenges, earned badges, and lifetime statistics
/// Focuses on personal growth without social comparison
class PersonalProgressDashboard extends StatefulWidget {
  const PersonalProgressDashboard({Key? key}) : super(key: key);

  @override
  State<PersonalProgressDashboard> createState() =>
      _PersonalProgressDashboardState();
}

class _PersonalProgressDashboardState extends State<PersonalProgressDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;

  final Map<String, dynamic> _progressData = {
    'currentStreak': 7,
    'longestStreak': 15,
    'weeklyProgress': 0.71,
    'motivationalMessage': 'You\'re building strong style habits.',
    'totalPoints': 1250,
  };

  final List<Map<String, dynamic>> _activeChallenges = [
    {
      'id': '1',
      'title': 'Daily Outfit Logger',
      'description': 'Log your outfit for 7 consecutive days',
      'type': 'daily',
      'progress': 0.71,
      'currentValue': 5,
      'targetValue': 7,
      'points': 50,
      'icon': 'today',
      'dueDate': DateTime.now().add(const Duration(days: 2)),
    },
    {
      'id': '2',
      'title': 'Rate Your Outfits',
      'description': 'Rate at least 5 outfits this week',
      'type': 'weekly',
      'progress': 0.6,
      'currentValue': 3,
      'targetValue': 5,
      'points': 75,
      'icon': 'star',
      'dueDate': DateTime.now().add(const Duration(days: 4)),
    },
  ];

  final List<Map<String, dynamic>> _earnedAchievements = [
    {
      'id': '1',
      'title': 'First Steps',
      'icon': 'emoji_events',
      'unlockedDate': DateTime.now().subtract(const Duration(days: 30)),
      'rarity': 'common',
    },
    {
      'id': '2',
      'title': 'Week Warrior',
      'icon': 'local_fire_department',
      'unlockedDate': DateTime.now().subtract(const Duration(days: 1)),
      'rarity': 'rare',
    },
  ];

  final Map<String, dynamic> _personalStats = {
    'totalOutfitsLogged': 142,
    'moneySaved': 385.50,
    'sustainabilityScore': 78,
    'itemsAdded': 42,
    'avgCostPerWear': 12.30,
    'wardrobeUtilization': 65,
  };

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _navigateToChallengeCenter() {
    Navigator.pushNamed(context, AppRoutes.challengeCenter);
  }

  Map<String, dynamic>? get _closestChallenge {
    if (_activeChallenges.isEmpty) return null;

    final sorted = [..._activeChallenges]
      ..sort(
        (a, b) => (b['progress'] as double).compareTo(a['progress'] as double),
      );

    return sorted.first;
  }

  String get _nextMilestoneText {
    final closest = _closestChallenge;
    if (closest == null) return 'Keep going — your progress is taking shape.';

    final pct = ((closest['progress'] as double) * 100).round();
    return '${closest['title']} is $pct% complete.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'My Progress',
        variant: CustomAppBarVariant.detail,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: _navigateToChallengeCenter,
            tooltip: 'Challenge Center',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            setState(() {});
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSummaryCard(theme),
              SizedBox(height: 2.h),

              StreakHeroWidget(
                currentStreak: _progressData['currentStreak'],
                longestStreak: _progressData['longestStreak'],
                weeklyProgress: _progressData['weeklyProgress'],
                motivationalMessage: _progressData['motivationalMessage'],
                totalPoints: _progressData['totalPoints'],
              ),
              SizedBox(height: 2.5.h),

              _buildSectionHeader(
                context,
                title: 'Active Challenges',
                actionLabel: 'View All',
                onTap: _navigateToChallengeCenter,
              ),
              SizedBox(height: 1.h),
              _buildChallengesSection(theme),
              SizedBox(height: 3.h),

              _buildSectionHeader(
                context,
                title: 'Recent Achievements',
              ),
              SizedBox(height: 1.h),
              _buildAchievementsSection(theme),
              SizedBox(height: 3.h),

              _buildSectionHeader(
                context,
                title: 'Your Statistics',
              ),
              SizedBox(height: 1.h),
              PersonalStatsWidget(
                totalOutfitsLogged: _personalStats['totalOutfitsLogged'],
                moneySaved: _personalStats['moneySaved'],
                sustainabilityScore: _personalStats['sustainabilityScore'],
                itemsAdded: _personalStats['itemsAdded'],
                avgCostPerWear: _personalStats['avgCostPerWear'],
                wardrobeUtilization: _personalStats['wardrobeUtilization'],
              ),
              SizedBox(height: 3.h),

              _buildAchievementGalleryCard(theme),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSummaryCard(ThemeData theme) {
    final currentStreak = _progressData['currentStreak'] as int;
    final totalPoints = _progressData['totalPoints'] as int;
    final unlockedCount = _earnedAchievements.length;

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
              Icons.trending_up,
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
                    '$currentStreak day streak',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Your progress is building momentum',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  'You have unlocked $unlockedCount achievements and earned $totalPoints points so far. $_nextMilestoneText',
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(ThemeData theme) {
    if (_activeChallenges.isEmpty) {
      return _buildEmptyInfoCard(
        theme,
        icon: Icons.flag_outlined,
        title: 'No active challenges right now',
        subtitle:
            'Check the Challenge Center to join a new goal and keep your momentum going.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _activeChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _activeChallenges[index];
        return ActiveChallengeCardWidget(
          title: challenge['title'],
          description: challenge['description'],
          type: challenge['type'],
          progress: challenge['progress'],
          currentValue: challenge['currentValue'],
          targetValue: challenge['targetValue'],
          points: challenge['points'],
          icon: challenge['icon'],
          dueDate: challenge['dueDate'],
          onTap: () {},
        );
      },
    );
  }

  Widget _buildAchievementsSection(ThemeData theme) {
    if (_earnedAchievements.isEmpty) {
      return _buildEmptyInfoCard(
        theme,
        icon: Icons.emoji_events_outlined,
        title: 'No achievements unlocked yet',
        subtitle:
            'Keep logging outfits, completing challenges, and building habits to unlock your first milestone.',
      );
    }

    return SizedBox(
      height: 14.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _earnedAchievements.length,
        itemBuilder: (context, index) {
          final achievement = _earnedAchievements[index];
          return Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: AchievementBadgeDisplayWidget(
              title: achievement['title'],
              icon: achievement['icon'],
              rarity: achievement['rarity'],
              unlockedDate: achievement['unlockedDate'],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementGalleryCard(ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.achievementGallery),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.secondary,
              theme.colorScheme.secondary.withValues(alpha: 0.82),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSecondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: theme.colorScheme.onSecondary,
                size: 28,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Gallery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    'See every badge, milestone, and unlocked moment in your style journey.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInfoCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          SizedBox(height: 1.5.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.6.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
