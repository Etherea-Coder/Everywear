import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/monthly_summary_widget.dart';
import './widgets/purchase_card_widget.dart';
import './widgets/filter_controls_widget.dart';
import './widgets/spending_chart_widget.dart';
import './widgets/add_purchase_dialog.dart';

/// Purchase Tracking Screen
/// Enables comprehensive clothing purchase logging and spending analysis
class PurchaseTracking extends StatefulWidget {
  const PurchaseTracking({Key? key}) : super(key: key);

  @override
  State<PurchaseTracking> createState() => _PurchaseTrackingState();
}

class _PurchaseTrackingState extends State<PurchaseTracking> {
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;
  String _selectedBrand = 'All';

  // Mock purchase data
  final List<Map<String, dynamic>> _purchases = [
    {
      'id': '1',
      'name': 'Linen Shirt',
      'brand': 'Everlane',
      'price': 68.0,
      'purchaseDate': DateTime(2024, 12, 15),
      'wearCount': 12,
      'image':
          'https://images.unsplash.com/photo-1687226425801-9f6b8ad0c719',
      'semanticLabel': 'White linen button-up shirt on wooden hanger',
      'category': 'Tops',
    },
    {
      'id': '2',
      'name': 'Denim Jeans',
      'brand': 'Levi\'s',
      'price': 89.0,
      'purchaseDate': DateTime(2024, 11, 28),
      'wearCount': 18,
      'image':
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400',
      'semanticLabel': 'Blue denim jeans folded on white surface',
      'category': 'Bottoms',
    },
    {
      'id': '3',
      'name': 'Wool Coat',
      'brand': 'J.Crew',
      'price': 245.0,
      'purchaseDate': DateTime(2024, 10, 5),
      'wearCount': 8,
      'image':
          'https://images.unsplash.com/photo-1702190650252-69c13d08ad8d',
      'semanticLabel': 'Camel wool coat hanging on rack',
      'category': 'Outerwear',
    },
    {
      'id': '4',
      'name': 'Sneakers',
      'brand': 'Allbirds',
      'price': 98.0,
      'purchaseDate': DateTime(2024, 9, 12),
      'wearCount': 45,
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_16b89617c-1766885482133.png',
      'semanticLabel': 'White minimalist sneakers on gray background',
      'category': 'Shoes',
    },
    {
      'id': '5',
      'name': 'Silk Blouse',
      'brand': 'Reformation',
      'price': 128.0,
      'purchaseDate': DateTime(2024, 8, 20),
      'wearCount': 6,
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_152019ad7-1767857908873.png',
      'semanticLabel': 'Cream silk blouse with delicate draping',
      'category': 'Tops',
    },
  ];

  double get _totalSpent {
    return _filteredPurchases.fold(0.0, (sum, item) => sum + item['price']);
  }

  double get _averageCostPerWear {
    final items = _filteredPurchases.where((p) => p['wearCount'] > 0).toList();
    if (items.isEmpty) return 0.0;
    final totalCPW = items.fold(
      0.0,
      (sum, item) => sum + (item['price'] / item['wearCount']),
    );
    return totalCPW / items.length;
  }

  List<Map<String, dynamic>> get _filteredPurchases {
    return _purchases.where((purchase) {
      // Filter by brand
      if (_selectedBrand != 'All' && purchase['brand'] != _selectedBrand) {
        return false;
      }

      // Filter by date range
      if (_dateRange != null) {
        final purchaseDate = purchase['purchaseDate'] as DateTime;
        if (purchaseDate.isBefore(_dateRange!.start) ||
            purchaseDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() => _dateRange = range);
  }

  void _onBrandChanged(String brand) {
    setState(() => _selectedBrand = brand);
  }

  void _showAddPurchaseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPurchaseDialog(
        onSave: (purchaseData) {
          setState(() {
            _purchases.insert(0, {
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              ...purchaseData,
              'wearCount': 0,
            });
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${purchaseData['name']} added to purchases'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _deletePurchase(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase'),
        content: const Text('Are you sure you want to delete this purchase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _purchases.removeWhere((p) => p['id'] == id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Purchase Tracking',
        variant: CustomAppBarVariant.standard,
      ),
      body: Column(
        children: [
          // Monthly summary header
          MonthlySummaryWidget(
            totalSpent: _totalSpent,
            purchaseCount: _filteredPurchases.length,
            averageCostPerWear: _averageCostPerWear,
          ),

          // Filter controls
          FilterControlsWidget(
            selectedFilter: _selectedFilter,
            selectedBrand: _selectedBrand,
            dateRange: _dateRange,
            availableBrands: [
              'All',
              ...{..._purchases.map((p) => p['brand'] as String)},
            ],
            onFilterChanged: _onFilterChanged,
            onBrandChanged: _onBrandChanged,
            onDateRangeChanged: _onDateRangeChanged,
          ),

          // Spending chart section
          SpendingChartWidget(purchases: _filteredPurchases),

          // Purchase list
          Expanded(
            child: _filteredPurchases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No purchases yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Tap + to log your first purchase',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: _filteredPurchases.length,
                    itemBuilder: (context, index) {
                      final purchase = _filteredPurchases[index];
                      return PurchaseCardWidget(
                        purchase: purchase,
                        onDelete: () => _deletePurchase(purchase['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPurchaseDialog,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }
}
