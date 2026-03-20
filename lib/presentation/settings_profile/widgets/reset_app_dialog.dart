import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';
import '../../../services/reset_service.dart';
import '../../../routes/app_routes.dart';

/// Shows a two-step confirmation dialog before wiping all user data.
/// Call [ResetAppDialog.show] from your settings screen.
class ResetAppDialog {
  static Future<void> show(BuildContext context) async {
    final loc = AppLocalizations.of(context);

    // ── Step 1: Warning + item list ──────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(ctx).colorScheme.error, size: 26),
            SizedBox(width: 2.w),
            Text(loc.translate('reset_title'),
                style: Theme.of(ctx).textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('reset_warning'),
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            SizedBox(height: 2.h),
            // What will be deleted
            _buildDeleteList(ctx, loc),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(ctx).colorScheme.error),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      loc.translate('reset_keeps_account'),
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(loc.translate('reset_continue_btn')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // ── Step 2: Type RESET to confirm ────────────────────────────────────
    final controller = TextEditingController();
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(loc.translate('reset_confirm_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('reset_type_instruction'),
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'RESET',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 1.5.h),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: controller.text.trim() == 'RESET'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.translate('reset_confirm_btn')),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (doubleConfirmed != true || !context.mounted) return;

    // ── Execute reset ─────────────────────────────────────────────────────
    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                SizedBox(width: 4.w),
                Text(loc.translate('reset_in_progress')),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await ResetService().resetAllUserData();

    // Clear local preferences
    if (result.success) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        if (kDebugMode) debugPrint('Prefs clear error: $e');
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close progress dialog

    if (result.success) {
      // Navigate to splash/onboarding and clear the stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.splash,
        (route) => false,
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${loc.translate('reset_error')}: ${result.errorMessage}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static Widget _buildDeleteList(BuildContext ctx, AppLocalizations loc) {
    final items = [
      (Icons.checkroom_outlined, loc.translate('reset_item_wardrobe')),
      (Icons.today_outlined,     loc.translate('reset_item_logs')),
      (Icons.shopping_bag_outlined, loc.translate('reset_item_purchases')),
      (Icons.flag_outlined,      loc.translate('reset_item_challenges')),
      (Icons.quiz_outlined,      loc.translate('reset_item_quiz')),
      (Icons.event_outlined,     loc.translate('reset_item_events')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                children: [
                  Icon(item.$1,
                      size: 16,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                  SizedBox(width: 2.w),
                  Text(
                    item.$2,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}