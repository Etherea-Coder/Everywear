import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Item details form widget for clothing item information
/// Includes item name, category selection, and brand fields
class ItemDetailsForm extends StatelessWidget {
  final TextEditingController itemNameController;
  final TextEditingController brandController;
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  const ItemDetailsForm({
    Key? key,
    required this.itemNameController,
    required this.brandController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  // Category icons for visual selection
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tops':
        return Icons.checkroom;
      case 'Bottoms':
        return Icons.content_cut;
      case 'Dresses':
        return Icons.woman;
      case 'Outerwear':
        return Icons.ac_unit;
      case 'Shoes':
        return Icons.directions_walk;
      case 'Accessories':
        return Icons.watch;
      case 'Activewear':
        return Icons.fitness_center;
      case 'Sleepwear':
        return Icons.hotel;
      default:
        return Icons.checkroom;
    }
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
          Text(
            'Item Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Item name field
          TextFormField(
            controller: itemNameController,
            decoration: InputDecoration(
              labelText: 'Item Name *',
              hintText: 'e.g., Blue Denim Jacket',
              helperText: 'AI can auto-fill this based on your photo',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'checkroom',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an item name';
              }
              return null;
            },
          ),

          SizedBox(height: 2.h),

          // Category selection with icons
          Row(
            children: [
              Text(
                'Category *',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (selectedCategory != null) ...[
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'verified',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'AI detected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          
          // Icon-based category grid (Tier 1 enhancement)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 1.h,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category;
              return GestureDetector(
                onTap: () => onCategoryChanged(category),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 28.sp,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 2.h),

          // Brand field (optional)
          TextFormField(
            controller: brandController,
            decoration: InputDecoration(
              labelText: 'Brand (Optional)',
              hintText: 'e.g., Levi\'s',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'local_offer',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}