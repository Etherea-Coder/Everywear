import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_localizations.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/purchase_service.dart';
import './widgets/spending_chart_widget.dart';
import './widgets/add_purchase_dialog.dart';

class PurchaseTracking extends StatefulWidget {
  const PurchaseTracking({Key? key}) : super(key: key);

  @override
  State<PurchaseTracking> createState() => _PurchaseTrackingState();
}

class _PurchaseTrackingState extends State<PurchaseTracking>
    with SingleTickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  late TabController _tabController;

  // Data
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _wishlist = [];
  List<Map<String, dynamic>> _cpwLeaderboard = [];
  Map<String, dynamic> _monthlyStats = {'totalSpent': 0.0, 'purchaseCount': 0};
  Map<String, dynamic> _budget = {'monthly_budget': 0.0, 'currency': 'EUR'};
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _purchaseService.fetchPurchases(),
      _purchaseService.fetchMonthlyStats(DateTime.now()),
      _purchaseService.fetchBudget(),
      _purchaseService.fetchWishlist(),
      _purchaseService.fetchCPWLeaderboard(),
      _purchaseService.fetchCategorySpending(),
    ]);
    if (mounted) {
      setState(() {
        _purchases = results[0] as List<Map<String, dynamic>>;
        _monthlyStats = results[1] as Map<String, dynamic>;
        _budget = results[2] as Map<String, dynamic>;
        _wishlist = results[3] as List<Map<String, dynamic>>;
        _cpwLeaderboard = results[4] as List<Map<String, dynamic>>;
        _categorySpending = results[5] as Map<String, double>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Purchases',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showBudgetDialog,
            tooltip: 'Wardrobe budget',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBudgetBar(theme),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Purchases'),
                    Tab(text: 'Wishlist'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildPurchasesTab(theme),
                      _buildWishlistTab(theme),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 2) {
            _showAddWishlistDialog();
          } else {
            _showAddPurchaseDialog();
          }
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  // ── BUDGET BAR ───────────────────────────────────────────
  Widget _buildBudgetBar(ThemeData theme) {
    final budget = (_budget['monthly_budget'] as num?)?.toDouble() ?? 0.0;
    final spent = (_monthlyStats['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final currency = _budget['currency'] as String? ?? 'EUR';

    if (budget <= 0) return const SizedBox.shrink();

    final progress = (spent / budget).clamp(0.0, 1.0);
    final isOver = spent > budget;
    final color = isOver
        ? theme.colorScheme.error
        : progress > 0.8
            ? Colors.orange
            : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOver ? 'Wardrobe budget exceeded' : 'Wardrobe investment this month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$currency ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB ─────────────────────────────────────────
  Widget _buildOverviewTab(ThemeData theme) {
    final totalSpent = (_monthlyStats['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final purchaseCount = _monthlyStats['purchaseCount'] as int? ?? 0;
    final currency = _budget['currency'] as String? ?? 'EUR';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 15.h),
        children: [
          _buildHeroInsightCard(theme, currency),
          SizedBox(height: 2.h),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: '💸',
                  label: 'Wardrobe Investment',
                  value: '$currency ${totalSpent.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: '🛍',
                  label: 'Items Added',
                  value: purchaseCount.toString(),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Chart — only show if there are purchases
          if (_purchases.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Spending Rhythm', Icons.show_chart),
            SizedBox(height: 0.5.h),
            Text(
              'A quick view of how your wardrobe spending evolved this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            SpendingChartWidget(
              purchases: _purchases
                  .map((p) => {
                        'purchaseDate': p['purchase_date'] != null
                            ? DateTime.parse(p['purchase_date'])
                            : DateTime.now(),
                        'price': (p['price'] as num).toDouble(),
                      })
                  .toList(),
            ),
            SizedBox(height: 2.h),
          ],

          if (_categorySpending.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Where You Invest Most', Icons.pie_chart),
            SizedBox(height: 0.5.h),
            Text(
              'See which categories are shaping your wardrobe the most',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            _buildCategoryBreakdown(theme, currency),
            SizedBox(height: 2.h),
          ],

          if (_cpwLeaderboard.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Top Picks This Month', Icons.emoji_events),
            SizedBox(height: 0.5.h),
            Text(
              'Your smartest purchases so far, ranked by value per wear',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            ..._cpwLeaderboard.take(5).toList().asMap().entries.map((entry) {
              return _buildCPWCard(theme, entry.value, currency, rank: entry.key + 1);
            }),
          ],

          if (_cpwLeaderboard.isEmpty && _categorySpending.isEmpty)
            _buildEmptyState(
              theme,
              icon: Icons.analytics_outlined,
              title: 'No wardrobe insights yet',
              subtitle: 'Add purchases to unlock smarter shopping insights',
            ),
        ],
      ),
    );
  }

  Widget _buildHeroInsightCard(ThemeData theme, String currency) {
    final bestItem = _cpwLeaderboard.isNotEmpty ? _cpwLeaderboard.first : null;
    final totalSpent = (_monthlyStats['totalSpent'] as num?)?.toDouble() ?? 0.0;
    final purchaseCount = _monthlyStats['purchaseCount'] as int? ?? 0;

    String title = 'Wardrobe Intelligence';
    String subtitle = 'Track what you buy, what pays off, and what is truly worth it.';
    String badge = 'This month';

    if (bestItem != null) {
      final cpw = (bestItem['cpw'] as num).toDouble();
      title = 'Smartest Purchase So Far';
      subtitle =
          '${bestItem['name']} is currently your best-value item at $currency ${cpw.toStringAsFixed(2)} per wear.';
      badge = 'Top value';
    } else if (purchaseCount > 0) {
      title = 'Your Wardrobe Is Taking Shape';
      subtitle =
          'You added $purchaseCount pieces this month for a total of $currency ${totalSpent.toStringAsFixed(0)}.';
      badge = 'In progress';
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, String currency) {
    final total = _categorySpending.values.fold(0.0, (a, b) => a + b);
    final colors = [
      theme.colorScheme.primary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    int colorIndex = 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _categorySpending.entries.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = colors[colorIndex++ % colors.length];
          return Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text(
                      '$currency ${entry.value.toStringAsFixed(0)} · ${(pct * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCPWCard(
    ThemeData theme,
    Map<String, dynamic> item,
    String currency, {
    int? rank,
  }) {
    final cpw = (item['cpw'] as num).toDouble();
    final wearCount = item['wearCount'] as int;
    final price = (item['price'] as num).toDouble();
    final isGoodValue = cpw < 10;

    Color accentColor;
    String tagLabel;

    if (rank == 1) {
      accentColor = Colors.amber.shade700;
      tagLabel = 'Best value';
    } else if (rank == 2) {
      accentColor = Colors.blueGrey;
      tagLabel = 'Strong pick';
    } else {
      accentColor = isGoodValue ? Colors.green : theme.colorScheme.primary;
      tagLabel = isGoodValue ? 'Worth it' : 'Good potential';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 11.w,
                height: 11.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(item['category']),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rank != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 0.6.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rank == 1 ? 'Top pick' : '#$rank',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      item['name'] as String,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$currency ${price.toStringAsFixed(0)} · worn $wearCount times',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${cpw.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    'per wear',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.4.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tagLabel,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'tops': return '👕';
      case 'bottoms': return '👖';
      case 'shoes': return '👟';
      case 'outerwear': return '🧥';
      case 'accessories': return '👜';
      case 'dresses': return '👗';
      case 'activewear': return '🏃';
      default: return '👗';
    }
  }

  // ── PURCHASES TAB ────────────────────────────────────────
  Widget _buildPurchasesTab(ThemeData theme) {
    if (_purchases.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.shopping_bag_outlined,
        title: 'No purchases yet',
        subtitle: 'Start tracking the pieces you bring into your wardrobe',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 15.h),
        itemCount: _purchases.length,
        itemBuilder: (context, index) => _buildPurchaseCard(theme, _purchases[index]),
      ),
    );
  }

  Widget _buildPurchaseCard(ThemeData theme, Map<String, dynamic> p) {
    final price = (p['price'] as num).toDouble();
    final currency = _budget['currency'] as String? ?? 'EUR';
    final date = p['purchase_date'] != null
        ? DateTime.parse(p['purchase_date'])
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getCategoryEmoji(p['category']),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'] as String? ?? '',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if ((p['brand'] as String? ?? '').isNotEmpty)
                  Text(
                    p['brand'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currency ${price.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 0.5.h),
              GestureDetector(
                onTap: () => _deletePurchase(p['id']),
                child: Icon(Icons.delete_outline,
                    size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── WISHLIST TAB ─────────────────────────────────────────
  Widget _buildWishlistTab(ThemeData theme) {
    if (_wishlist.isEmpty) {
      return _buildEmptyState(
        theme,
        icon: Icons.favorite_border,
        title: 'Your style wishlist is empty',
        subtitle: 'Save the pieces you are considering for your wardrobe',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 15.h),
        itemCount: _wishlist.length,
        itemBuilder: (context, index) =>
            _buildWishlistCard(theme, _wishlist[index]),
      ),
    );
  }

  Widget _buildWishlistCard(ThemeData theme, Map<String, dynamic> item) {
    final currentPrice = (item['current_price'] as num?)?.toDouble();
    final targetPrice = (item['target_price'] as num?)?.toDouble();
    final currency = _budget['currency'] as String? ?? 'EUR';
    final isAtTarget = currentPrice != null &&
        targetPrice != null &&
        currentPrice <= targetPrice;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isAtTarget
            ? Border.all(color: Colors.green.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 13.w,
                height: 13.w,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCategoryEmoji(item['category']),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if ((item['brand'] as String? ?? '').isNotEmpty)
                      Text(
                        item['brand'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isAtTarget)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ready to buy',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (currentPrice != null || targetPrice != null) ...[
            SizedBox(height: 1.5.h),
            Row(
              children: [
                if (currentPrice != null)
                  _buildPriceChip(theme,
                      label: 'Current',
                      value: '$currency ${currentPrice.toStringAsFixed(2)}',
                      color: theme.colorScheme.primary),
                if (currentPrice != null && targetPrice != null)
                  SizedBox(width: 2.w),
                if (targetPrice != null)
                  _buildPriceChip(theme,
                      label: 'Target',
                      value: '$currency ${targetPrice.toStringAsFixed(2)}',
                      color: Colors.orange),
              ],
            ),
          ],
          if ((item['notes'] as String? ?? '').isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              item['notes'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateWishlistPrice(item),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(AppLocalizations.of(context).updatePrice),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _markWishlistPurchased(item),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(AppLocalizations.of(context).boughtIt),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: () => _deleteWishlistItem(item['id']),
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(ThemeData theme,
      {required String label, required String value, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────
  Widget _buildStatCard(ThemeData theme,
      {required String icon, required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          SizedBox(height: 1.h),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        SizedBox(width: 2.w),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme,
      {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            SizedBox(height: 2.h),
            Text(title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
            SizedBox(height: 1.h),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────
  void _showBudgetDialog() {
    final controller = TextEditingController(
      text: ((_budget['monthly_budget'] as num?)?.toDouble() ?? 0.0) > 0
          ? (_budget['monthly_budget'] as num).toStringAsFixed(0)
          : '',
    );
    String currency = _budget['currency'] as String? ?? 'EUR';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).monthlyBudget),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget amount',
                  prefixText: '$currency ',
                ),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['EUR', 'USD', 'GBP', 'CAD', 'AUD']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => currency = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                Navigator.pop(context);
                await _purchaseService.saveBudget(
                    monthlyBudget: amount, currency: currency);
                _loadData();
              },
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      ),
    );
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${purchaseData['name']} ${AppLocalizations.of(context).addedToWardrobeLog}'),
              behavior: SnackBarBehavior.floating,
            ));
            _loadData();
          }
        },
      ),
    );
  }

  void _showAddWishlistDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final currentPriceController = TextEditingController();
    final targetPriceController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedCategory;
    final categories = [
      'Tops', 'Bottoms', 'Shoes', 'Outerwear',
      'Accessories', 'Dresses', 'Activewear'
    ];
    final currency = _budget['currency'] as String? ?? 'EUR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(AppLocalizations.of(context).addToWishlist,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  SizedBox(height: 2.h),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item name *',
                      prefixIcon: Icon(Icons.favorite_border),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand (optional)',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCategory = v),
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: currentPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Current price',
                            prefixText: '$currency ',
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: TextField(
                          controller: targetPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Target price',
                            prefixText: '$currency ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        await _purchaseService.addWishlistItem(
                          name: nameController.text.trim(),
                          brand: brandController.text.trim().isNotEmpty
                              ? brandController.text.trim() : null,
                          category: selectedCategory,
                          currentPrice: double.tryParse(currentPriceController.text),
                          targetPrice: double.tryParse(targetPriceController.text),
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim() : null,
                        );
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context).addToWishlist),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateWishlistPrice(Map<String, dynamic> item) {
    final controller = TextEditingController(
      text: (item['current_price'] as num?)?.toStringAsFixed(2) ?? '',
    );
    final currency = _budget['currency'] as String? ?? 'EUR';
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context).updatePrice}: ${item['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: localizations.currentPrice, prefixText: '$currency '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel)),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price == null) return;
              Navigator.pop(context);
              await _purchaseService.updateWishlistPrice(item['id'], price);
              _loadData();
            },
            child: Text(AppLocalizations.of(context).updatePrice),
          ),
        ],
      ),
    );
  }

  void _markWishlistPurchased(Map<String, dynamic> item) {
    final controller = TextEditingController(
      text: (item['current_price'] as num?)?.toStringAsFixed(2) ?? '',
    );
    final currency = _budget['currency'] as String? ?? 'EUR';
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).markAsPurchased),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppLocalizations.of(context).howMuchDidYouPay} ${item['name']}?'),
            SizedBox(height: 2.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: localizations.finalPrice, prefixText: '$currency '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel)),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context);
              await _purchaseService.markWishlistItemPurchased(item['id'], price);
              await _purchaseService.addPurchase(
                name: item['name'],
                price: price,
                purchaseDate: DateTime.now(),
                brand: item['brand'],
                category: item['category'],
              );
              _loadData();
            },
            child: Text(AppLocalizations.of(context).confirmPurchase),
          ),
        ],
      ),
    );
  }

  void _deleteWishlistItem(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).removeFromWishlist),
        content: Text(AppLocalizations.of(context).removeFromWishlist),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _purchaseService.deleteWishlistItem(id);
              _loadData();
            },
            child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePurchase(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePurchase),
        content: Text(AppLocalizations.of(context).deletePurchase),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _purchaseService.deletePurchase(id);
              _loadData();
            },
            child: Text(AppLocalizations.of(context).delete,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}