import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import '../../services/progress_service.dart';
import './widgets/streak_hero_widget.dart';
import './widgets/active_challenge_card_widget.dart';

class PersonalProgressDashboard extends StatefulWidget {
  const PersonalProgressDashboard({Key? key}) : super(key: key);

  @override
  State<PersonalProgressDashboard> createState() =>
      _PersonalProgressDashboardState();
}

class _PersonalProgressDashboardState extends State<PersonalProgressDashboard> {
  final ProgressService _progressService = ProgressService();

  bool _isLoading = true;

  Map<String, int> _streakData = {'current': 0, 'longest': 0};
  List<Map<String, dynamic>> _activeChallenges = [];
  Map<String, dynamic> _stats = {
    'totalOutfitsLogged': 0,
    'totalItems': 0,
    'totalSpent': 0.0,
    'avgCostPerWear': 0.0,
    'wardrobeUtilization': 0,
    'purchasesThisMonth': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _progressService.fetchStreakData(),
      _progressService.fetchActiveChallenges(),
      _progressService.fetchPersonalStats(),
    ]);
    if (mounted) {
      setState(() {
        _streakData = results[0] as Map<String, int>;
        _activeChallenges = results[1] as List<Map<String, dynamic>>;
        _stats = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  void _navigateToChallengeCenter() {
    Navigator.pushNamed(context, AppRoutes.challengeCenter);
  }

  String get _heroSubtitle {
    final current = _streakData['current'] ?? 0;
    final outfits = _stats['totalOutfitsLogged'] as int? ?? 0;
    final challenges = _activeChallenges.length;

    if (current == 0 && outfits == 0) {
      return AppLocalizations.of(context).translate('progress_hero_start');
    }
    if (challenges > 0) {
      final best = _activeChallenges.reduce(
          (a, b) => (a['progress'] as double) >= (b['progress'] as double) ? a : b);
      final pct = ((best['progress'] as double) * 100).round();
      return '${best['title']} — $pct%';
    }
    return AppLocalizations.of(context).translate('progress_hero_default');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: loc.translate('my_progress'),
        variant: CustomAppBarVariant.detail,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _navigateToChallengeCenter,
            tooltip: loc.translate('challenge_center'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(theme, loc),
                    SizedBox(height: 2.h),

                    StreakHeroWidget(
                      currentStreak: _streakData['current'] ?? 0,
                      longestStreak: _streakData['longest'] ?? 0,
                      weeklyProgress: _weeklyProgress,
                      motivationalMessage: _motivationalMessage(loc),
                      totalPoints: 0, // no points table yet
                    ),
                    SizedBox(height: 2.5.h),

                    _buildSectionHeader(
                      context,
                      title: loc.translate('active_challenges'),
                      actionLabel: loc.translate('view_all'),
                      onTap: _navigateToChallengeCenter,
                    ),
                    SizedBox(height: 1.h),
                    _buildChallengesSection(theme, loc),
                    SizedBox(height: 3.h),

                    _buildSectionHeader(
                      context,
                      title: loc.translate('your_statistics'),
                    ),
                    SizedBox(height: 1.h),
                    _buildStatsSection(theme, loc),
                    SizedBox(height: 3.h),

                    _buildChallengeGalleryCard(theme, loc),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
    );
  }

  /// Weekly progress: ratio of days with outfits in last 7 days
  double get _weeklyProgress {
    // This is a lightweight estimate — for precision we'd need a date query
    // but StreakHeroWidget already shows the real streak
    final streak = _streakData['current'] ?? 0;
    return (streak.clamp(0, 7) / 7).clamp(0.0, 1.0);
  }

  String _motivationalMessage(AppLocalizations loc) {
    final streak = _streakData['current'] ?? 0;
    if (streak == 0) return loc.translate('motivation_start');
    if (streak < 3) return loc.translate('motivation_building');
    if (streak < 7) return loc.translate('motivation_going');
    return loc.translate('motivation_strong');
  }

  Widget _buildHeroCard(ThemeData theme, AppLocalizations loc) {
    final current = _streakData['current'] ?? 0;
    final outfits = _stats['totalOutfitsLogged'] as int? ?? 0;
    final activeChallengeCount = _activeChallenges.length;

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
            child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$current ${loc.translate('day_streak')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(height: 1.h),
                Text(
                  loc.translate('progress_hero_title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  outfits == 0
                      ? loc.translate('progress_hero_no_logs')
                      : '$outfits ${loc.translate('outfits_logged_so_far')} · '
                        '$activeChallengeCount ${loc.translate('challenges_active')}. '
                        '$_heroSubtitle',
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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (actionLabel != null && onTap != null)
            TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(ThemeData theme, AppLocalizations loc) {
    if (_activeChallenges.isEmpty) {
      return _buildEmptyCard(
        theme,
        icon: Icons.flag_outlined,
        title: loc.translate('no_active_challenges'),
        subtitle: loc.translate('no_active_challenges_hint'),
        actionLabel: loc.translate('browse_challenges'),
        onAction: _navigateToChallengeCenter,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _activeChallenges.length,
      itemBuilder: (context, index) {
        final c = _activeChallenges[index];
        return ActiveChallengeCardWidget(
          title: c['title'],
          description: c['description'],
          type: c['type'],
          progress: c['progress'],
          currentValue: c['currentValue'],
          targetValue: c['targetValue'],
          points: c['points'],
          icon: c['icon'],
          dueDate: c['dueDate'],
          onTap: () {},
        );
      },
    );
  }

  Widget _buildStatsSection(ThemeData theme, AppLocalizations loc) {
    final outfits = _stats['totalOutfitsLogged'] as int? ?? 0;
    final items = _stats['totalItems'] as int? ?? 0;
    final spent = (_stats['totalSpent'] as double?) ?? 0.0;
    final cpw = (_stats['avgCostPerWear'] as double?) ?? 0.0;
    final utilization = _stats['wardrobeUtilization'] as int? ?? 0;
    final purchases = _stats['purchasesThisMonth'] as int? ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatPill(theme,
                    icon: '👗',
                    label: loc.translate('outfits_logged'),
                    value: '$outfits'),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatPill(theme,
                    icon: '🧺',
                    label: loc.translate('wardrobe_items'),
                    value: '$items'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(theme,
                    icon: '💸',
                    label: loc.translate('total_spent'),
                    value: '€${spent.toStringAsFixed(0)}'),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatPill(theme,
                    icon: '📊',
                    label: loc.translate('cost_per_wear'),
                    value: cpw > 0 ? '€${cpw.toStringAsFixed(2)}' : '—'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(theme,
                    icon: '🔄',
                    label: loc.translate('wardrobe_utilization'),
                    value: '$utilization%'),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatPill(theme,
                    icon: '🛍',
                    label: loc.translate('purchases_this_month'),
                    value: '$purchases'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(ThemeData theme,
      {required String icon,
      required String label,
      required String value}) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          SizedBox(width: 2.5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeGalleryCard(ThemeData theme, AppLocalizations loc) {
    return GestureDetector(
      onTap: _navigateToChallengeCenter,
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
              child: Icon(Icons.flag, color: theme.colorScheme.onSecondary, size: 28),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('challenge_center'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    loc.translate('challenge_center_subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: theme.colorScheme.onSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          SizedBox(height: 1.5.h),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          SizedBox(height: 0.6.h),
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 2.h),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}