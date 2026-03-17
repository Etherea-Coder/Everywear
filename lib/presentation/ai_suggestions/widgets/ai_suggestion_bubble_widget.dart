import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/utils/app_localizations.dart';

class AiSuggestionBubbleWidget extends StatelessWidget {
  final String suggestions;
  final VoidCallback onDismiss;

  const AiSuggestionBubbleWidget({
    Key? key,
    required this.suggestions,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.20),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: theme.colorScheme.secondary, size: 20),
                  SizedBox(width: 2.w),
                  Text(
                    localizations.aiStylingAssistant,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: theme.colorScheme.onSurfaceVariant, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDismiss,
                tooltip: localizations.dismiss,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            suggestions,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.secondary,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Text(
                  localizations.poweredByAi,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
