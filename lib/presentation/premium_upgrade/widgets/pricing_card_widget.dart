import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PricingCardWidget extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final String? savings;
  final List<String> features;
  final bool isSelected;
  final bool isBestValue;
  final VoidCallback onSelect;
  final VoidCallback onUpgrade;

  const PricingCardWidget({
    Key? key,
    required this.planName,
    required this.price,
    required this.period,
    this.savings,
    required this.features,
    required this.isSelected,
    this.isBestValue = false,
    required this.onSelect,
    required this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.5.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.secondary.withValues(alpha: 0.35)
                : theme.colorScheme.outline.withValues(alpha: 0.14),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.cardColor,
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            planName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isBestValue) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.4.w,
                                vertical: 0.45.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Best value',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        _getPlanSubtitle(planName),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  size: 21.sp,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Pricing
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    height: 1,
                  ),
                ),
                SizedBox(width: 1.2.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 0.7.h),
                  child: Text(
                    period,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            if (savings != null) ...[
              SizedBox(height: 0.9.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.8.w,
                  vertical: 0.5.h,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  savings!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],

            SizedBox(height: 2.2.h),

            // Features
            ...features.map(
              (feature) => Padding(
                padding: EdgeInsets.only(bottom: 1.2.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 0.15.h),
                      child: Icon(
                        Icons.check_circle,
                        size: 16.sp,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 2.4.w),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 2.2.h),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSelected ? onUpgrade : onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary
                      : theme.cardColor,
                  foregroundColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  elevation: isSelected ? 1.5 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(
                        alpha: isSelected ? 0 : 0.45,
                      ),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Text(
                  isSelected ? 'Continue' : 'Choose plan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanSubtitle(String planName) {
    final plan = planName.toLowerCase();

    if (plan.contains('monthly')) {
      return 'Flexible access to Signature, billed monthly.';
    }

    if (plan.contains('annual') || plan.contains('yearly')) {
      return 'The best long-term value for your wardrobe studio.';
    }

    return 'Choose the plan that fits your rhythm best.';
  }
}
