import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedItemIds = {};

  // Mock wardrobe data
  final List<Map<String, dynamic>> _wardrobeItems = [
    {
      "id": "top_1",
      "category": "Tops",
      "name": "White Cotton T-Shirt",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d49fa61f-1766582359298.png",
      "semanticLabel":
          "White cotton crew neck t-shirt laid flat on neutral background",
      "color": "White",
      "brand": "Everlane",
      "price": 30.0,
      "wearCount": 15,
    },
    {
      "id": "top_2",
      "category": "Tops",
      "name": "Navy Sweater",
      "image":
          "https://images.unsplash.com/photo-1670080589800-6416c8ce8a14",
      "semanticLabel":
          "Navy blue knit sweater with ribbed texture on white background",
      "color": "Navy",
      "brand": "Uniqlo",
      "price": 80.0,
      "wearCount": 4,
    },
    {
      "id": "top_3",
      "category": "Tops",
      "name": "Black Turtleneck",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_151c1c2d5-1765986465525.png",
      "semanticLabel":
          "Black turtleneck sweater folded neatly on light surface",
      "color": "Black",
      "brand": "COS",
      "price": 95.0,
      "wearCount": 2,
    },
    {
      "id": "bottom_1",
      "category": "Bottoms",
      "name": "Blue Jeans",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_10022c057-1767737640248.png",
      "semanticLabel":
          "Medium wash blue denim jeans laid flat showing front view",
      "color": "Blue",
      "brand": "Levi's",
      "price": 110.0,
      "wearCount": 22,
    },
    {
      "id": "bottom_2",
      "category": "Bottoms",
      "name": "Black Trousers",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1be7e67a4-1766999382260.png",
      "semanticLabel":
          "Black tailored trousers with pressed crease on neutral background",
      "color": "Black",
      "brand": "Zara",
      "price": 60.0,
      "wearCount": 8,
    },
    {
      "id": "bottom_3",
      "category": "Bottoms",
      "name": "Khaki Chinos",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_16c23660c-1764658181737.png",
      "semanticLabel":
          "Khaki colored chino pants folded showing fabric texture",
      "color": "Khaki",
      "brand": "Gap",
      "price": 45.0,
      "wearCount": 12,
    },
    {
      "id": "shoe_1",
      "category": "Shoes",
      "name": "White Sneakers",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_13ef60586-1767723958930.png",
      "semanticLabel":
          "White leather sneakers with minimal design on clean background",
      "color": "White",
      "brand": "Adidas",
      "price": 90.0,
      "wearCount": 30,
    },
    {
      "id": "shoe_2",
      "category": "Shoes",
      "name": "Brown Boots",
      "image":
          "https://images.unsplash.com/photo-1595388710140-e7b90300ec73",
      "semanticLabel": "Brown leather ankle boots with laces on wooden surface",
      "color": "Brown",
      "brand": "Clarks",
      "price": 140.0,
      "wearCount": 5,
    },
    {
      "id": "accessory_1",
      "category": "Accessories",
      "name": "Leather Belt",
      "image":
          "https://images.unsplash.com/photo-1719006289912-ee23ba74e315",
      "semanticLabel":
          "Brown leather belt with silver buckle coiled on white background",
      "color": "Brown",
      "brand": "Coach",
      "price": 120.0,
      "wearCount": 1,
    },
    {
      "id": "accessory_2",
      "category": "Accessories",
      "name": "Canvas Tote",
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_12e3fa5ba-1765572948306.png",
      "semanticLabel":
          "Natural canvas tote bag with leather handles on neutral surface",
      "color": "Beige",
      "brand": "Madewell",
      "price": 40.0,
      "wearCount": 6,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get filtered items by search query
  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _wardrobeItems;

    return _wardrobeItems.where((item) {
      final name = (item['name'] as String).toLowerCase();
      final category = (item['category'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  /// Get items by category
  Map<String, List<Map<String, dynamic>>> get _itemsByCategory {
    final Map<String, List<Map<String, dynamic>>> categorized = {};

    for (var item in _filteredItems) {
      final category = item['category'] as String;
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
        .where((item) => _selectedItemIds.contains(item['id']))
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
              final isSelected = _selectedItemIds.contains(item['id']);
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
    return GestureDetector(
      onTap: () => _toggleItemSelection(item['id'] as String),
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
                    tag: 'wardrobe_item_${item['id']}',
                    child: CustomImageWidget(
                      imageUrl: item['image'] as String,
                      width: 40.w,
                      height: 15.h,
                      fit: BoxFit.cover,
                      semanticLabel: item['semanticLabel'] as String,
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
                    item['name'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    item['brand'] as String,
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
    return Container(
      width: 20.w,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Hero(
        tag: 'wardrobe_item_chip_${item['id']}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(
            imageUrl: item['image'] as String,
            width: 20.w,
            height: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: item['semanticLabel'] as String,
          ),
        ),
      ),
    );
  }

  /// Build CPW badge
  Widget _buildCPWBadge(ThemeData theme, Map<String, dynamic> item) {
    final price = item['price'] as double? ?? 0.0;
    final wearCount = item['wearCount'] as int? ?? 1;
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
