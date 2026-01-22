import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
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
  String _selectedDifficulty = 'all';

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
      appBar: CustomAppBar(title: 'Challenge Center'),
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
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Type',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    SingleChildScrollView(
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
                          ChallengeFilterChipWidget(
                            label: 'Daily',
                            isSelected: _selectedFilter == 'daily',
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'daily';
                              });
                            },
                          ),
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
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Available Challenges',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _filteredChallenges.length,
                itemBuilder: (context, index) {
                  final challenge = _filteredChallenges[index];
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