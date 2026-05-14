import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../../core/utils/app_localizations.dart';

class ThemeSelectorDialog extends StatelessWidget {
  final String currentTheme;
  final Function(String) onThemeSelected;

  const ThemeSelectorDialog({
    Key? key,
    required this.currentTheme,
    required this.onThemeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        l10n.selectTheme,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 2.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context,
            theme,
            'light',
            l10n.lightMode,
            Icons.light_mode,
            l10n.lightModeDesc,
          ),
          _buildThemeOption(
            context,
            theme,
            'dark',
            l10n.darkMode,
            Icons.dark_mode,
            l10n.darkModeDesc,
          ),
          _buildThemeOption(
            context,
            theme,
            'auto',
            l10n.systemAuto,
            Icons.brightness_auto,
            l10n.systemAutoDesc,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeData theme,
    String value,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = currentTheme == value;

    return InkWell(
      onTap: () {
        onThemeSelected(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20.sp,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
