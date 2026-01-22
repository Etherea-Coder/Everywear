import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
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
  bool _showCelebration = false;

  // Mock data - Current streak and progress
  final Map<String, dynamic> _progressData = {
    'currentStreak': 7,
    'longestStreak': 15,
    'weeklyProgress': 0.71,
    'motivationalMessage': 'You\'re building great habits!',
    'totalPoints': 1250,
  };

  // Mock data - Active challenges
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

  // Mock data - Earned achievements
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

  // Mock data - Personal statistics
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'My Progress',
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
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {});
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreakHeroWidget(
                currentStreak: _progressData['currentStreak'],
                longestStreak: _progressData['longestStreak'],
                weeklyProgress: _progressData['weeklyProgress'],
                motivationalMessage: _progressData['motivationalMessage'],
                totalPoints: _progressData['totalPoints'],
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Challenges',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToChallengeCenter,
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              ListView.builder(
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
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Recent Achievements',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              SizedBox(
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
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Your Statistics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.dailyLog);
              break;
            case 1:
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.wardrobeManagement,
              );
              break;
            case 2:
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.smartSuggestions,
              );
              break;
            case 3:
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.insightsDashboard,
              );
              break;
            case 4:
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.purchaseTracking,
              );
              break;
          }
        },
      ),
    );
  }
}