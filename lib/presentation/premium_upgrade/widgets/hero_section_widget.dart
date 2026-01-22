import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HeroSectionWidget extends StatelessWidget {
  const HeroSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Premium Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: theme.colorScheme.onSecondary,
                  size: 18.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Main Tagline
          Text(
            'Unlock Your Style Potential',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          // Subtitle
          Text(
            'Get unlimited access to advanced analytics, AI-powered insights, and exclusive learning content',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
