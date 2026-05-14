import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Achievement detail modal showing comprehensive achievement information
class AchievementDetailModalWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback onShare;

  const AchievementDetailModalWidget({
    Key? key,
    required this.achievement,
    required this.onShare,
  }) : super(key: key);

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Epic':
        return const Color(0xFF9C27B0);
      case 'Rare':
        return const Color(0xFF2196F3);
      case 'Uncommon':
        return const Color(0xFF4CAF50);
      case 'Common':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement['isUnlocked'] as bool;
    final rarity = achievement['rarity'] as String;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: _getRarityColor(rarity).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: achievement['icon'],
                      size: 40,
                      color: _getRarityColor(rarity),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).getAchievementTitle(achievement['id']),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getRarityColor(rarity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context).getLocalizedRarity(rarity),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Description
              Text(
                AppLocalizations.of(context).getAchievementDescription(achievement['id']),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 2.h),

              // Unlock status
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUnlocked ? Icons.check_circle : Icons.lock,
                      color: isUnlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUnlocked ? AppLocalizations.of(context).unlocked : AppLocalizations.of(context).locked,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isUnlocked && achievement['unlockedDate'] != null)
                            Text(
                              DateFormat(
                                'MMMM d, yyyy',
                                Localizations.localeOf(context).toString(),
                              ).format(achievement['unlockedDate']),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          if (!isUnlocked)
                            Text(
                              AppLocalizations.of(context).percentComplete((achievement['progress'] * 100).toInt()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),

              // Requirement
              _buildSection(
                theme,
                AppLocalizations.of(context).unlockRequirement,
                AppLocalizations.of(context).getAchievementRequirement(achievement['id']),
                Icons.flag,
              ),
              SizedBox(height: 2.h),

              // Backstory
              _buildSection(
                theme,
                AppLocalizations.of(context).backstory,
                AppLocalizations.of(context).getAchievementBackstory(achievement['id']),
                Icons.auto_stories,
              ),
              SizedBox(height: 2.h),

              // Related challenges
              Text(
                AppLocalizations.of(context).relatedChallenges,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: (achievement['relatedChallenges'] as List<String>)
                    .map(
                      (challenge) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).getLocalizedChallenge(challenge),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 3.h),

              // Action buttons
              if (isUnlocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: Text(AppLocalizations.of(context).shareAchievement),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
