import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/feedback_section_widget.dart';
import './widgets/outfit_preview_widget.dart';
import './widgets/rating_stars_widget.dart';

/// Outfit Rating Screen - Rate and provide feedback on daily outfits
/// Allows users to rate their outfit experience, add notes about comfort,
/// occasion appropriateness, and receive insights for future recommendations.
class OutfitRating extends StatefulWidget {
  const OutfitRating({Key? key}) : super(key: key);

  @override
  State<OutfitRating> createState() => _OutfitRatingState();
}

class _OutfitRatingState extends State<OutfitRating> {
  int _overallRating = 0;
  int _comfortRating = 0;
  int _styleRating = 0;
  int _versatilityRating = 0;
  final TextEditingController _notesController = TextEditingController();
  String _selectedOccasion = 'Casual';
  bool _wouldWearAgain = true;
  bool _isSaving = false;

  final List<String> _occasions = [
    'Casual',
    'Work',
    'Formal',
    'Athletic',
    'Social Event',
    'Date Night',
    'Travel',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRating() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Simulate saving rating data
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back after short delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Rate Your Outfit', variant: CustomAppBarVariant.detail),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutfitPreviewWidget(),
                SizedBox(height: 3.h),
                _buildOverallRatingSection(theme),
                SizedBox(height: 3.h),
                _buildDetailedRatingsSection(theme),
                SizedBox(height: 3.h),
                _buildOccasionSection(theme),
                SizedBox(height: 3.h),
                _buildWouldWearAgainSection(theme),
                SizedBox(height: 3.h),
                FeedbackSectionWidget(controller: _notesController),
                SizedBox(height: 3.h),
                _buildSaveButton(theme),
                SizedBox(height: 2.h),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Saving your rating...',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverallRatingSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Rating',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'How did you feel in this outfit?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 2.h),
            Center(
              child: RatingStarsWidget(
                rating: _overallRating,
                size: 48.0,
                onRatingChanged: (rating) {
                  setState(() => _overallRating = rating);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Ratings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildRatingRow(
              theme,
              'Comfort',
              _comfortRating,
              (rating) => setState(() => _comfortRating = rating),
            ),
            SizedBox(height: 2.h),
            _buildRatingRow(
              theme,
              'Style',
              _styleRating,
              (rating) => setState(() => _styleRating = rating),
            ),
            SizedBox(height: 2.h),
            _buildRatingRow(
              theme,
              'Versatility',
              _versatilityRating,
              (rating) => setState(() => _versatilityRating = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    ThemeData theme,
    String label,
    int rating,
    Function(int) onRatingChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        RatingStarsWidget(
          rating: rating,
          size: 28.0,
          onRatingChanged: onRatingChanged,
        ),
      ],
    );
  }

  Widget _buildOccasionSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Occasion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _occasions.map((occasion) {
                final isSelected = _selectedOccasion == occasion;
                return ChoiceChip(
                  label: Text(occasion),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedOccasion = occasion);
                    }
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWouldWearAgainSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Would wear again?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Help us learn your preferences',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _wouldWearAgain,
              onChanged: (value) {
                setState(() => _wouldWearAgain = value);
              },
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
        ),
        child: Text(
          'Save Rating',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}