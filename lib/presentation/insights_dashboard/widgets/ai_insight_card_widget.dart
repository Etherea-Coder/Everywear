import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class AIInsightCardWidget extends StatelessWidget {
  final String type;
  final String title;
  final String description;
  final IconData icon;

  const AIInsightCardWidget({
    Key? key,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getColors(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colors['border']!, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: colors['iconBg'],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: colors['icon'], size: 24),
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
                    color: colors['text'],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    switch (type) {
      // Positive = AI-observed improvement → pink tint (intelligence)
      case 'positive':
        return {
          'background': secondary.withValues(alpha: 0.05),
          'border': secondary.withValues(alpha: 0.14),
          'iconBg': secondary.withValues(alpha: 0.10),
          'icon': secondary,
          'text': onSurface,
        };
      // Suggestion = AI recommendation → pink tint (intelligence)
      case 'suggestion':
        return {
          'background': secondary.withValues(alpha: 0.05),
          'border': secondary.withValues(alpha: 0.14),
          'iconBg': secondary.withValues(alpha: 0.10),
          'icon': secondary,
          'text': onSurface,
        };
      // Achievement = confirmed milestone → green tint (confirmation)
      case 'achievement':
        return {
          'background': primary.withValues(alpha: 0.06),
          'border': primary.withValues(alpha: 0.18),
          'iconBg': primary.withValues(alpha: 0.10),
          'icon': primary,
          'text': onSurface,
        };
      default:
        return {
          'background': theme.colorScheme.surface,
          'border': theme.dividerColor,
          'iconBg': theme.colorScheme.surfaceContainerHighest,
          'icon': theme.colorScheme.onSurfaceVariant,
          'text': onSurface,
        };
    }
  }
}
