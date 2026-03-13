import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/featured_challenge_banner_widget.dart';
import './widgets/challenge_category_card_widget.dart';
import './widgets/challenge_filter_chip_widget.dart';

/// Challenge Center - Browse and accept personal challenges
class ChallengeCenter extends StatefulWidget {
  const ChallengeCenter({Key? key}) : super(key: key);

  @override
  State<ChallengeCenter> createState() => _ChallengeCenterState();
}

class _ChallengeCenterState extends State<ChallengeCenter> {
  String _selectedFilter = 'all';
  final String _selectedDifficulty = 'all';

  final Map<String, dynamic> _featuredChallenge = {
    'id': 'featured-1',
    'title': 'Sustainability Week',
    'description': 'Focus on sustainable fashion choices for 7 days.',
    'imageUrl': 'https://images.unsplash.com/photo-1680731097148-be4d24e56752',
    'semanticLabel':
        'Green leaves and sustainable fashion items arranged on wooden surface',
    'duration': '7 days',
    'points': 500,
    'difficulty': 'medium',
  };

  final List<Map<String, dynamic>> _allChallenges = [
    {
      'id': '1',
      'title': 'Daily Outfit Logger',
      'description': 'Log your outfit every day for a week',
      'type': 'daily',
      'difficulty': 'easy',
      'duration': '7 days',
      'points': 50,
      'icon': 'today',
      'estimatedTime': '2 min/day',
      'isActive': true,
      'progress': 0.71,
    },
    {
      'id': '2',
      'title': 'Wardrobe Explorer',
      'description': 'Try 3 new outfit combinations',
      'type': 'weekly',
      'difficulty': 'medium',
      'duration': '1 week',
      'points': 100,
      'icon': 'explore',
      'estimatedTime': '30 min',
      'isActive': false,
      'progress': 0.0,
    },
  ];

  List<Map<String, dynamic>> get _filteredChallenges {
    return _allChallenges.where((challenge) {
      final matchesType =
          _selectedFilter == 'all' || challenge['type'] == _selectedFilter;
      final matchesDifficulty =
          _selectedDifficulty == 'all' ||
              challenge['difficulty'] == _selectedDifficulty;
      return matchesType && matchesDifficulty;
    }).toList();
  }

  int get _activeCount =>
      _allChallenges.where((challenge) => challenge['isActive'] == true).length;

  Map<String, dynamic>? get _closestChallenge {
    final activeChallenges = _allChallenges
        .where((challenge) => challenge['isActive'] == true)
        .toList();

    if (activeChallenges.isEmpty) return null;

    activeChallenges.sort(
      (a, b) => (b['progress'] as double).compareTo(a['progress'] as double),
    );

    return activeChallenges.first;
  }

  void _acceptChallenge(String challengeId) {
    setState(() {
      final challenge = _allChallenges.firstWhere(
        (c) => c['id'] == challengeId,
      );
      challenge['isActive'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Challenge accepted! Good luck!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Challenge Center',
        variant: CustomAppBarVariant.detail,
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
              _buildHeroCard(theme),
              SizedBox(height: 2.h),

              FeaturedChallengeBannerWidget(
                title: _featuredChallenge['title'],
                description: _featuredChallenge['description'],
                imageUrl: _featuredChallenge['imageUrl'],
                semanticLabel: _featuredChallenge['semanticLabel'],
                duration: _featuredChallenge['duration'],
                points: _featuredChallenge['points'],
                difficulty: _featuredChallenge['difficulty'],
                onTap: () {},
              ),
              SizedBox(height: 2.5.h),

              _buildSectionHeader(
                context,
                title: 'Browse by type',
              ),
              SizedBox(height: 1.h),
              _buildFilterSection(theme),
              SizedBox(height: 2.5.h),

              _buildSectionHeader(
                context,
                title: 'Available Challenges',
                actionLabel: _activeCount > 0 ? '$_activeCount active' : null,
              ),
              SizedBox(height: 1.h),
              _buildChallengeList(theme),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final closest = _closestChallenge;

    String title = 'Build better style habits';
    String subtitle =
        'Take on focused challenges to improve consistency, creativity, and mindful wardrobe use.';
    String chip = _activeCount > 0 ? '$_activeCount active' : 'New goals';

    if (closest != null) {
      final progress = ((closest['progress'] as double) * 100).round();
      title = 'Your next milestone is in progress';
      subtitle =
          '${closest['title']} is $progress% complete. Keep going and turn today’s effort into long-term progress.';
      chip = 'Keep going';
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
              Icons.flag_outlined,
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
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
          if (actionLabel != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 2.8.w,
                vertical: 0.5.h,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChallengeFilterChipWidget(
              label: 'All',
              isSelected: _selectedFilter == 'all',
              onTap: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: 'Daily',
              isSelected: _selectedFilter == 'daily',
              onTap: () {
                setState(() {
                  _selectedFilter = 'daily';
                });
              },
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: 'Weekly',
              isSelected: _selectedFilter == 'weekly',
              onTap: () {
                setState(() {
                  _selectedFilter = 'weekly';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeList(ThemeData theme) {
    final challenges = _filteredChallenges;

    if (challenges.isEmpty) {
      return _buildEmptyInfoCard(
        theme,
        icon: Icons.flag_outlined,
        title: 'No challenges found',
        subtitle:
            'Try changing your current filter to explore more challenge options.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return ChallengeCategoryCardWidget(
          title: challenge['title'],
          description: challenge['description'],
          type: challenge['type'],
          difficulty: challenge['difficulty'],
          duration: challenge['duration'],
          points: challenge['points'],
          icon: challenge['icon'],
          estimatedTime: challenge['estimatedTime'],
          isActive: challenge['isActive'],
          progress: challenge['progress'],
          onTap: () {},
          onAccept: () => _acceptChallenge(challenge['id']),
        );
      },
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
