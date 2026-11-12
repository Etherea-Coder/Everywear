import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/learning_service.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/module_card_widget.dart';
import './widgets/progress_header_widget.dart';

class LearningPaths extends StatefulWidget {
  const LearningPaths({super.key, this.learningService});

  final LearningService? learningService;

  @override
  State<LearningPaths> createState() => _LearningPathsState();
}

class _LearningPathsState extends State<LearningPaths> {
  late final LearningService _learningService =
      widget.learningService ?? LearningService();

  bool _isLoading = true;
  bool _loadFailed = false;
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _achievements = [];
  Map<String, dynamic> _stats = {
    'outfits_logged': 0,
    'wardrobe_items': 0,
    'completed_modules': 0,
    'level': 1,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final results = await Future.wait([
        _learningService.fetchModulesWithProgress(),
        _learningService.getUserLearningStats(),
      ]);

      final modules = results[0] as List<Map<String, dynamic>>;
      final stats = results[1] as Map<String, dynamic>;
      final achievements = _learningService.deriveAchievements(stats);

      if (!mounted) return;
      setState(() {
        _modules = modules;
        _stats = stats;
        _achievements = achievements;
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

  String _getLocalizedRequirement(Map<String, dynamic> module) {
    final label = module['unlock_requirement_label'] as String? ?? '';
    final requiredOutfits = module['unlock_required_outfits'] as int? ?? 0;
    
    if (requiredOutfits > 0 && (label.contains('Log') || label.contains('outfits'))) {
      return AppLocalizations.of(context).logOutfitsToUnlock(requiredOutfits);
    }
    
    // Fallback or specific rules for wardrobe items
    if (label.contains('wardrobe items')) {
      final itemsNeeded = label.contains('20') ? 20 : label.contains('30') ? 30 : label.contains('50') ? 50 : 0;
      if (itemsNeeded > 0) {
        // We could add a translation for this too if needed
        return label; 
      }
    }
    
    return label;
  }

  int get _completedModules => _stats['completed_modules'] as int;
  int get _totalModules => _modules.length;
  int get _currentLevel => _stats['level'] as int;
  int get _outfitsLogged => _stats['outfits_logged'] as int;
  int get _wardrobeItems => _stats['wardrobe_items'] as int;

  double get _overallProgress =>
      _totalModules > 0 ? _completedModules / _totalModules : 0.0;

  /// Determine if a module is unlocked based on real user data
  bool _isModuleUnlocked(Map<String, dynamic> module) {
    final required = module['unlock_required_outfits'] as int? ?? 0;
    final orderIndex = module['order_index'] as int? ?? 1;

    // First 3 modules always unlocked
    if (orderIndex <= 3) return true;

    // Check outfit log requirement
    if (_outfitsLogged >= required) return true;

    // Module 5 requires wardrobe items
    if (orderIndex == 5 && _wardrobeItems >= 20) return true;
    if (orderIndex == 7 && _wardrobeItems >= 30) return true;
    if (orderIndex == 11 && _wardrobeItems >= 50) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: CustomAppBar(
          title: AppLocalizations.of(context).learningPathsTitle,
          variant: CustomAppBarVariant.detail,
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () => _showInfoDialog(context),
              tooltip: AppLocalizations.of(context).aboutLearningPathsTooltip,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildLoadError(theme),
                )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProgressHeaderWidget(
                      currentLevel: _currentLevel,
                      overallProgress: _overallProgress,
                      totalModulesCompleted: _completedModules,
                      totalModules: _totalModules,
                    ),
                  ),
                  if (_achievements.any((a) => a['is_unlocked'] == true))
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
                            child: Text(
                              AppLocalizations.of(context).recentAchievements,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            height: 18.h,
                            child: ListView.separated(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 4.w),
                              scrollDirection: Axis.horizontal,
                              itemCount: _achievements
                                  .where((a) =>
                                      a['is_unlocked'] == true)
                                  .length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: 3.w),
                              itemBuilder: (context, index) {
                                final unlocked = _achievements
                                    .where((a) =>
                                        a['is_unlocked'] == true)
                                    .toList();
                                final achievement = unlocked[index];
                                return AchievementBadgeWidget(
                                  title: AppLocalizations.of(context).getLpAchievementTitle(achievement['id']),
                                  description: AppLocalizations.of(context).getLpAchievementDescription(achievement['id']),
                                  icon: achievement['icon'],
                                  isUnlocked: achievement['is_unlocked'],
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).learningModules,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context).modulesCompletedLabel(_completedModules, _totalModules),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final module = _modules[index];
                          final isUnlocked =
                              _isModuleUnlocked(module);
                          return Padding(
                            padding: EdgeInsets.only(bottom: 2.h),
                            child: ModuleCardWidget(
                              title: module['title'] ?? '',
                              description:
                                  module['description'] ?? '',
                              difficulty:
                                  module['difficulty'] ?? 'Beginner',
                              estimatedTime:
                                  module['estimated_time'] ?? '20 min',
                              isUnlocked: isUnlocked,
                              isCompleted:
                                  module['is_completed'] == true,
                              progress: (module['progress'] as num?)
                                      ?.toDouble() ??
                                  0.0,
                              unlockRequirement:
                                  _getLocalizedRequirement(module),
                              requiredOutfits:
                                  module['unlock_required_outfits']
                                          as int? ??
                                      0,
                              currentOutfits: _outfitsLogged,
                              keyLearnings:
                                  (module['key_learnings'] as List?)
                                          ?.cast<String>() ??
                                      [],
                              imageUrl: module['image_url'] ?? '',
                              semanticLabel:
                                  module['semantic_label'] ?? '',
                              onTap: () =>
                                  _handleModuleTap(context, module,
                                      isUnlocked: isUnlocked),
                            ),
                          );
                        },
                        childCount: _modules.length,
                      ),
                    ),
                  ),
                ],
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
                  localizations.failedToLoadLearning,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: 1.5.h),
                FilledButton.icon(
                  onPressed: _loadData,
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

  void _handleModuleTap(
    BuildContext context,
    Map<String, dynamic> module, {
    required bool isUnlocked,
  }) {
    if (!isUnlocked) {
      _showUnlockRequirementDialog(context, module);
      return;
    }

    final theme = Theme.of(context);
    final isCompleted = module['is_completed'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((module['image_url'] ?? '').isNotEmpty)
                      CustomImageWidget(
                        imageUrl: module['image_url'] as String,
                        width: double.infinity,
                        height: 25.h,
                        fit: BoxFit.cover,
                        semanticLabel:
                            module['semantic_label'] as String? ?? '',
                      ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                                    module['difficulty'] as String? ??
                                        'Beginner',
                                    theme)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context).getLocalizedDifficulty(
                                    module['difficulty'] as String? ??
                                        'Beginner'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getDifficultyColor(
                                  module['difficulty'] as String? ??
                                      'Beginner',
                                  theme),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: 'schedule',
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          module['estimated_time'] as String? ?? '20 min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      module['title'] as String? ?? '',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      module['description'] as String? ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(AppLocalizations.of(context).keyLearningsTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 1.h),
                    ...((module['key_learnings'] as List?)
                                ?.cast<String>() ??
                            [])
                        .map(
                          (learning) => Padding(
                            padding: EdgeInsets.only(bottom: 1.h),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 0.5.h),
                                  child: CustomIconWidget(
                                    iconName: 'check_circle',
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(learning,
                                      style:
                                          theme.textTheme.bodyMedium),
                                ),
                              ],
                            ),
                          ),
                        ),
                    SizedBox(height: 3.h),
                    if (!isCompleted) ...[
                      Text(
                        AppLocalizations.of(context).moduleCompletionHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isCompleted) {
                            Navigator.pop(context);
                            return;
                          }

                          final saved = await _learningService
                              .updateModuleProgress(
                            module['id'] as String,
                            1.0,
                          );
                          if (!mounted) return;
                          if (!saved) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(this.context)
                                      .failedToSaveModuleProgress,
                                ),
                              ),
                            );
                            return;
                          }

                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(this.context)
                                    .moduleProgressSaved,
                              ),
                            ),
                          );
                          await _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(vertical: 1.8.h),
                        ),
                        child: Text(isCompleted
                            ? AppLocalizations.of(context).reviewModule
                            : AppLocalizations.of(context)
                                .markModuleComplete),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockRequirementDialog(
      BuildContext context, Map<String, dynamic> module) {
    final theme = Theme.of(context);
    final requiredOutfits =
        module['unlock_required_outfits'] as int? ?? 0;
    final remaining = (requiredOutfits - _outfitsLogged).clamp(0, requiredOutfits);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
                iconName: 'lock',
                size: 24,
                color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(AppLocalizations.of(context).moduleLockedTitle,
                  style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLocalizedRequirement(module),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            if (remaining > 0) ...[
              Text(
                AppLocalizations.of(context).progressOutfitsLabel(_outfitsLogged, requiredOutfits),
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: requiredOutfits > 0
                    ? _outfitsLogged / requiredOutfits
                    : 0,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary),
              ),
              SizedBox(height: 1.h),
              Text(
                AppLocalizations.of(context).moreOutfitsNeeded(remaining),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ] else
              Text(
                AppLocalizations.of(context).completeRequiredModules,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('got_it')),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).aboutLearningPathsTooltip,
            style: theme.textTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).aboutLpDescription,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(AppLocalizations.of(context).howItWorks,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 1.h),
              _buildInfoPoint(context,
                  AppLocalizations.of(context).aboutLpPoint1),
              _buildInfoPoint(context,
                  AppLocalizations.of(context).aboutLpPoint2),
              _buildInfoPoint(context,
                  AppLocalizations.of(context).aboutLpPoint3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 0.3.h),
            child: CustomIconWidget(
                iconName: 'check_circle',
                size: 18,
                color: theme.colorScheme.primary),
          ),
          SizedBox(width: 2.w),
          Expanded(
              child:
                  Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty, ThemeData theme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return theme.colorScheme.primary;
      case 'intermediate':
        return const Color(0xFFB8860B);
      case 'advanced':
        return const Color(0xFFA0522D);
      default:
        return theme.colorScheme.primary;
    }
  }
}
