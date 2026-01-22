import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../presentation/insights_dashboard/widgets/metric_card_widget.dart';

/// Personal statistics widget displaying lifetime achievements
class PersonalStatsWidget extends StatelessWidget {
  final int totalOutfitsLogged;
  final double moneySaved;
  final int sustainabilityScore;
  final int itemsAdded;
  final double avgCostPerWear;
  final int wardrobeUtilization;

  const PersonalStatsWidget({
    Key? key,
    required this.totalOutfitsLogged,
    required this.moneySaved,
    required this.sustainabilityScore,
    required this.itemsAdded,
    required this.avgCostPerWear,
    required this.wardrobeUtilization,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: 'Outfits Logged',
                  value: totalOutfitsLogged.toString(),
                  icon: Icons.checkroom,
                  trend: '+12 this month',
                  isPositiveTrend: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: 'Money Saved',
                  value: '\$${moneySaved.toStringAsFixed(0)}',
                  icon: Icons.savings,
                  trend: '+\$45 this month',
                  isPositiveTrend: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: 'Sustainability',
                  value: '$sustainabilityScore%',
                  icon: Icons.eco,
                  trend: '+5% this month',
                  isPositiveTrend: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: 'Items Added',
                  value: itemsAdded.toString(),
                  icon: Icons.add_circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: 'Avg Cost/Wear',
                  value: '\$${avgCostPerWear.toStringAsFixed(2)}',
                  icon: Icons.trending_down,
                  trend: '-\$2.10',
                  isPositiveTrend: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: 'Utilization',
                  value: '$wardrobeUtilization%',
                  icon: Icons.pie_chart,
                  trend: '+8%',
                  isPositiveTrend: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
