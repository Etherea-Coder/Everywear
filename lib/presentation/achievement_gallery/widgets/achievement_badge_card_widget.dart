import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Achievement badge card displaying individual achievement with unlock status
class AchievementBadgeCardWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback onTap;

  const AchievementBadgeCardWidget({
    Key? key,
    required this.achievement,
    required this.onTap,
  }) : super(key: key);

  Color _getRarityColor(String rarity, ThemeData theme) {
    switch (rarity) {
      case 'Epic':
        return const Color(0xFF9C27B0); // Purple
      case 'Rare':
        return const Color(0xFF2196F3); // Blue
      case 'Uncommon':
        return const Color(0xFF4CAF50); // Green
      case 'Common':
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement['isUnlocked'] as bool;
    final progress = achievement['progress'] as double;
    final rarity = achievement['rarity'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? Border.all(
                  color: _getRarityColor(rarity, theme).withValues(alpha: 0.4),
                  width: 2,
                )
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge icon
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? _getRarityColor(
                              rarity,
                              theme,
                            ).withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: achievement['icon'],
                      size: 36,
                      color: isUnlocked
                          ? _getRarityColor(rarity, theme)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Title
                  Text(
                    achievement['title'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),

                  // Description
                  Text(
                    achievement['description'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 11.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),

                  // Progress bar for locked achievements
                  if (!isUnlocked)
                    Column(
                      children: [
                        LinearPercentIndicator(
                          lineHeight: 6,
                          percent: progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          progressColor: theme.colorScheme.primary,
                          barRadius: const Radius.circular(3),
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${(progress * 100).toInt()}% complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Unlock date for unlocked achievements
                  if (isUnlocked && achievement['unlockedDate'] != null)
                    Text(
                      'Unlocked ${DateFormat('MMM d, y').format(achievement['unlockedDate'])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Rarity badge
            Positioned(
              top: 2.w,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: _getRarityColor(rarity, theme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rarity,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Lock overlay for locked achievements
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      size: 32,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
