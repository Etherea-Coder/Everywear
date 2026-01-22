import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Wardrobe Upload Step - Fourth step in personalization wizard
/// Optional wardrobe photo upload for AI analysis
class WardrobeUploadStep extends StatelessWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;

  const WardrobeUploadStep({
    Key? key,
    required this.photos,
    required this.onPhotosChanged,
  }) : super(key: key);

  void _addPhoto() {
    // Simulate photo selection
    final newPhotos = List<String>.from(photos);
    newPhotos.add('https://images.unsplash.com/photo-1489987707025-afc232f7ea0f');
    onPhotosChanged(newPhotos);
  }

  void _removePhoto(int index) {
    final newPhotos = List<String>.from(photos);
    newPhotos.removeAt(index);
    onPhotosChanged(newPhotos);
  }

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
            'Upload Wardrobe Photos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Optional: Upload photos of your wardrobe for AI-powered analysis and better recommendations.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          SizedBox(height: 3.h),
          // Privacy notice
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20.sp,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Your photos are private and used only to improve your recommendations. You can delete them anytime.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          // Photo grid
          if (photos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.w,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: NetworkImage(photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 1.w,
                      right: 1.w,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14.sp,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
          // Upload button
          GestureDetector(
            onTap: _addPhoto,
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(77),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48.sp,
                    color: theme.colorScheme.primary.withAlpha(153),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Add Photos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Tap to select from gallery or camera',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Skip option
          Center(
            child: TextButton(
              onPressed: () {
                // Clear photos to indicate skip
                onPhotosChanged([]);
              },
              child: Text(
                'Skip this step',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}