import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../theme/app_theme.dart';

class SustainabilityScoreWidget extends StatelessWidget {
  final int score;
  final int wardrobeUtilization;

  const SustainabilityScoreWidget({
    Key? key,
    required this.score,
    required this.wardrobeUtilization,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCircle(
                'Sustainability\nScore',
                score,
                100,
                Colors.green,
                theme,
              ),
              _buildScoreCircle(
                'Wardrobe\nUtilization',
                wardrobeUtilization,
                100,
                AppTheme.primaryLight,
                theme,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildScoreBreakdown(theme),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(
    String label,
    int value,
    int maxValue,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 8.0,
          percent: value / maxValue,
          center: Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          _buildBreakdownItem(
            'Items worn regularly',
            '27/42',
            Icons.check_circle,
            Colors.green,
            theme,
          ),
          Divider(height: 2.h),
          _buildBreakdownItem(
            'Avg wears per item',
            '2.3x/month',
            Icons.repeat,
            AppTheme.primaryLight,
            theme,
          ),
          Divider(height: 2.h),
          _buildBreakdownItem(
            'Neglected items',
            '12 items',
            Icons.warning_amber,
            Colors.orange,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 3.w),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
