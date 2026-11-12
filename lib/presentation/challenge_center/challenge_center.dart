import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:everywear/core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';

import '../../services/challenge_service.dart';
import '../../services/challenge_data.dart';
import './widgets/featured_challenge_banner_widget.dart';
import './widgets/challenge_category_card_widget.dart';
import './widgets/challenge_filter_chip_widget.dart';

class ChallengeCenter extends StatefulWidget {
  const ChallengeCenter({super.key});

  @override
  State<ChallengeCenter> createState() => _ChallengeCenterState();
}

class _ChallengeCenterState extends State<ChallengeCenter> {
  final ChallengeService _challengeService = ChallengeService();

  String _selectedFilter = 'all';
  bool _isLoading = true;
  bool _loadFailed = false;
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final history = await _challengeService.fetchUserChallengeHistory();
      final current = await _challengeService.fetchCurrentChallenge();
      if (!mounted) return;
      setState(() {
        _challenges = mergeChallengeData(current: current, history: history);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
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
        ((b['progress'] as num?) ?? 0).compareTo(
          (a['progress'] as num?) ?? 0,
        ));
    return joined.first;
  }

  Future<void> _acceptChallenge(String challengeId) async {
    final error = await _challengeService.joinChallenge(challengeId);
    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).challengeAcceptedMsg)),
      );
      _loadChallenges();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorLabel(error ?? ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).challengeCenterTitle,
        variant: CustomAppBarVariant.detail,
      ),
      body: RefreshIndicator(
        onRefresh: _loadChallenges,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
                ? _buildLoadError(theme)
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
                        imageUrl: _featuredChallenge!['image_url'] as String? ?? '',
                        semanticLabel: AppLocalizations.of(context).featuredChallengeBannerSemantic,
                        duration: AppLocalizations.of(context).daysLabel(_featuredChallenge!['duration_days'] as int? ?? 0),
                        points: _featuredChallenge!['points'] ?? 100,
                        difficulty: _featuredChallenge!['difficulty'] ?? 'medium',
                        onTap: _featuredChallenge!['is_joined'] == true
                            ? () {}
                            : () => _acceptChallenge(_featuredChallenge!['id']),
                      ),
                    SizedBox(height: 2.5.h),
                    _buildSectionHeader(context, title: AppLocalizations.of(context).browseByType),
                    SizedBox(height: 1.h),
                    _buildFilterSection(theme),
                    SizedBox(height: 2.5.h),
                    _buildSectionHeader(
                      context,
                      title: AppLocalizations.of(context).availableChallenges,
                      actionLabel:
                          _activeCount > 0 ? AppLocalizations.of(context).activeChallengesCount(_activeCount) : null,
                    ),
                    SizedBox(height: 1.h),
                    _buildChallengeList(theme),
                    SizedBox(height: 15.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadError(ThemeData theme) {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 2.h),
                Text(
                  localizations.failedToLoadChallenges,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: 1.5.h),
                FilledButton.icon(
                  onPressed: _loadChallenges,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final closest = _closestChallenge;
    String title = AppLocalizations.of(context).buildBetterStyleHabits;
    String subtitle = AppLocalizations.of(context).challengeCenterDesc;
    String chip = _activeCount > 0 ? AppLocalizations.of(context).activeChallengesCount(_activeCount) : AppLocalizations.of(context).newGoalsLabel;

    if (closest != null) {
      final progress = closest['progress'] as int? ?? 0;
      final duration = closest['duration_days'] as int? ?? 1;
      final pct = ((progress / duration) * 100).round();
      title = AppLocalizations.of(context).nextMilestoneInProgress;
      subtitle = AppLocalizations.of(context).challengeProgressMsg(closest['title'] ?? '', pct);
      chip = AppLocalizations.of(context).keepGoingLabel;
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
              label: AppLocalizations.of(context).getLocalizedChallengeFilter('all'),
              isSelected: _selectedFilter == 'all',
              onTap: () => setState(() => _selectedFilter = 'all'),
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: AppLocalizations.of(context).getLocalizedChallengeFilter('daily'),
              isSelected: _selectedFilter == 'daily',
              onTap: () => setState(() => _selectedFilter = 'daily'),
            ),
            SizedBox(width: 2.w),
            ChallengeFilterChipWidget(
              label: AppLocalizations.of(context).getLocalizedChallengeFilter('weekly'),
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
            Text(AppLocalizations.of(context).noChallengesFound,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            SizedBox(height: 0.6.h),
            Text(
                AppLocalizations.of(context).changeFilterExploreMore,
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
          duration: AppLocalizations.of(context).daysLabel(challenge['duration_days'] as int? ?? 0),
          points: challenge['points'] ?? 100,
          icon: challenge['icon'] ?? 'flag',
          estimatedTime: challenge['estimated_time'] ?? '30 min',
          isActive: challenge['is_joined'] == true,
          progress: duration > 0 ? progress / duration : 0.0,
          onTap: challenge['is_joined'] == true
              ? () {}
              : () => _acceptChallenge(challenge['id']),
          onAccept: () => _acceptChallenge(challenge['id']),
        );
      },
    );
  }
}
