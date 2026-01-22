import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Individual suggestion card with swipe actions
class SuggestionCardWidget extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final bool isSaved;
  final bool isAIGenerated;
  final VoidCallback onWearThis;
  final VoidCallback onSaveForLater;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const SuggestionCardWidget({
    Key? key,
    required this.suggestion,
    required this.isSaved,
    this.isAIGenerated = false,
    required this.onWearThis,
    required this.onSaveForLater,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherAppropriate = suggestion["weatherAppropriate"] as bool;

    return Dismissible(
      key: Key(suggestion["id"] as String),
      background: _buildSwipeBackground(theme, isLeft: true),
      secondaryBackground: _buildSwipeBackground(theme, isLeft: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDismiss();
        } else {
          onSaveForLater();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isAIGenerated
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outfit image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildOutfitImage(theme),
                  ),

                  // AI Badge
                  if (isAIGenerated)
                    Positioned(
                      top: 2.h,
                      left: 3.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'auto_awesome',
                              color: theme.colorScheme.onPrimary,
                              size: 12,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'AI',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Confidence badge
                  Positioned(
                    top: 2.h,
                    right: 3.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'verified',
                            color: theme.colorScheme.onPrimary,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${suggestion["confidence"]}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Weather indicator
                  weatherAppropriate
                      ? const SizedBox.shrink()
                      : Positioned(
                          top: 2.h,
                          left: 3.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'warning',
                                  color: theme.colorScheme.error,
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  'Check weather',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reasoning
                    Text(
                      suggestion["reasoning"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 2.h),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: onWearThis,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            ),
                            child: const Text('Wear This'),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSaveForLater,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            ),
                            child: CustomIconWidget(
                              iconName: isSaved
                                  ? 'bookmark'
                                  : 'bookmark_border',
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(ThemeData theme, {required bool isLeft}) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: isLeft ? theme.colorScheme.primary : theme.colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: isLeft ? 'bookmark' : 'close',
            color: Colors.white,
            size: 28,
          ),
          SizedBox(height: 0.5.h),
          Text(
            isLeft ? 'Save' : 'Dismiss',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitImage(ThemeData theme) {
    // For AI-generated suggestions, show item grid
    if (isAIGenerated && suggestion['items'] != null) {
      final items = suggestion['items'] as List<Map<String, dynamic>>;

      if (items.length == 2) {
        return SizedBox(
          height: 30.h,
          child: Row(
            children: items.map((item) {
              return Expanded(
                child: CustomImageWidget(
                  imageUrl: item['image'] as String,
                  height: 30.h,
                  fit: BoxFit.cover,
                  semanticLabel:
                      item['semanticLabel'] as String? ?? 'Clothing item',
                ),
              );
            }).toList(),
          ),
        );
      } else if (items.length >= 3) {
        return SizedBox(
          height: 30.h,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: items.take(2).map((item) {
                    return Expanded(
                      child: CustomImageWidget(
                        imageUrl: item['image'] as String,
                        height: 15.h,
                        fit: BoxFit.cover,
                        semanticLabel:
                            item['semanticLabel'] as String? ?? 'Clothing item',
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Row(
                  children: items.skip(2).take(2).map((item) {
                    return Expanded(
                      child: CustomImageWidget(
                        imageUrl: item['image'] as String,
                        height: 15.h,
                        fit: BoxFit.cover,
                        semanticLabel:
                            item['semanticLabel'] as String? ?? 'Clothing item',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Fallback to single outfit image
    return CustomImageWidget(
      imageUrl: suggestion["outfitImage"] as String,
      width: double.infinity,
      height: 30.h,
      fit: BoxFit.cover,
      semanticLabel: suggestion["semanticLabel"] as String,
    );
  }
}
