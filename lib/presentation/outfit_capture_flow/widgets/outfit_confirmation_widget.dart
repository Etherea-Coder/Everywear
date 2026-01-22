import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Outfit confirmation widget for final review and rating
/// Implements outfit preview with rating system and optional notes
class OutfitConfirmationWidget extends StatefulWidget {
  final XFile? capturedImage;
  final List<Map<String, dynamic>> selectedItems;
  final String captureMethod;
  final Function(String, int) onConfirm;
  final VoidCallback onRetake;

  const OutfitConfirmationWidget({
    Key? key,
    this.capturedImage,
    required this.selectedItems,
    required this.captureMethod,
    required this.onConfirm,
    required this.onRetake,
  }) : super(key: key);

  @override
  State<OutfitConfirmationWidget> createState() =>
      _OutfitConfirmationWidgetState();
}

class _OutfitConfirmationWidgetState extends State<OutfitConfirmationWidget> {
  final TextEditingController _outfitNameController = TextEditingController();
  int _selectedRating =
      0; // 0: not rated, 1: didn't feel great, 2: OK, 3: loved it

  @override
  void dispose() {
    _outfitNameController.dispose();
    super.dispose();
  }

  /// Handle save outfit
  void _handleSave() {
    if (_selectedRating == 0) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.rateOutfitError),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final outfitName = _outfitNameController.text.trim().isEmpty
        ? 'Outfit ${DateTime.now().toString().substring(0, 10)}'
        : _outfitNameController.text.trim();

    widget.onConfirm(outfitName, _selectedRating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview section
                _buildPreviewSection(theme, localizations),

                SizedBox(height: 3.h),

                // Outfit name field
                _buildOutfitNameField(theme, localizations),

                SizedBox(height: 3.h),

                // Rating section
                _buildRatingSection(theme, localizations),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),

        // Action buttons
        _buildActionButtons(theme, localizations),
      ],
    );
  }

  /// Build preview section
  Widget _buildPreviewSection(ThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.outfitPreview,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: widget.onRetake,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              label: Text(
                localizations.retake,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),

        widget.captureMethod == 'camera'
            ? _buildCameraPreview(theme, localizations)
            : _buildWardrobePreview(theme, localizations),
      ],
    );
  }

  /// Build camera preview
  Widget _buildCameraPreview(ThemeData theme, AppLocalizations localizations) {
    if (widget.capturedImage == null) {
      return Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            localizations.noImageCaptured,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: kIsWeb
          ? Image.network(
              widget.capturedImage!.path,
              height: 50.h,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(widget.capturedImage!.path),
              height: 50.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  /// Build wardrobe preview
  Widget _buildWardrobePreview(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.getSelectedItemsLabel(widget.selectedItems.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 0.75,
            ),
            itemCount: widget.selectedItems.length,
            itemBuilder: (context, index) {
              final item = widget.selectedItems[index];
              return _buildItemPreviewCard(theme, item);
            },
          ),
        ],
      ),
    );
  }

  /// Build item preview card
  Widget _buildItemPreviewCard(ThemeData theme, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CustomImageWidget(
              imageUrl: item['image'] as String,
              width: double.infinity,
              height: 15.h,
              fit: BoxFit.cover,
              semanticLabel: item['semanticLabel'] as String,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  item['category'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build outfit name field
  Widget _buildOutfitNameField(ThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.outfitNameOptional,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _outfitNameController,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: localizations.outfitNameHint,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  /// Build rating section
  Widget _buildRatingSection(ThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.feelInOutfitQuestion,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildRatingOption(
                theme: theme,
                rating: 1,
                icon: 'sentiment_dissatisfied',
                label: localizations.ratingNotGreat,
                color: const Color(0xFFA0522D),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildRatingOption(
                theme: theme,
                rating: 2,
                icon: 'sentiment_neutral',
                label: localizations.ratingOk,
                color: const Color(0xFFB8860B),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildRatingOption(
                theme: theme,
                rating: 3,
                icon: 'sentiment_very_satisfied',
                label: localizations.ratingLovedIt,
                color: const Color(0xFF4A7C59),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build rating option
  Widget _buildRatingOption({
    required ThemeData theme,
    required int rating,
    required String icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedRating == rating;

    return GestureDetector(
      onTap: () => setState(() => _selectedRating = rating),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 6.h),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            localizations.saveOutfit,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
