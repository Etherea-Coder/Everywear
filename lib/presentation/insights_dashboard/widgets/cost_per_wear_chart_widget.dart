import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class CostPerWearChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topItems;

  const CostPerWearChartWidget({Key? key, required this.topItems})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      height: 32.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 Most Worn Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: topItems.isEmpty
                ? Center(
                    child: Text(
                      'Not enough data yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : BarChart(_buildBarChartData(theme)),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(ThemeData theme) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 10,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = topItems[group.x.toInt()];
            return BarTooltipItem(
              '${item['name']}\n',
              TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
              children: [
                TextSpan(
                  text: '${rod.toY.toInt()} wears\n',
                  style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                ),
                TextSpan(
                  text: 'CPW: \$${item['cpw'].toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < topItems.length) {
                final item = topItems[value.toInt()];
                return Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          );
        },
      ),
      barGroups: _buildBarGroups(),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return topItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item['wears'].toDouble(),
            color: AppTheme.primaryLight,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }
}
