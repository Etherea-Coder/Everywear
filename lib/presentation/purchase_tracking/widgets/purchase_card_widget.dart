import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Purchase card widget with swipe actions and cost-per-wear display
class PurchaseCardWidget extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onDelete;

  const PurchaseCardWidget({
    Key? key,
    required this.purchase,
    required this.onDelete,
  }) : super(key: key);

  double get _costPerWear {
    final wearCount = purchase['wearCount'] as int;
    if (wearCount == 0) return purchase['price'];
    return purchase['price'] / wearCount;
  }

  Color _getCostPerWearColor(BuildContext context) {
    if (_costPerWear <= 5.0) return Colors.green;
    if (_costPerWear <= 15.0) return Colors.orange;
    return Colors.red;
  }

  String _getCostPerWearLabel() {
    if (_costPerWear <= 5.0) return 'Great Value';
    if (_costPerWear <= 15.0) return 'Moderate';
    return 'Poor Value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Slidable(
      key: ValueKey(purchase['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: CustomImageWidget(
                imageUrl: purchase['image'],
                width: 25.w,
                height: 25.w,
                fit: BoxFit.cover,
                semanticLabel: purchase['semanticLabel'],
              ),
            ),

            // Item details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      purchase['brand'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          dateFormat.format(purchase['purchaseDate']),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${purchase['price'].toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getCostPerWearColor(
                              context,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getCostPerWearColor(context),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CPW: \$${_costPerWear.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getCostPerWearColor(context),
                                ),
                              ),
                              Text(
                                _getCostPerWearLabel(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8.sp,
                                  color: _getCostPerWearColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
