import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ai_suggestions_service.dart';
import '../../services/weather_service.dart';
import '../ai_suggestions/widgets/ai_suggestion_bubble_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/camera_view_widget.dart';
import './widgets/outfit_confirmation_widget.dart';
import './widgets/wardrobe_selection_widget.dart';

/// Outfit Capture Flow screen for quick outfit photography and item selection
/// Implements streamlined mobile interface with camera integration and wardrobe selection
class OutfitCaptureFlow extends StatefulWidget {
  const OutfitCaptureFlow({Key? key}) : super(key: key);

  @override
  State<OutfitCaptureFlow> createState() => _OutfitCaptureFlowState();
}

class _OutfitCaptureFlowState extends State<OutfitCaptureFlow> {
  // Flow state management
  int _currentStep =
      0; // 0: Method selection, 1: Camera/Wardrobe, 2: Confirmation
  String _captureMethod = ''; // 'camera' or 'wardrobe'

  // Camera state
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  XFile? _capturedImage;

  // Wardrobe selection state
  List<Map<String, dynamic>> _selectedItems = [];

  // Loading state
  bool _isLoading = false;

  final AiSuggestionsService _aiSuggestionsService = AiSuggestionsService();
  final WeatherService _weatherService = WeatherService();
  String? _aiSuggestions;
  bool _isLoadingSuggestions = false;
  String _selectedLanguage = 'EN';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Request camera permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraPermissionRequired),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      setState(() => _isLoading = true);

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      // Apply platform-specific settings
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus mode not supported: $e');
      }

      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Flash mode not supported: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraInitError),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle camera controller change from child widget
  void _onCameraControllerChanged(CameraController newController) {
    setState(() {
      _cameraController = newController;
    });
  }

  /// Handle method selection
  void _selectCaptureMethod(String method) {
    HapticFeedback.lightImpact();
    setState(() {
      _captureMethod = method;
      _currentStep = 1;
    });

    if (method == 'camera') {
      _initializeCamera();
    }
  }

  /// Handle photo capture from camera
  void _onPhotoCaptured(XFile photo) {
    setState(() {
      _capturedImage = photo;
      _currentStep = 2;
    });
  }

  /// Handle wardrobe items selection
  void _onItemsSelected(List<Map<String, dynamic>> items) {
    setState(() {
      _selectedItems = items;
      _currentStep = 2;
    });
  }

  /// Handle outfit confirmation
  void _onOutfitConfirmed(String outfitName, int rating) {
    // Save outfit logic would go here
    Navigator.of(context, rootNavigator: true).pop({
      'success': true,
      'outfitName': outfitName,
      'rating': rating,
      'captureMethod': _captureMethod,
      'image': _capturedImage?.path,
      'items': _selectedItems,
    });
  }

  /// Handle back navigation
  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _captureMethod = '';
        _capturedImage = null;
        _selectedItems.clear();
        _cameraController?.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
      });
    } else {
      setState(() {
        _currentStep = 1;
        _capturedImage = null;
      });
    }
  }

  Future<void> _getAiSuggestions(String imageUrl) async {
    setState(() {
      _isLoadingSuggestions = true;
      _aiSuggestions = null;
    });

    // Fetch weather context
    final weatherContext = await _weatherService.getCurrentWeather();

    // Prepare items context (if building from wardrobe)
    final itemsContext =
        _selectedItems.isNotEmpty
            ? _selectedItems
                .map(
                  (item) => {
                    'name': item['name'],
                    'category': item['category'],
                    'brand': item['brand'],
                  },
                )
                .toList()
            : null;

    final result = await _aiSuggestionsService.generateSuggestions(
      imageUrl: imageUrl,
      language: _selectedLanguage,
      weatherContext: weatherContext,
      itemHistory: itemsContext,
    );

    setState(() {
      _isLoadingSuggestions = false;
      if (result['success'] == true) {
        _aiSuggestions = result['suggestions'];
      }
    });
  }

  void _dismissSuggestions() {
    setState(() {
      _aiSuggestions = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: _currentStep == 0 ? 'close' : 'arrow_back',
              color:
                  theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleBack,
            tooltip: _currentStep == 0 ? localizations.cancel : localizations.back,
          ),
          title: Text(
            _currentStep == 0
                ? localizations.logOutfit
                : _currentStep == 1
                ? _captureMethod == 'camera'
                      ? localizations.captureOutfit
                      : localizations.selectFromWardrobe
                : localizations.confirmOutfit,
            style: theme.appBarTheme.titleTextStyle,
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _buildCurrentStep(theme),

            // AI Suggestions Bubble
            if (_aiSuggestions != null)
              Positioned(
                bottom: 10.h,
                left: 0,
                right: 0,
                child: AiSuggestionBubbleWidget(
                  suggestions: _aiSuggestions!,
                  onDismiss: _dismissSuggestions,
                ),
              ),

            // Loading indicator for AI suggestions
            if (_isLoadingSuggestions)
              Positioned(
                bottom: 10.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          localizations.gettingAiSuggestions,
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Language selector button
            Positioned(
              top: 12.h,
              right: 4.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  initialValue: _selectedLanguage,
                  onSelected: (value) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'EN', child: Text('🇬🇧 English')),
                    PopupMenuItem(value: 'FR', child: Text('🇫🇷 Français')),
                    PopupMenuItem(value: 'ES', child: Text('🇪🇸 Español')),
                  ],
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, size: 18.sp),
                        SizedBox(width: 1.w),
                        Text(
                          _selectedLanguage,
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // AI Suggestions trigger button (after photo capture)
            if (_capturedImage != null && !_isLoadingSuggestions)
              Positioned(
                bottom: 18.h,
                right: 4.w,
                child: FloatingActionButton.extended(
                  onPressed: () => _getAiSuggestions(_capturedImage!.path),
                  backgroundColor: Color(0xFF6366F1),
                  icon: Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    localizations.getAiTips,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build current step content
  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection(theme);
      case 1:
        return _captureMethod == 'camera'
            ? CameraViewWidget(
                cameraController: _cameraController,
                isCameraInitialized: _isCameraInitialized,
                onPhotoCaptured: _onPhotoCaptured,
                onGalleryPick: _pickFromGallery,
                onCameraControllerChanged: _onCameraControllerChanged,
              )
            : WardrobeSelectionWidget(onItemsSelected: _onItemsSelected);
      case 2:
        return OutfitConfirmationWidget(
          capturedImage: _capturedImage,
          selectedItems: _selectedItems,
          captureMethod: _captureMethod,
          onConfirm: _onOutfitConfirmed,
          onRetake: () {
            setState(() {
              _currentStep = 1;
              _capturedImage = null;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build method selection screen
  Widget _buildMethodSelection(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 2.h),
            Text(
              localizations.howToLogOutfit,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              localizations.captureMethodSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMethodCard(
                    theme: theme,
                    icon: 'camera_alt',
                    title: localizations.takePhoto,
                    description: localizations.takePhotoSubtitle,
                    onTap: () => _selectCaptureMethod('camera'),
                  ),
                  SizedBox(height: 3.h),
                  _buildMethodCard(
                    theme: theme,
                    icon: 'checkroom',
                    title: localizations.buildFromWardrobe,
                    description: localizations.buildFromWardrobeSubtitle,
                    onTap: () => _selectCaptureMethod('wardrobe'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build method selection card
  Widget _buildMethodCard({
    required ThemeData theme,
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: theme.colorScheme.primary,
                  size: 10.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _currentStep = 2;
        });
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.galleryPickError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
