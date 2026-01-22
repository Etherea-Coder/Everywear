import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Challenge category card widget for browsing challenges
class ChallengeCategoryCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final String duration;
  final int points;
  final String icon;
  final String estimatedTime;
  final bool isActive;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onAccept;

  const ChallengeCategoryCardWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.duration,
    required this.points,
    required this.icon,
    required this.estimatedTime,
    required this.isActive,
    required this.progress,
    required this.onTap,
    required this.onAccept,
  }) : super(key: key);

  IconData _getIconData() {
    switch (icon) {
      case 'today':
        return Icons.today;
      case 'star':
        return Icons.star;
      case 'explore':
        return Icons.explore;
      case 'refresh':
        return Icons.refresh;
      case 'trending_down':
        return Icons.trending_down;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getDifficultyColor() {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case 'daily':
        return theme.colorScheme.primary;
      case 'weekly':
        return Colors.blue;
      case 'monthly':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = _getDifficultyColor();
    final typeColor = _getTypeColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: isActive
              ? Border.all(color: typeColor.withValues(alpha: 0.3), width: 1.5)
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(_getIconData(), size: 24, color: typeColor),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildDetailChip(
                  context,
                  Icons.schedule,
                  duration,
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: 2.w),
                _buildDetailChip(
                  context,
                  Icons.timer,
                  estimatedTime,
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    difficulty.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: difficultyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              SizedBox(height: 2.h),
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 0.8.h,
                percent: progress.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                progressColor: typeColor,
                barRadius: const Radius.circular(10.0),
                animation: true,
                animationDuration: 800,
              ),
              SizedBox(height: 1.h),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, size: 20, color: Colors.amber),
                    SizedBox(width: 1.w),
                    Text(
                      '$points points',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isActive)
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Accept'),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}
