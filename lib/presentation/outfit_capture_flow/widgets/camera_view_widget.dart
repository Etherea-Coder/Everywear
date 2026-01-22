import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Camera view widget for outfit capture
/// Implements custom camera interface with overlay guides and controls
class CameraViewWidget extends StatefulWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final Function(XFile) onPhotoCaptured;
  final VoidCallback onGalleryPick;
  final Function(CameraController)? onCameraControllerChanged;

  const CameraViewWidget({
    Key? key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.onPhotoCaptured,
    required this.onGalleryPick,
    this.onCameraControllerChanged,
  }) : super(key: key);

  @override
  State<CameraViewWidget> createState() => _CameraViewWidgetState();
}

class _CameraViewWidgetState extends State<CameraViewWidget> {
  bool _isFlashOn = false;
  bool _isCapturing = false;
  CameraController? _localCameraController;

  @override
  void initState() {
    super.initState();
    _localCameraController = widget.cameraController;
  }

  @override
  void didUpdateWidget(CameraViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameraController != oldWidget.cameraController) {
      _localCameraController = widget.cameraController;
    }
  }

  /// Toggle flash mode
  Future<void> _toggleFlash() async {
    if (kIsWeb || _localCameraController == null) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _localCameraController!.setFlashMode(newFlashMode);
      if (mounted) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  /// Flip camera
  Future<void> _flipCamera() async {
    if (_localCameraController == null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final currentLens = _localCameraController!.description.lensDirection;
      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentLens,
        orElse: () => cameras.first,
      );

      await _localCameraController!.dispose();

      final newController = CameraController(
        newCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await newController.initialize();

      // Apply platform-specific settings
      try {
        await newController.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus mode not supported: $e');
      }

      if (!kIsWeb) {
        try {
          await newController.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Flash mode not supported: $e');
        }
      }

      if (mounted) {
        setState(() {
          _localCameraController = newController;
        });

        // Notify parent of controller change
        widget.onCameraControllerChanged?.call(newController);
      }
    } catch (e) {
      debugPrint('Camera flip error: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraFlipError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Capture photo
  Future<void> _capturePhoto() async {
    if (_localCameraController == null ||
        !widget.isCameraInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);

      final XFile photo = await _localCameraController!.takePicture();
      widget.onPhotoCaptured(photo);
    } catch (e) {
      debugPrint('Photo capture error: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraCaptureError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isCameraInitialized || _localCameraController == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(_localCameraController!),

        // Overlay guide
        _buildOverlayGuide(theme),

        // Controls
        _buildControls(theme),
      ],
    );
  }

  /// Build overlay guide for outfit framing
  Widget _buildOverlayGuide(ThemeData theme) {
    return CustomPaint(
      painter: _OutfitGuidePainter(color: Colors.white.withValues(alpha: 0.5)),
    );
  }

  /// Build camera controls
  Widget _buildControls(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          // Top controls
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!kIsWeb)
                  _buildControlButton(
                    theme: theme,
                    icon: _isFlashOn ? 'flash_on' : 'flash_off',
                    onTap: _toggleFlash,
                  ),
                const Spacer(),
                _buildControlButton(
                  theme: theme,
                  icon: 'flip_camera_android',
                  onTap: _flipCamera,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom controls
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                _buildActionButton(
                  theme: theme,
                  icon: 'photo_library',
                  onTap: widget.onGalleryPick,
                  size: 15.w,
                ),

                // Capture button
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 4,
                      ),
                    ),
                    child: _isCapturing
                        ? Padding(
                            padding: EdgeInsets.all(4.w),
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : null,
                  ),
                ),

                // Spacer for symmetry
                SizedBox(width: 15.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required ThemeData theme,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: Colors.white,
            size: 6.w,
          ),
        ),
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required ThemeData theme,
    required String icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for outfit guide overlay
class _OutfitGuidePainter extends CustomPainter {
  final Color color;

  _OutfitGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.7,
    );

    // Draw corner guides
    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + cornerLength),
      paint,
    );

    // Top-right
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right - cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right - cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
