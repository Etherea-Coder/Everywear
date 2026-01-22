import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget for wardrobe with supportive messaging
class EmptyWardrobeWidget extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onAddItem;

  const EmptyWardrobeWidget({
    Key? key,
    required this.hasSearchQuery,
    required this.onAddItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: hasSearchQuery ? 'search_off' : 'checkroom',
                  color: theme.colorScheme.primary,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              hasSearchQuery
                  ? 'No items found'
                  : 'Start building your wardrobe',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              hasSearchQuery
                  ? 'Try adjusting your search or filters to find what you\'re looking for'
                  : 'Add your first clothing item to start understanding your personal style and maximizing what you already own',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearchQuery) ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: onAddItem,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: const Text('Add Your First Item'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
