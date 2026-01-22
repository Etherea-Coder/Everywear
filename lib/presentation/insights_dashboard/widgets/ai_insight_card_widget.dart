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
    final colors = _getColors();

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

  Map<String, Color> _getColors() {
    switch (type) {
      case 'positive':
        return {
          'background': Colors.green.shade50,
          'border': Colors.green.shade200,
          'iconBg': Colors.green.shade100,
          'icon': Colors.green.shade700,
          'text': Colors.green.shade900,
        };
      case 'suggestion':
        return {
          'background': Colors.blue.shade50,
          'border': Colors.blue.shade200,
          'iconBg': Colors.blue.shade100,
          'icon': Colors.blue.shade700,
          'text': Colors.blue.shade900,
        };
      case 'achievement':
        return {
          'background': Colors.purple.shade50,
          'border': Colors.purple.shade200,
          'iconBg': Colors.purple.shade100,
          'icon': Colors.purple.shade700,
          'text': Colors.purple.shade900,
        };
      default:
        return {
          'background': Colors.grey.shade50,
          'border': Colors.grey.shade200,
          'iconBg': Colors.grey.shade100,
          'icon': Colors.grey.shade700,
          'text': Colors.grey.shade900,
        };
    }
  }
}
