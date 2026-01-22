import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/item_details_form.dart';
import './widgets/photo_capture_section.dart';
import './widgets/purchase_info_section.dart';

/// Add Clothing Item Screen
/// Captures new wardrobe pieces through streamlined mobile form optimized for quick entry
class AddClothingItem extends StatefulWidget {
  const AddClothingItem({Key? key}) : super(key: key);

  @override
  State<AddClothingItem> createState() => _AddClothingItemState();
}

class _AddClothingItemState extends State<AddClothingItem> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeController = TextEditingController();

  List<String> _capturedPhotos = [];
  String? _selectedCategory;
  DateTime? _purchaseDate;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Map<String, dynamic>? _aiAnalysisData;

  // Category options for clothing items
  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Activewear',
    'Sleepwear',
  ];

  @override
  void initState() {
    super.initState();
    _itemNameController.addListener(_onFormChanged);
    _brandController.addListener(_onFormChanged);
    _priceController.addListener(_onFormChanged);
    _storeController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _onPhotosChanged(List<String> photos) {
    setState(() {
      _capturedPhotos = photos;
      _hasUnsavedChanges = true;
    });
  }

  void _onAIAnalysisComplete(Map<String, dynamic> analysisResult) {
    setState(() {
      _aiAnalysisData = analysisResult;

      // Auto-populate category from AI analysis
      final aiCategory = analysisResult['category'] as String?;
      if (aiCategory != null && _categories.contains(aiCategory)) {
        _selectedCategory = aiCategory;
      }

      // Auto-populate item name if empty
      if (_itemNameController.text.trim().isEmpty) {
        final color = analysisResult['color'] as String? ?? '';
        final material = analysisResult['material'] as String? ?? '';
        final category = analysisResult['category'] as String? ?? 'Item';
        _itemNameController.text = '$color $material $category';
      }

      _hasUnsavedChanges = true;
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
      _hasUnsavedChanges = true;
    });
  }

  void _onPurchaseDateChanged(DateTime? date) {
    setState(() {
      _purchaseDate = date;
      _hasUnsavedChanges = true;
    });
  }

  bool _isFormValid() {
    return _itemNameController.text.trim().isNotEmpty &&
        _selectedCategory != null;
  }

  Future<void> _saveItem() async {
    if (!_isFormValid()) return;

    setState(() => _isSaving = true);

    try {
      // Simulate saving to local storage/database
      await Future.delayed(const Duration(seconds: 1));

      // Create item data structure with AI tags
      final itemData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _itemNameController.text.trim(),
        'category': _selectedCategory,
        'brand': _brandController.text.trim(),
        'price': _priceController.text.trim(),
        'purchaseDate': _purchaseDate?.toIso8601String(),
        'store': _storeController.text.trim(),
        'photos': _capturedPhotos,
        'createdAt': DateTime.now().toIso8601String(),
        'wearCount': 0,
        'costPerWear': _priceController.text.trim().isNotEmpty
            ? double.tryParse(_priceController.text.trim())
            : null,
        // AI-generated metadata
        'aiTags': _aiAnalysisData?['tags'] ?? [],
        'color': _aiAnalysisData?['color'],
        'material': _aiAnalysisData?['material'],
        'style_vibe': _aiAnalysisData?['style_vibe'],
        'aiConfidence': _aiAnalysisData?['confidence'],
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_itemNameController.text} added to wardrobe'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to wardrobe management
        Navigator.of(context, rootNavigator: true).pop(itemData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save item. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Add Clothing Item'),
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            },
            tooltip: 'Cancel',
          ),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: TextButton(
                onPressed: _isFormValid() && !_isSaving ? _saveItem : null,
                style: TextButton.styleFrom(
                  foregroundColor: _isFormValid() && !_isSaving
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Photo capture section with AI analysis
              PhotoCaptureSection(
                photos: _capturedPhotos,
                onPhotosChanged: _onPhotosChanged,
                onAIAnalysisComplete: _onAIAnalysisComplete,
              ),

              SizedBox(height: 2.h),

              // Item details form
              ItemDetailsForm(
                itemNameController: _itemNameController,
                brandController: _brandController,
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategoryChanged: _onCategoryChanged,
              ),

              SizedBox(height: 2.h),

              // Purchase information section
              PurchaseInfoSection(
                priceController: _priceController,
                storeController: _storeController,
                purchaseDate: _purchaseDate,
                onPurchaseDateChanged: _onPurchaseDateChanged,
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
