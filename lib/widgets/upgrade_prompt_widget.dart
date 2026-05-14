import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../routes/app_routes.dart';

/// Reusable widget shown when an Essential user hits a tier limit.
/// Displays a contextual message and a soft CTA to upgrade.
class UpgradePromptWidget extends StatelessWidget {
  const UpgradePromptWidget({
    super.key,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final String title;
  final String message;

  /// Compact mode for inline banners, full mode for blocking screens
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Upgrade',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome,
                color: theme.colorScheme.primary, size: 32),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.premiumUpgrade),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Signature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe later',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show as a bottom sheet dialog
  static void show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptWidget(title: title, message: message),
    );
  }
}