import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Interactive philosophy alignment quiz with sliding scale responses
class PhilosophyQuizWidget extends StatelessWidget {
  final Map<String, double> responses;
  final Function(String, double) onResponseChanged;

  const PhilosophyQuizWidget({
    Key? key,
    required this.responses,
    required this.onResponseChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'quiz',
                size: 24,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'How aligned are you?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildQuizItem(
            context,
            theme,
            'quality',
            'I prioritize quality over quantity',
            'Disagree',
            'Strongly Agree',
          ),
          SizedBox(height: 2.h),
          _buildQuizItem(
            context,
            theme,
            'sustainability',
            'Sustainability matters in my choices',
            'Not Important',
            'Very Important',
          ),
          SizedBox(height: 2.h),
          _buildQuizItem(
            context,
            theme,
            'mindfulness',
            'I want to be more mindful about fashion',
            'Not Really',
            'Absolutely',
          ),
          SizedBox(height: 2.h),
          _buildAlignmentFeedback(theme),
        ],
      ),
    );
  }

  Widget _buildQuizItem(
    BuildContext context,
    ThemeData theme,
    String key,
    String question,
    String leftLabel,
    String rightLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: responses[key] ?? 0.5,
                  onChanged: (value) => onResponseChanged(key, value),
                  min: 0.0,
                  max: 1.0,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              rightLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentFeedback(ThemeData theme) {
    final averageAlignment =
        responses.values.reduce((a, b) => a + b) / responses.length;
    final alignmentPercentage = (averageAlignment * 100).round();

    String feedbackMessage;
    Color feedbackColor;

    if (alignmentPercentage >= 70) {
      feedbackMessage = 'You\'re perfectly aligned with our philosophy!';
      feedbackColor = theme.colorScheme.primary;
    } else if (alignmentPercentage >= 40) {
      feedbackMessage = 'You\'re on the right path to mindful fashion!';
      feedbackColor = theme.colorScheme.secondary;
    } else {
      feedbackMessage = 'We\'ll help you discover mindful fashion!';
      feedbackColor = theme.colorScheme.tertiary;
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: feedbackColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            size: 20,
            color: feedbackColor,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              feedbackMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: feedbackColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
