import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class UsageChartWidget extends StatelessWidget {
  final int timeRange;

  const UsageChartWidget({Key? key, required this.timeRange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      height: 30.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Outfit Frequency',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 2.h),
          Expanded(child: LineChart(_buildLineChartData(theme))),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(ThemeData theme) {
    final spots = _getDataSpots();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final labels = _getBottomLabels();
              if (value.toInt() >= 0 && value.toInt() < labels.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    labels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: 5,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primaryLight,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryLight,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getDataSpots() {
    switch (timeRange) {
      case 0: // Week
        return [
          const FlSpot(0, 2),
          const FlSpot(1, 3),
          const FlSpot(2, 1),
          const FlSpot(3, 4),
          const FlSpot(4, 2),
          const FlSpot(5, 3),
          const FlSpot(6, 2),
        ];
      case 1: // Month
        return [
          const FlSpot(0, 2.5),
          const FlSpot(1, 3.2),
          const FlSpot(2, 2.8),
          const FlSpot(3, 4.1),
        ];
      case 2: // Year
        return [
          const FlSpot(0, 2.2),
          const FlSpot(1, 2.8),
          const FlSpot(2, 3.5),
          const FlSpot(3, 3.1),
        ];
      default:
        return [];
    }
  }

  List<String> _getBottomLabels() {
    switch (timeRange) {
      case 0: // Week
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 1: // Month
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      case 2: // Year
        return ['Q1', 'Q2', 'Q3', 'Q4'];
      default:
        return [];
    }
  }
}
