import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FeatureComparisonWidget extends StatelessWidget {
  const FeatureComparisonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final features = [
      {
        'feature': 'Outfit history',
        'essential': '30 saved looks',
        'signature': '100 saved looks',
      },
      {
        'feature': 'Daily suggestions',
        'essential': '1 basic daily idea',
        'signature': 'Intelligent outfit suggestions',
      },
      {
        'feature': 'Outfit swaps',
        'essential': 'Unlimited',
        'signature': 'Unlimited',
      },
      {
        'feature': 'AI coach',
        'essential': '1 per week',
        'signature': '50 per month',
      },
      {
        'feature': 'Wardrobe insights',
        'essential': 'Essential stats',
        'signature': 'Advanced insights',
      },
      {
        'feature': 'Cost-per-wear analysis',
        'essential': '—',
        'signature': 'Included',
      },
      {
        'feature': 'Unused item detection',
        'essential': '—',
        'signature': 'Included',
      },
      {
        'feature': 'Event styling guidance',
        'essential': 'Basic',
        'signature': 'Enhanced',
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary.withValues(alpha: 0.12),
                  theme.colorScheme.secondary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Essential',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 15.sp,
                        color: theme.colorScheme.secondary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Signature',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isLast = index == features.length - 1;
            final essentialValue = feature['essential'] ?? '';
            final signatureValue = feature['signature'] ?? '';
            final isLockedInEssential = essentialValue.trim() == '—';

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.7.h),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: 2.w),
                      child: Text(
                        feature['feature']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        essentialValue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isLockedInEssential
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: isLockedInEssential
                              ? FontWeight.w500
                              : FontWeight.w600,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        signatureValue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
