import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/purchase_service.dart';
import './widgets/monthly_summary_widget.dart';
import './widgets/purchase_card_widget.dart';
import './widgets/filter_controls_widget.dart';
import './widgets/spending_chart_widget.dart';
import './widgets/add_purchase_dialog.dart';

class PurchaseTracking extends StatefulWidget {
  const PurchaseTracking({Key? key}) : super(key: key);

  @override
  State<PurchaseTracking> createState() => _PurchaseTrackingState();
}

class _PurchaseTrackingState extends State<PurchaseTracking> {
  final PurchaseService _purchaseService = PurchaseService();

  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;
  String _selectedBrand = 'All';

  List<Map<String, dynamic>> _purchases = [];
  List<String> _brands = ['All'];
  Map<String, dynamic> _monthlyStats = {'totalSpent': 0.0, 'purchaseCount': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPurchases(), _loadMonthlyStats(), _loadBrands()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPurchases() async {
    final purchases = await _purchaseService.fetchPurchases(
      category: _selectedFilter == 'All' ? null : _selectedFilter,
      brand: _selectedBrand == 'All' ? null : _selectedBrand,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    if (mounted) setState(() => _purchases = purchases);
  }

  Future<void> _loadMonthlyStats() async {
    final stats = await _purchaseService.fetchMonthlyStats(DateTime.now());
    if (mounted) setState(() => _monthlyStats = stats);
  }

  Future<void> _loadBrands() async {
    final brands = await _purchaseService.fetchBrands();
    if (mounted) setState(() => _brands = ['All', ...brands]);
  }

  /// Convert Supabase snake_case to camelCase for widgets
  Map<String, dynamic> _formatPurchase(Map<String, dynamic> p) {
    final price = (p['price'] as num).toDouble();
    // CPW not tracked yet - show price as CPW placeholder
    return {
      'id': p['id'],
      'name': p['name'] ?? '',
      'brand': p['brand'] ?? '',
      'price': price,
      'purchaseDate': p['purchase_date'] != null
          ? DateTime.parse(p['purchase_date'])
          : DateTime.now(),
      'wearCount': 0,
      'image': p['image_url'] ?? '',
      'semanticLabel': p['name'] ?? 'Purchase item',
      'category': p['category'] ?? '',
      'notes': p['notes'] ?? '',
    };
  }

  double get _averageCostPerWear {
    if (_purchases.isEmpty) return 0.0;
    final total = _purchases.fold(
        0.0, (sum, p) => sum + (p['price'] as num).toDouble());
    return total / _purchases.length;
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadPurchases();
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() => _dateRange = range);
    _loadPurchases();
  }

  void _onBrandChanged(String brand) {
    setState(() => _selectedBrand = brand);
    _loadPurchases();
  }

  void _showAddPurchaseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPurchaseDialog(
        onSave: (purchaseData) async {
          Navigator.pop(context);
          final result = await _purchaseService.addPurchase(
            name: purchaseData['name'],
            price: purchaseData['price'],
            purchaseDate: purchaseData['purchaseDate'],
            brand: purchaseData['brand'],
            category: purchaseData['category'],
            notes: purchaseData['notes'],
          );
          if (!mounted) return;
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${purchaseData['name']} added!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save purchase'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
            onPressed: () async {
              Navigator.pop(context);
              final success = await _purchaseService.deletePurchase(id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purchase deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadData();
              }
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
    final formattedPurchases = _purchases.map(_formatPurchase).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Purchase Tracking',
        variant: CustomAppBarVariant.standard,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            MonthlySummaryWidget(
              totalSpent: (_monthlyStats['totalSpent'] as num).toDouble(),
              purchaseCount: _monthlyStats['purchaseCount'] as int,
              averageCostPerWear: _averageCostPerWear,
            ),
            FilterControlsWidget(
              selectedFilter: _selectedFilter,
              selectedBrand: _selectedBrand,
              dateRange: _dateRange,
              availableBrands: _brands,
              onFilterChanged: _onFilterChanged,
              onBrandChanged: _onBrandChanged,
              onDateRangeChanged: _onDateRangeChanged,
            ),
            SpendingChartWidget(purchases: formattedPurchases),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : formattedPurchases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No purchases yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Tap + to log your first purchase',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
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
                          itemCount: formattedPurchases.length,
                          itemBuilder: (context, index) {
                            final purchase = formattedPurchases[index];
                            return PurchaseCardWidget(
                              purchase: purchase,
                              onDelete: () => _deletePurchase(purchase['id']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPurchaseDialog,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }
}
