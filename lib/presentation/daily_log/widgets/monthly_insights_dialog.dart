import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MonthlyInsightsDialog extends StatelessWidget {
  final int totalOutfits;
  final int uniqueItems;
  final String favoriteOccasion;
  final String avgRating;

  const MonthlyInsightsDialog({
    Key? key,
    required this.totalOutfits,
    required this.uniqueItems,
    required this.favoriteOccasion,
    required this.avgRating,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required int totalOutfits,
    required int uniqueItems,
    required String favoriteOccasion,
    required String avgRating,
  }) {
    showDialog(
      context: context,
      builder: (context) => MonthlyInsightsDialog(
        totalOutfits: totalOutfits,
        uniqueItems: uniqueItems,
        favoriteOccasion: favoriteOccasion,
        avgRating: avgRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 2.w),
          const Text('Monthly Insights'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightRow(context, 'Total Outfits', '$totalOutfits'),
          _buildInsightRow(context, 'Unique Items', '$uniqueItems'),
          _buildInsightRow(context, 'Favorite Occasion', favoriteOccasion),
          _buildInsightRow(context, 'Avg. Rating', avgRating),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInsightRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
