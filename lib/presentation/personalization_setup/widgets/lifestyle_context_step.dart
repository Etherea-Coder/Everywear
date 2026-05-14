import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/utils/app_localizations.dart';



/// Lifestyle Context Step - Second step in personalization wizard
/// Captures work environment, social activities, and climate preferences
class LifestyleContextStep extends StatelessWidget {
  final String? workEnvironment;
  final String? socialFrequency;
  final String? climate;
  final Function({String? work, String? social, String? climate})
  onLifestyleChanged;

  const LifestyleContextStep({
    Key? key,
    required this.workEnvironment,
    required this.socialFrequency,
    required this.climate,
    required this.onLifestyleChanged,
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
            AppLocalizations.of(context).lifestyleStepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            AppLocalizations.of(context).lifestyleStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          // Work environment
          _buildSectionTitle(context, AppLocalizations.of(context).workEnvironmentLabel),
          SizedBox(height: 1.h),
          _buildOptionGroup(
            context,
            options: [
              {
                'id': 'office',
                'label': AppLocalizations.of(context).officeLabel,
                'icon': Icons.business_outlined,
              },
              {
                'id': 'remote',
                'label': AppLocalizations.of(context).remoteLabel,
                'icon': Icons.home_outlined
              },
              {
                'id': 'creative',
                'label': AppLocalizations.of(context).creativeLabel,
                'icon': Icons.brush_outlined,
              },
              {
                'id': 'casual',
                'label': AppLocalizations.of(context).casualLabel,
                'icon': Icons.weekend_outlined,
              },
            ],
            selectedValue: workEnvironment,
            onChanged: (value) => onLifestyleChanged(work: value),
          ),
          SizedBox(height: 3.h),
          // Social activities
          _buildSectionTitle(context, AppLocalizations.of(context).socialActivitiesLabel),
          SizedBox(height: 1.h),
          _buildOptionGroup(
            context,
            options: [
              {
                'id': 'frequent',
                'label': AppLocalizations.of(context).frequentLabel,
                'icon': Icons.groups_outlined,
              },
              {
                'id': 'occasional',
                'label': AppLocalizations.of(context).occasionalLabel,
                'icon': Icons.people_outline,
              },
              {
                'id': 'rare',
                'label': AppLocalizations.of(context).rareLabel,
                'icon': Icons.person_outline
              },
            ],
            selectedValue: socialFrequency,
            onChanged: (value) => onLifestyleChanged(social: value),
          ),
          SizedBox(height: 3.h),
          // Climate
          _buildSectionTitle(context, AppLocalizations.of(context).climateLabel),
          SizedBox(height: 1.h),
          _buildOptionGroup(
            context,
            options: [
              {
                'id': 'warm',
                'label': AppLocalizations.of(context).warmLabel,
                'icon': Icons.wb_sunny_outlined
              },
              {
                'id': 'moderate',
                'label': AppLocalizations.of(context).moderateLabel,
                'icon': Icons.cloud_outlined,
              },
              {
                'id': 'cold',
                'label': AppLocalizations.of(context).coldLabel,
                'icon': Icons.ac_unit_outlined
              },
              {
                'id': 'variable',
                'label': AppLocalizations.of(context).variableLabel,
                'icon': Icons.thermostat_outlined,
              },
            ],
            selectedValue: climate,
            onChanged: (value) => onLifestyleChanged(climate: value),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildOptionGroup(
    BuildContext context, {
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: options.map((option) {
        final isSelected = selectedValue == option['id'];
        return GestureDetector(
          onTap: () => onChanged(option['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withAlpha(51),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 18.sp,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withAlpha(179),
                ),
                SizedBox(width: 2.w),
                Text(
                  option['label'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
