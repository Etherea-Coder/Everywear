import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/challenge_service.dart';
import './widgets/featured_challenge_banner_widget.dart';
import './widgets/challenge_category_card_widget.dart';
import './widgets/challenge_filter_chip_widget.dart';

class ChallengeCenter extends StatefulWidget {
  const ChallengeCenter({Key? key}) : super(key: key);

  @override
  State<ChallengeCenter> createState() => _ChallengeCenterState();
}

class _ChallengeCenterState extends State<ChallengeCenter> {
  final ChallengeService _challengeService = ChallengeService();

  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    final history = await _challengeService.fetchUserChallengeHistory();
    final current = await _challengeService.fetchCurrentChallenge();
    if (mounted) {
      setState(() {
        _challenges = [
          if (current != null) current,
          ...history
              .where((h) => h['challenge_id'] != current?['id'])
              .map((h) => {
                    ...Map<String, dynamic>.from(h['challenges'] as Map),
                    'is_joined': true,
                    'progress': h['progress'] ?? 0,
                  })
              .toList(),
        ];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredChallenges {
    if (_selectedFilter == 'all') return _challenges;
    return _challenges
        .where((c) => c['type'] == _selectedFilter)
        .toList();
  }

  Map<String, dynamic>? get _featuredChallenge {
    if (_challenges.isEmpty) return null;
    // Show first active challenge as featured
    return _challenges.firstWhere(
      (c) => c['is_active'] == true || c['is_joined'] == true,
      orElse: () => _challenges.first,
    );
  }

  int get _activeCount =>
      _challenges.where((c) => c['is_joined'] == true).length;

  Map<String, dynamic>? get _closestChallenge {
    final joined = _challenges
        .where((c) => c['is_joined'] == true)
        .toList();
    if (joined.isEmpty) return null;
    joined.sort((a, b) =>
        (b['progress'] as int).compareTo(a['progress'] as int));
    return joined.first;
  }

  Future<void> _acceptChallenge(String challengeId) async {
    final success = await _challengeService.joinChallenge(challengeId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Challenge accepted! Good luck!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _loadChallenges();
    }
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
        onRefresh: _loadChallenges,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(theme),
                    SizedBox(height: 2.h),
                    if (_featuredChallenge != null)
                      FeaturedChallengeBannerWidget(
                        title: _featuredChallenge!['title'] ?? '',
                        description: _featuredChallenge!['description'] ?? '',
                        imageUrl: 'assets/images/challenges/sustainability_week.jpg',
                        semanticLabel: 'Featured challenge banner',
                        duration: '${_featuredChallenge!['duration_days']} days',
                        points: _featuredChallenge!['points'] ?? 100,
                        difficulty: _featuredChallenge!['difficulty'] ?? 'medium',
                        onTap: () {},
                      ),
                    SizedBox(height: 2.5.h),
                    _buildSectionHeader(context, title: 'Browse by type'),
                    SizedBox(height: 1.h),
                    _buildFilterSection(theme),
                    SizedBox(height: 2.5.h),
                    _buildSectionHeader(
                      context,
                      title: 'Available Challenges',
                      actionLabel:
                          _activeCount > 0 ? '$_activeCount active' : null,
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
      final progress = closest['progress'] as int? ?? 0;
      final duration = closest['duration_days'] as int? ?? 1;
      final pct = ((progress / duration) * 100).round();
      title = 'Your next milestone is in progress';
      subtitle =
          '${closest['title']} is $pct% complete. Keep going!';
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
            child: const Icon(Icons.flag_outlined,
                color: Colors.white, size: 28),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.5.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(chip,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(height: 1.h),
                Text(title,
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 0.6.h),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, String? actionLabel}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (actionLabel != null)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 2.8.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(actionLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
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
              onTap: () => setState(() => _selectedFilter = 'all'),
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: 'Daily',
              isSelected: _selectedFilter == 'daily',
              onTap: () => setState(() => _selectedFilter = 'daily'),
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: 'Weekly',
              isSelected: _selectedFilter == 'weekly',
              onTap: () => setState(() => _selectedFilter = 'weekly'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeList(ThemeData theme) {
    final challenges = _filteredChallenges;

    if (challenges.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.flag_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7)),
            SizedBox(height: 1.5.h),
            Text('No challenges found',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            SizedBox(height: 0.6.h),
            Text(
                'Try changing your filter to explore more challenge options.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final progress = challenge['progress'] as int? ?? 0;
        final duration = challenge['duration_days'] as int? ?? 1;
        return ChallengeCategoryCardWidget(
          title: challenge['title'] ?? '',
          description: challenge['description'] ?? '',
          type: challenge['type'] ?? 'weekly',
          difficulty: challenge['difficulty'] ?? 'medium',
          duration: '${challenge['duration_days']} days',
          points: challenge['points'] ?? 100,
          icon: challenge['icon'] ?? 'flag',
          estimatedTime: challenge['estimated_time'] ?? '30 min',
          isActive: challenge['is_joined'] == true,
          progress: duration > 0 ? progress / duration : 0.0,
          onTap: () {},
          onAccept: () => _acceptChallenge(challenge['id']),
        );
      },
    );
  }
}