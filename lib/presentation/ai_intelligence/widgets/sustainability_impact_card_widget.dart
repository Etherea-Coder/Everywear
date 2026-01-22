import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../theme/app_theme.dart';

class SustainabilityImpactCardWidget extends StatefulWidget {
  final Map<String, dynamic> metrics;

  const SustainabilityImpactCardWidget({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  State<SustainabilityImpactCardWidget> createState() =>
      _SustainabilityImpactCardWidgetState();
}

class _SustainabilityImpactCardWidgetState
    extends State<SustainabilityImpactCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          if (_isExpanded) ..._buildExpandedContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.eco_outlined,
                color: Colors.green,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sustainability Impact',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Environmental footprint tracking',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExpandedContent(ThemeData theme) {
    final avgCostPerWear = widget.metrics['avgCostPerWear'] as double;
    final costTrend = widget.metrics['costTrend'] as double;
    final purchaseFrequency = widget.metrics['purchaseFrequency'] as double;
    final carbonImpact = widget.metrics['carbonImpact'] as int;
    final carbonGoal = widget.metrics['carbonGoal'] as int;
    final goalProgress = widget.metrics['sustainabilityGoalProgress'] as int;

    return [
      Divider(height: 1, color: theme.dividerColor),
      Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Cost Per Wear',
                    '\$${avgCostPerWear.toStringAsFixed(2)}',
                    costTrend < 0 ? 'Decreasing' : 'Increasing',
                    costTrend < 0,
                    Icons.attach_money,
                    theme,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildMetricCard(
                    'Purchases/Month',
                    purchaseFrequency.toStringAsFixed(1),
                    'Average',
                    false,
                    Icons.shopping_bag_outlined,
                    theme,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              'Carbon Impact',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildCarbonProgress(carbonImpact, carbonGoal, theme),
            SizedBox(height: 3.h),
            Text(
              'Sustainability Goal Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildGoalProgress(goalProgress, theme),
          ],
        ),
      ),
    ];
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String trend,
    bool isPositive,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 20),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (trend.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarbonProgress(
    int current,
    int goal,
    ThemeData theme,
  ) {
    final percentage = (current / goal * 100).clamp(0, 100).toInt();
    final isOnTrack = current <= goal;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isOnTrack
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isOnTrack
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current kg CO₂',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOnTrack ? Colors.green : Colors.orange,
                ),
              ),
              Text(
                'Goal: $goal kg',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
            color: isOnTrack ? Colors.green : Colors.orange,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4.0),
          ),
          SizedBox(height: 1.h),
          Text(
            isOnTrack
                ? 'On track to meet your sustainability goal!'
                : 'Consider reducing new purchases',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOnTrack ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(int progress, ThemeData theme) {
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 40,
          lineWidth: 8.0,
          percent: progress / 100,
          center: Text(
            '$progress%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          progressColor: Colors.green,
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Great progress!',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'You\'re $progress% towards your monthly sustainability goal. Keep maximizing existing items!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}