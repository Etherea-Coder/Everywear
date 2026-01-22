import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Feature card displaying individual feature with preview capability
class FeatureCardWidget extends StatelessWidget {
  final Map<String, dynamic> feature;
  final VoidCallback onTryIt;

  const FeatureCardWidget({
    Key? key,
    required this.feature,
    required this.onTryIt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: CustomImageWidget(
                    imageUrl: feature['imageUrl'] as String,
                    width: double.infinity,
                    height: 35.h,
                    fit: BoxFit.cover,
                    semanticLabel: feature['semanticLabel'] as String,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(5.w),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (feature['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: feature['icon'] as String,
                                size: 24,
                                color: feature['color'] as Color,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature['title'] as String,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  feature['benefit'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: feature['color'] as Color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        feature['description'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onTryIt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: feature['color'] as Color,
                            side: BorderSide(
                              color: feature['color'] as Color,
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Learn More',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: feature['color'] as Color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              CustomIconWidget(
                                iconName: 'info_outline',
                                size: 18,
                                color: feature['color'] as Color,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
