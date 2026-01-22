import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class StatsSummaryWidget extends StatelessWidget {
  final int totalOutfits;
  final int uniqueItems;
  final String favoriteOccasion;

  const StatsSummaryWidget({
    Key? key,
    required this.totalOutfits,
    required this.uniqueItems,
    required this.favoriteOccasion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha(26),
            AppTheme.primaryLight.withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.checkroom,
            label: 'Outfits',
            value: '$totalOutfits',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.style,
            label: 'Items',
            value: '$uniqueItems',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.favorite,
            label: 'Top',
            value: favoriteOccasion,
            isText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isText = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 24),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: isText ? 12.sp : 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}