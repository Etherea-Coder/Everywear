import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Style Preference Step - First step in personalization wizard
/// Visual mood board for selecting fashion aesthetics
class StylePreferenceStep extends StatelessWidget {
  final List<String> selectedStyles;
  final Function(List<String>) onStylesChanged;

  const StylePreferenceStep({
    Key? key,
    required this.selectedStyles,
    required this.onStylesChanged,
  }) : super(key: key);

  List<Map<String, dynamic>> _getStyleOptions(AppLocalizations localizations) => [
    {
      'id': 'minimalist',
      'label': localizations.styleMinimalist,
      'icon': Icons.circle_outlined,
      'description': localizations.styleMinimalistDesc,
    },
    {
      'id': 'bohemian',
      'label': localizations.styleBohemian,
      'icon': Icons.nature_people_outlined,
      'description': localizations.styleBohemianDesc,
    },
    {
      'id': 'classic',
      'label': localizations.styleClassic,
      'icon': Icons.checkroom_outlined,
      'description': localizations.styleClassicDesc,
    },
    {
      'id': 'trendy',
      'label': localizations.styleTrendy,
      'icon': Icons.auto_awesome_outlined,
      'description': localizations.styleTrendyDesc,
    },
    {
      'id': 'eclectic',
      'label': localizations.styleEclectic,
      'icon': Icons.palette_outlined,
      'description': localizations.styleEclecticDesc,
    },
    {
      'id': 'sporty',
      'label': localizations.styleSporty,
      'icon': Icons.directions_run_outlined,
      'description': localizations.styleSportyDesc,
    },
  ];

  void _toggleStyle(String styleId) {
    final newStyles = List<String>.from(selectedStyles);
    if (newStyles.contains(styleId)) {
      newStyles.remove(styleId);
    } else {
      newStyles.add(styleId);
    }
    onStylesChanged(newStyles);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final styleOptions = _getStyleOptions(localizations);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            localizations.styleStepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            localizations.styleStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.1,
            ),
            itemCount: styleOptions.length,
            itemBuilder: (context, index) {
              final style = styleOptions[index];
              final isSelected = selectedStyles.contains(style['id']);

              return GestureDetector(
                onTap: () => _toggleStyle(style['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(26)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(51),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        style['icon'] as IconData,
                        size: 32.sp,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withAlpha(153),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        style['label'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        style['description'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
          if (selectedStyles.isNotEmpty)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(13),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      localizations.styleSelectionConfirmation,
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
}
