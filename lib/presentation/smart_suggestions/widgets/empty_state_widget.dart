import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state when insufficient data for suggestions
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onNavigateToLog;

  const EmptyStateWidget({Key? key, required this.onNavigateToLog})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'lightbulb_outline',
                color: theme.colorScheme.primary,
                size: 60,
              ),
            ),

            SizedBox(height: 3.h),

            Text(
              'Building your suggestions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            Text(
              'We need a bit more data to create personalized outfit suggestions for you.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h),

            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    theme,
                    'Log 3 outfits',
                    'Start tracking your daily outfits',
                    isCompleted: false,
                  ),
                  SizedBox(height: 2.h),
                  _buildTimelineItem(
                    theme,
                    'Rate your outfits',
                    'Tell us how you felt wearing them',
                    isCompleted: false,
                  ),
                  SizedBox(height: 2.h),
                  _buildTimelineItem(
                    theme,
                    'Get suggestions',
                    'We\'ll recommend outfits you\'ll love',
                    isCompleted: false,
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            ElevatedButton(
              onPressed: onNavigateToLog,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              ),
              child: const Text('Log Your First Outfit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    String title,
    String subtitle, {
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isCompleted
              ? CustomIconWidget(
                  iconName: 'check',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                )
              : null,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
