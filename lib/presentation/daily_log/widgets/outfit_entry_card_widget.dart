import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OutfitEntryCardWidget extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRepeat;

  const OutfitEntryCardWidget({
    Key? key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onRepeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = entry['rating'] as int? ?? 0;
    final items = entry['items'] as List<dynamic>? ?? [];
    final notes = entry['notes'] as String? ?? '';
    final imageUrl = entry['imageUrl'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header (only if image exists)
          if (imageUrl.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16.0)),
                  child: CustomImageWidget(
                    imageUrl: imageUrl,
                    height: 25.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: entry['semanticLabel'] ?? AppLocalizations.of(context).outfitImageLabel,
                  ),
                ),
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      entry['time'] ?? '',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (rating > 0)
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Row(
                      children: List.generate(
                        rating,
                        (index) => const Icon(Icons.star,
                            color: Colors.amber, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          // Content
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time (if no image)
                if (imageUrl.isEmpty)
                  Text(
                    entry['time'] ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                // Occasion + actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, size: 18,
                            color: theme.colorScheme.primary),
                        SizedBox(width: 2.w),
                        Text(
                          entry['occasion'] ?? AppLocalizations.of(context).outfitLabel,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Repeat button
                        IconButton(
                          icon: const Icon(Icons.repeat, size: 20),
                          onPressed: onRepeat,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: AppLocalizations.of(context).repeatOutfitTooltip,
                        ),
                        SizedBox(width: 2.w),
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: AppLocalizations.of(context).editOutfitTooltip,
                        ),
                        SizedBox(width: 2.w),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: AppLocalizations.of(context).deleteOutfitTooltip,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                // Rating (if no image)
                if (imageUrl.isEmpty && rating > 0)
                  Row(
                    children: List.generate(
                      rating,
                      (index) => const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                    ),
                  ),
                SizedBox(height: 0.5.h),
                // Item image thumbnails
                if (items.isNotEmpty)
                  SizedBox(
                    height: 11.w,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(width: 2.w),
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        final imgUrl = item['imageUrl'] as String? ?? '';
                        final name = item['name'] as String? ?? '';
                        return Tooltip(
                          message: name,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imgUrl.isNotEmpty
                                ? Image.network(
                                    imgUrl,
                                    width: 11.w,
                                    height: 11.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _itemPlaceholder(theme, name),
                                  )
                                : _itemPlaceholder(theme, name),
                          ),
                        );
                      },
                    ),
                  ),
                // Notes
                if (notes.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(ThemeData theme, String name) {
    return Container(
      width: 11.w,
      height: 11.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
