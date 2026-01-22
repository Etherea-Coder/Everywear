import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual wardrobe item card with swipe actions and selection support
class WardrobeItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const WardrobeItemCardWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Update field access to match database schema
    final name = item['name'] as String? ?? 'Unnamed Item';
    final category = item['category'] as String? ?? 'Uncategorized';
    final brand = item['brand'] as String? ?? '';
    final wearCount = item['wear_count'] as int? ?? 0;
    final imageUrl = item['image_url'] as String? ?? '';
    final semanticLabel = item['semantic_label'] as String? ?? 'Wardrobe item';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: imageUrl.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            semanticLabel: semanticLabel,
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'checkroom',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                ),
                // Details section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (brand.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                brand,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (!isMultiSelectMode)
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'star',
                                    color: theme.colorScheme.secondary,
                                    size: 14,
                                  ),
                                  SizedBox(width: 0.5.w),
                                  Text(
                                    '$wearCount',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Selection indicator
          if (isMultiSelectMode)
            Positioned(
              top: 2.w,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      )
                    : SizedBox(width: 16.sp, height: 16.sp),
              ),
            ),
        ],
      ),
    );
  }
}