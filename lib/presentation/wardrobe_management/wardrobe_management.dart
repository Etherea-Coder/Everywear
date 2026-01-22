import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/user_tier_service.dart';
import '../../services/wardrobe_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/category_filter_chip_widget.dart';
import './widgets/empty_wardrobe_widget.dart';
import './widgets/wardrobe_item_card_widget.dart';

/// Wardrobe Management Screen - Tab navigation content widget
/// Displays clothing items with real-time synchronization across devices
class WardrobeManagement extends StatefulWidget {
  const WardrobeManagement({Key? key}) : super(key: key);

  @override
  State<WardrobeManagement> createState() => _WardrobeManagementState();
}

class _WardrobeManagementState extends State<WardrobeManagement> {
  final TextEditingController _searchController = TextEditingController();
  final WardrobeService _wardrobeService = WardrobeService();
  final UserTierService _tierService = UserTierService();

  String _selectedCategory = 'All';
  bool _isMultiSelectMode = false;
  final Set<String> _selectedItems = {};
  List<Map<String, dynamic>> _wardrobeItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  RealtimeChannel? _realtimeChannel;

  Map<String, dynamic>? _tierInfo;

  final List<String> _categories = [
    'All',
    'Tops',
    'Bottoms',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_loadWardrobeItems);
    _loadWardrobeItems();
    _loadTierInfo();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Sets up real-time subscription for wardrobe changes
  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = _wardrobeService.subscribeToWardrobeChanges(
        onInsert: (payload) {
          if (!mounted) return;
          final newItem = payload.newRecord;
          setState(() {
            _wardrobeItems.insert(0, newItem);
          });
          _showSnackBar('New item added to wardrobe');
        },
        onUpdate: (payload) {
          if (!mounted) return;
          final updatedItem = payload.newRecord;
          setState(() {
            final index = _wardrobeItems.indexWhere(
              (item) => item['id'] == updatedItem['id'],
            );
            if (index != -1) {
              _wardrobeItems[index] = updatedItem;
            }
          });
          _showSnackBar('Item updated');
        },
        onDelete: (payload) {
          if (!mounted) return;
          final deletedRecord = payload.oldRecord;
          final deletedId = deletedRecord['id'] as String;
          setState(() {
            _wardrobeItems.removeWhere((item) => item['id'] == deletedId);
          });
          _showSnackBar('Item deleted from wardrobe');
        },
      );
    } catch (error) {
      debugPrint('Failed to setup real-time subscription: $error');
    }
  }

  /// Loads wardrobe items from database
  Future<void> _loadWardrobeItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _wardrobeService.fetchWardrobeItems(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchController.text.isEmpty
            ? null
            : _searchController.text,
      );

      if (!mounted) return;
      setState(() {
        _wardrobeItems = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTierInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final info = await _tierService.getUserTierInfo(user.id);
      if (mounted) {
        setState(() {
          _tierInfo = info;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadWardrobeItems();
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _handleItemTap(Map<String, dynamic> item) {
    if (_isMultiSelectMode) {
      _toggleItemSelection(item['id'] as String);
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed('/add-clothing-item', arguments: item);
    }
  }

  void _handleItemLongPress(String itemId) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedItems.add(itemId);
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadWardrobeItems();
  }

  void _showDeleteConfirmation(String itemId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to delete this item from your wardrobe?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(itemId);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _wardrobeService.deleteWardrobeItem(itemId);
      _showSnackBar('Item deleted successfully');
    } catch (error) {
      _showSnackBar('Failed to delete item: $error', isError: true);
    }
  }

  void _handleBatchDelete() {
    if (_selectedItems.isEmpty) return;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Items', style: theme.textTheme.titleLarge),
        content: Text(
          'Delete ${_selectedItems.length} selected items?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBatchItems();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBatchItems() async {
    try {
      await _wardrobeService.deleteMultipleItems(_selectedItems.toList());
      setState(() {
        _selectedItems.clear();
        _isMultiSelectMode = false;
      });
      _showSnackBar('Items deleted successfully');
    } catch (error) {
      _showSnackBar('Failed to delete items: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Wardrobe',
        actions: [
          if (_tierInfo != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _tierInfo!['tier'] == 'premium'
                        ? Colors.amber.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${_tierInfo!['items_count']}/${_tierInfo!['items_limit']} items',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          (_tierInfo!['items_count'] as int) >=
                              (_tierInfo!['items_limit'] as int)
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Custom AppBar content
          Container(
            color: theme.appBarTheme.backgroundColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Wardrobe',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        // Real-time sync indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'sync',
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Live',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        if (_isMultiSelectMode) ...[
                          IconButton(
                            onPressed: _handleBatchDelete,
                            icon: CustomIconWidget(
                              iconName: 'delete',
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            tooltip: 'Delete selected',
                          ),
                          IconButton(
                            onPressed: _toggleMultiSelect,
                            icon: CustomIconWidget(
                              iconName: 'close',
                              color: theme.colorScheme.onSurface,
                              size: 24,
                            ),
                            tooltip: 'Cancel selection',
                          ),
                        ] else
                          IconButton(
                            onPressed: () {},
                            icon: CustomIconWidget(
                              iconName: 'filter_list',
                              color: theme.colorScheme.onSurface,
                              size: 24,
                            ),
                            tooltip: 'Filter options',
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or brand',
                        prefixIcon: CustomIconWidget(
                          iconName: 'search',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
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
                ),
              ),
            ),
          ),
          // Category filter chips
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  return CategoryFilterChipWidget(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onSelected: () => _onCategorySelected(category),
                  );
                }).toList(),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 2.h),
                        Text(
                          'Loading wardrobe...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'error_outline',
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Failed to load wardrobe',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: _loadWardrobeItems,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _wardrobeItems.isEmpty
                ? EmptyWardrobeWidget(
                    hasSearchQuery: _searchController.text.isNotEmpty,
                    onAddItem: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed('/add-clothing-item');
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: GridView.builder(
                      padding: EdgeInsets.all(4.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2,
                        crossAxisSpacing: 3.w,
                        mainAxisSpacing: 2.h,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _wardrobeItems.length,
                      itemBuilder: (context, index) {
                        final item = _wardrobeItems[index];
                        final isSelected = _selectedItems.contains(item['id']);
                        return WardrobeItemCardWidget(
                          item: item,
                          isSelected: isSelected,
                          isMultiSelectMode: _isMultiSelectMode,
                          onTap: () => _handleItemTap(item),
                          onLongPress: () =>
                              _handleItemLongPress(item['id'] as String),
                          onDelete: () =>
                              _showDeleteConfirmation(item['id'] as String),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}