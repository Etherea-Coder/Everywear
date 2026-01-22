import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Monthly summary widget showing key spending metrics
class MonthlySummaryWidget extends StatelessWidget {
  final double totalSpent;
  final int purchaseCount;
  final double averageCostPerWear;

  const MonthlySummaryWidget({
    Key? key,
    required this.totalSpent,
    required this.purchaseCount,
    required this.averageCostPerWear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                context,
                'Total Spent',
                '\$${totalSpent.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
              _buildDivider(theme),
              _buildMetric(
                context,
                'Purchases',
                purchaseCount.toString(),
                Icons.shopping_bag,
              ),
              _buildDivider(theme),
              _buildMetric(
                context,
                'Avg CPW',
                '\$${averageCostPerWear.toStringAsFixed(2)}',
                Icons.trending_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
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
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(height: 40, width: 1, color: theme.dividerColor);
  }
}
