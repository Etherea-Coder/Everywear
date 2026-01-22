import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

/// Spending chart widget displaying monthly spending trends
class SpendingChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> purchases;

  const SpendingChartWidget({Key? key, required this.purchases})
    : super(key: key);

  Map<int, double> _getMonthlySpending() {
    final Map<int, double> monthlyData = {};

    for (var purchase in purchases) {
      final date = purchase['purchaseDate'] as DateTime;
      final month = date.month;
      monthlyData[month] = (monthlyData[month] ?? 0.0) + purchase['price'];
    }

    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlySpending = _getMonthlySpending();

    if (monthlySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      height: 28.h,
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
                'Monthly Spending',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last 6 Months',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: LineChart(_buildLineChartData(theme, monthlySpending)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(
    ThemeData theme,
    Map<int, double> monthlySpending,
  ) {
    final spots = _buildSpots(monthlySpending);
    final maxY = monthlySpending.values.isEmpty
        ? 100.0
        : monthlySpending.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
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
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '\$${value.toInt()}',
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
              final month = value.toInt();
              if (month < 1 || month > 12) return const SizedBox();
              final monthName = DateFormat('MMM').format(DateTime(2024, month));
              return Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 1,
      maxX: 12,
      minY: 0,
      maxY: maxY,
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

  List<FlSpot> _buildSpots(Map<int, double> monthlySpending) {
    final List<FlSpot> spots = [];

    for (var entry in monthlySpending.entries) {
      spots.add(FlSpot(entry.key.toDouble(), entry.value));
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }
}
