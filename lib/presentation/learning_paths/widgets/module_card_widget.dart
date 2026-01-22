import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Module card widget displaying learning module information
class ModuleCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final String difficulty;
  final String estimatedTime;
  final bool isUnlocked;
  final bool isCompleted;
  final double progress;
  final String unlockRequirement;
  final int requiredOutfits;
  final int currentOutfits;
  final List<String> keyLearnings;
  final String imageUrl;
  final String semanticLabel;
  final VoidCallback onTap;

  const ModuleCardWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    required this.isUnlocked,
    required this.isCompleted,
    required this.progress,
    required this.unlockRequirement,
    required this.requiredOutfits,
    required this.currentOutfits,
    required this.keyLearnings,
    required this.imageUrl,
    required this.semanticLabel,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CustomImageWidget(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    semanticLabel: semanticLabel,
                  ),
                ),
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'lock',
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Locked',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isCompleted)
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: CustomIconWidget(
                        iconName: 'check',
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                Positioned(
                  top: 2.w,
                  left: 2.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        difficulty,
                        theme,
                      ).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      difficulty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        estimatedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.5.h),
                  if (isUnlocked && !isCompleted && progress > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'In Progress',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 0.6.h,
                          percent: progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          progressColor: theme.colorScheme.primary,
                          barRadius: const Radius.circular(10),
                        ),
                        SizedBox(height: 1.5.h),
                      ],
                    ),
                  if (!isUnlocked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'lock_outline',
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                unlockRequirement,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (requiredOutfits > 0 &&
                            currentOutfits < requiredOutfits) ...[
                          SizedBox(height: 1.h),
                          LinearPercentIndicator(
                            padding: EdgeInsets.zero,
                            lineHeight: 0.6.h,
                            percent: currentOutfits / requiredOutfits,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            progressColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                            barRadius: const Radius.circular(10),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '$currentOutfits / $requiredOutfits outfits logged',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                        SizedBox(height: 1.5.h),
                      ],
                    ),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: keyLearnings.take(3).map((learning) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          learning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.sp,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        side: BorderSide(
                          color: isUnlocked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isCompleted
                                ? 'Review Module'
                                : isUnlocked
                                ? progress > 0
                                      ? 'Continue'
                                      : 'Start Module'
                                : 'View Requirements',
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: isUnlocked
                                ? 'arrow_forward'
                                : 'info_outline',
                            size: 18,
                            color: isUnlocked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
