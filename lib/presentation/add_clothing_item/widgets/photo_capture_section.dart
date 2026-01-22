import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/ai/vision_engine_service.dart';
import '../../../core/utils/image_optimizer.dart';
import 'dart:io';

/// Photo capture section widget for adding clothing item photos
/// Supports up to 3 photos with camera and gallery options
class PhotoCaptureSection extends StatefulWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;
  final Function(Map<String, dynamic>)? onAIAnalysisComplete;

  const PhotoCaptureSection({
    Key? key,
    required this.photos,
    required this.onPhotosChanged,
    this.onAIAnalysisComplete,
  }) : super(key: key);

  @override
  State<PhotoCaptureSection> createState() => _PhotoCaptureSectionState();
}

class _PhotoCaptureSectionState extends State<PhotoCaptureSection> {
  final ImagePicker _picker = ImagePicker();
  final int _maxPhotos = 3;
  final VisionEngineService _visionEngine = VisionEngineService();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiAnalysisResult;

  Future<void> _showPhotoOptions() async {
    if (widget.photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxPhotos photos allowed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'photo_library',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'close',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
                title: const Text('Skip Photo'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      bool hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take photos'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        // Optimize image
        final optimizedFile = await ImageOptimizer.compressImage(File(photo.path));
        
        final updatedPhotos = List<String>.from(widget.photos)..add(optimizedFile.path);
        widget.onPhotosChanged(updatedPhotos);

        // Run AI analysis on the optimized photo
        await _analyzePhoto(optimizedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture photo. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Optimize image
        final optimizedFile = await ImageOptimizer.compressImage(File(image.path));
        
        final updatedPhotos = List<String>.from(widget.photos)..add(optimizedFile.path);
        widget.onPhotosChanged(updatedPhotos);

        // Run AI analysis on the optimized photo
        await _analyzePhoto(optimizedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select photo. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Analyze photo using AI vision engine
  Future<void> _analyzePhoto(String imagePath) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Initialize model if needed
      final isModelReady = await _visionEngine.isModelDownloaded();
      if (!isModelReady) {
        // Model will be downloaded in background
        await _visionEngine.downloadModel();
      }

      // Run AI analysis
      final result = await _visionEngine.analyzeClothing(imagePath);

      setState(() {
        _aiAnalysisResult = result;
        _isAnalyzing = false;
      });

      // Notify parent widget
      widget.onAIAnalysisComplete?.call(result);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI detected: ${result['category']} (${(result['confidence'] * 100).toInt()}% confident)',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI analysis unavailable. You can still add the item manually.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  void _removePhoto(int index) {
    final updatedPhotos = List<String>.from(widget.photos)..removeAt(index);
    widget.onPhotosChanged(updatedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Photos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isAnalyzing) ...[
                SizedBox(width: 2.w),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'AI analyzing...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Add up to $_maxPhotos photos of your clothing item',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_aiAnalysisResult != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'verified',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'AI detected: ${_aiAnalysisResult!['color']} ${_aiAnalysisResult!['material']} ${_aiAnalysisResult!['category']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  widget.photos.length +
                  (widget.photos.length < _maxPhotos ? 1 : 0),
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                if (index == widget.photos.length) {
                  return _buildAddPhotoButton(theme);
                }
                return _buildPhotoCard(theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(ThemeData theme) {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'add_a_photo',
              color: theme.colorScheme.primary,
              size: 48,
            ),
            SizedBox(height: 1.h),
            Text(
              'Add Photo',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(ThemeData theme, int index) {
    return Stack(
      children: [
        Container(
          width: 40.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(
                    widget.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: CustomIconWidget(
                        iconName: 'broken_image',
                        color: theme.colorScheme.error,
                        size: 48,
                      ),
                    ),
                  )
                : Image.network(
                    widget.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: CustomIconWidget(
                        iconName: 'broken_image',
                        color: theme.colorScheme.error,
                        size: 48,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 1.h,
          right: 2.w,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onError,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
