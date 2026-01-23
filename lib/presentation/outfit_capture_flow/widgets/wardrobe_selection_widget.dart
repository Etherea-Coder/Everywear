import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../services/wardrobe_service.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../core/utils/app_localizations.dart';

/// Wardrobe selection widget for building outfits from existing items
/// Implements categorized horizontal scrolling with multi-select interface
class WardrobeSelectionWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onItemsSelected;

  const WardrobeSelectionWidget({Key? key, required this.onItemsSelected})
      : super(key: key);

  @override
  State<WardrobeSelectionWidget> createState() =>
      _WardrobeSelectionWidgetState();
}

class _WardrobeSelectionWidgetState extends State<WardrobeSelectionWidget> {
  final WardrobeService _wardrobeService = WardrobeService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _wardrobeItems = [];
  Set<String> _selectedItemIds = {};
  String _searchQuery = '';
  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();
    _fetchProductionData();
  }

  Future<void> _fetchProductionData() async {
    try {
      final items = await _wardrobeService.fetchWardrobeItems();
      if (mounted) {
        setState(() {
          _wardrobeItems = items;
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get filtered items by search query
  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _wardrobeItems;

    return _wardrobeItems.where((item) {
      final name = (item['name']?.toString() ?? '').toLowerCase();
      final category = (item['category']?.toString() ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  /// Get items by category
  Map<String, List<Map<String, dynamic>>> get _itemsByCategory {
    final Map<String, List<Map<String, dynamic>>> categorized = {};

    for (var item in _filteredItems) {
      final category = item['category']?.toString() ?? 'Other';
      categorized.putIfAbsent(category, () => []);
      categorized[category]!.add(item);
    }

    return categorized;
  }

  /// Toggle item selection
  void _toggleItemSelection(String itemId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  /// Get selected items
  List<Map<String, dynamic>> get _selectedItems {
    return _wardrobeItems
        .where((item) => _selectedItemIds.contains(item['id']?.toString()))
        .toList();
  }

  /// Handle continue button
  void _handleContinue() {
    if (_selectedItems.isEmpty) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.selectAtLeastOneItem),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onItemsSelected(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(4.w),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: localizations.searchWardrobeHint,
              prefixIcon: CustomIconWidget(
                iconName: 'search',
                color: theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
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
        ),

        // Selected items preview
        if (_selectedItems.isNotEmpty)
          Container(
            height: 12.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedItems.length,
                    separatorBuilder: (_, __) => SizedBox(width: 2.w),
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return _buildSelectedItemChip(theme, item);
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${_selectedItems.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 2.h),

        // Category sections
        Expanded(
          child: _itemsByCategory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'search_off',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 15.w,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        localizations.noItemsFound,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: 2.h),
                  itemCount: _itemsByCategory.length,
                  separatorBuilder: (_, __) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final category = _itemsByCategory.keys.elementAt(index);
                    final items = _itemsByCategory[category]!;
                    return _buildCategorySection(theme, category, items);
                  },
                ),
        ),

        // Continue button
        Container(
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
              onPressed: _selectedItems.isEmpty ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 6.h),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.getContinueWithItemsLabel(_selectedItems.length),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _selectedItems.isEmpty
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build category section
  Widget _buildCategorySection(
    ThemeData theme,
    String category,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 25.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected =
                  _selectedItemIds.contains(item['id']?.toString());
              return _buildItemCard(theme, item, isSelected);
            },
          ),
        ),
      ],
    );
  }

  /// Build item card
  Widget _buildItemCard(
    ThemeData theme,
    Map<String, dynamic> item,
    bool isSelected,
  ) {
    final itemId = item['id']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _toggleItemSelection(itemId),
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Hero(
                    tag: 'wardrobe_item_$itemId',
                    child: CustomImageWidget(
                      imageUrl: (item['image_url'] ?? item['image'] ?? '')
                          as String,
                      width: 40.w,
                      height: 15.h,
                      fit: BoxFit.cover,
                      semanticLabel: (item['semantic_label'] ??
                          item['semanticLabel'] ??
                          '') as String,
                    ),
                  ),
                ),
                Positioned(
                  top: 2.w,
                  left: 2.w,
                  child: _buildCPWBadge(theme, item),
                ),
                if (isSelected)
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: theme.colorScheme.onPrimary,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Unnamed Item',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    item['brand']?.toString() ?? 'Unknown Brand',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build selected item chip
  Widget _buildSelectedItemChip(ThemeData theme, Map<String, dynamic> item) {
    final itemId = item['id']?.toString() ?? '';
    return Container(
      width: 20.w,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Hero(
        tag: 'wardrobe_item_chip_$itemId',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(
            imageUrl: (item['image_url'] ?? item['image'] ?? '') as String,
            width: 20.w,
            height: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: (item['semantic_label'] ??
                item['semanticLabel'] ??
                '') as String,
          ),
        ),
      ),
    );
  }

  /// Build CPW badge
  Widget _buildCPWBadge(ThemeData theme, Map<String, dynamic> item) {
    final price =
        (item['purchase_price'] ?? item['price'] as num?)?.toDouble() ?? 0.0;
    final wearCount = item['wearCount'] ?? item['wear_count'] as int? ?? 1;
    final cpw = wearCount > 0 ? price / wearCount : price;
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '\$${cpw.toStringAsFixed(2)}${localizations.perWear}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
