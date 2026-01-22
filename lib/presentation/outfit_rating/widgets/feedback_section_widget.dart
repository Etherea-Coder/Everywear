import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Feedback section for outfit notes and comments
/// Provides a text field for users to add detailed feedback about their outfit
class FeedbackSectionWidget extends StatelessWidget {
  final TextEditingController controller;

  const FeedbackSectionWidget({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Share your thoughts about this outfit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What worked well? What would you change?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
