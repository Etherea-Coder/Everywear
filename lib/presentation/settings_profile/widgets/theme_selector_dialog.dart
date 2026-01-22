import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    return AlertDialog(
      title: Text(
        'Select Theme',
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
            'Light Mode',
            Icons.light_mode,
            'Bright and clear interface',
          ),
          _buildThemeOption(
            context,
            theme,
            'dark',
            'Dark Mode',
            Icons.dark_mode,
            'Easy on the eyes at night',
          ),
          _buildThemeOption(
            context,
            theme,
            'auto',
            'Auto',
            Icons.brightness_auto,
            'Follows system settings',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
