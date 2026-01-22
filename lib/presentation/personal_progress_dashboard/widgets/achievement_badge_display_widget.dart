import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

/// Achievement badge display widget for earned achievements
class AchievementBadgeDisplayWidget extends StatelessWidget {
  final String title;
  final String icon;
  final String rarity;
  final DateTime unlockedDate;

  const AchievementBadgeDisplayWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.rarity,
    required this.unlockedDate,
  }) : super(key: key);

  IconData _getIconData() {
    switch (icon) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'explore':
        return Icons.explore;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getRarityColor() {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarityColor = _getRarityColor();

    return Container(
      width: 28.w,
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: rarityColor.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(_getIconData(), size: 32, color: rarityColor),
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            DateFormat('MMM d').format(unlockedDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
