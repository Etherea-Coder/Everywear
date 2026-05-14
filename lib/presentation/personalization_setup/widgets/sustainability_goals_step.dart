import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Sustainability Goals Step - Third step in personalization wizard
/// Captures sustainability preferences using slider controls
class SustainabilityGoalsStep extends StatelessWidget {
  final double purchaseFrequency;
  final double budgetConsciousness;
  final double environmentalImpact;
  final Function({double? purchase, double? budget, double? environmental})
  onSustainabilityChanged;

  const SustainabilityGoalsStep({
    Key? key,
    required this.purchaseFrequency,
    required this.budgetConsciousness,
    required this.environmentalImpact,
    required this.onSustainabilityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            AppLocalizations.of(context).sustainabilityStepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            AppLocalizations.of(context).sustainabilityStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          // Purchase frequency
          _buildSliderSection(
            context,
            title: AppLocalizations.of(context).purchaseFrequencyLabel,
            description: AppLocalizations.of(context).purchaseFrequencyDesc,
            icon: Icons.shopping_bag_outlined,
            value: purchaseFrequency,
            min: 1,
            max: 5,
            divisions: 4,
            labels: [
              AppLocalizations.of(context).rarelyLabel,
              AppLocalizations.of(context).occasionalSustainabilityLabel,
              AppLocalizations.of(context).regularlyLabel,
              AppLocalizations.of(context).oftenLabel,
              AppLocalizations.of(context).frequentlyLabel,
            ],
            onChanged: (value) => onSustainabilityChanged(purchase: value),
          ),
          SizedBox(height: 3.h),
          // Budget consciousness
          _buildSliderSection(
            context,
            title: AppLocalizations.of(context).budgetConsciousnessLabel,
            description: AppLocalizations.of(context).budgetConsciousnessDesc,
            icon: Icons.account_balance_wallet_outlined,
            value: budgetConsciousness,
            min: 1,
            max: 5,
            divisions: 4,
            labels: [
              AppLocalizations.of(context).flexibleLabel,
              AppLocalizations.of(context).somewhatLabel,
              AppLocalizations.of(context).moderateSustainabilityLabel,
              AppLocalizations.of(context).importantLabel,
              AppLocalizations.of(context).veryImportantLabel,
            ],
            onChanged: (value) => onSustainabilityChanged(budget: value),
          ),
          SizedBox(height: 3.h),
          // Environmental impact
          _buildSliderSection(
            context,
            title: AppLocalizations.of(context).environmentalImpactLabel,
            description: AppLocalizations.of(context).environmentalImpactDesc,
            icon: Icons.eco_outlined,
            value: environmentalImpact,
            min: 1,
            max: 5,
            divisions: 4,
            labels: [
              AppLocalizations.of(context).lowLabel,
              AppLocalizations.of(context).someLabel,
              AppLocalizations.of(context).moderateSustainabilityLabel,
              AppLocalizations.of(context).highLabel,
              AppLocalizations.of(context).veryHighLabel,
            ],
            onChanged: (value) => onSustainabilityChanged(environmental: value),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20.sp,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).sustainabilityConfirmation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required List<String> labels,
    required Function(double) onChanged,
  }) {
    final theme = Theme.of(context);
    final currentIndex = (value - 1).round();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 2.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withAlpha(51),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withAlpha(51),
              trackHeight: 0.5.h,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Text(
            labels[currentIndex],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
