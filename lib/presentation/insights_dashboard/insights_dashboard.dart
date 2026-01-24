import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/metric_card_widget.dart';
import './widgets/usage_chart_widget.dart';
import './widgets/cost_per_wear_chart_widget.dart';
import './widgets/sustainability_score_widget.dart';
import './widgets/ai_insight_card_widget.dart';
import '../../services/wardrobe_service.dart';

/// Insights Dashboard - AI-powered style analytics and wardrobe insights
/// Displays comprehensive analytics including usage patterns, cost-per-wear,
/// sustainability metrics, and personalized AI recommendations
class InsightsDashboard extends StatefulWidget {
  const InsightsDashboard({Key? key}) : super(key: key);

  @override
  State<InsightsDashboard> createState() => _InsightsDashboardState();
}

class _InsightsDashboardState extends State<InsightsDashboard> {
  int _selectedTimeRange = 0; // 0: Week, 1: Month, 2: Year
  bool _isLoading = true;
  final WardrobeService _wardrobeService = WardrobeService();

  // Mock analytics data
  Map<String, dynamic> _analyticsData = {
    'totalItems': 0,
    'favorite_items': 0,
    'outfitsLogged': 0,
    'avgCostPerWear': 0.0,
    'sustainabilityScore': 0,
    'wardrobeUtilization': 0,
    'topItems': [],
  };

  // AI-generated insights
  final List<Map<String, dynamic>> _aiInsights = [
    {
      'type': 'positive',
      'title': 'Great Wardrobe Utilization!',
      'description':
          'You\'re wearing 65% of your wardrobe regularly. This is above average and shows mindful consumption.',
      'icon': Icons.trending_up,
    },
    {
      'type': 'suggestion',
      'title': 'Optimize Your Dresses',
      'description':
          'You have 6 dresses but only wore them twice this month. Consider styling them differently or donating unused pieces.',
      'icon': Icons.lightbulb_outline,
    },
    {
      'type': 'achievement',
      'title': 'Sustainability Champion',
      'description':
          'Your cost-per-wear is decreasing! You\'ve saved \$45 this month by maximizing existing items.',
      'icon': Icons.eco,
    },
  ];

  String? _error;

  @override
  void initState() {
    super.initState();
    // _loadStats(); // DISABLED FOR DEBUGGING
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Added 5s timeout to prevent infinite white screen hang
      final stats = await _wardrobeService.getWardrobeStatistics()
          .timeout(const Duration(seconds: 5));
      final history = await _wardrobeService.fetchOutfitHistory(limit: 50)
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _analyticsData = {
            'totalItems': stats['total_items'],
            'favorite_items': stats['favorite_items'],
            'outfitsLogged': history.length,
            'avgCostPerWear': 12.50,
            'sustainabilityScore': 78,
            'wardrobeUtilization': (stats['total_items'] > 0) 
                ? (stats['favorite_items'] / stats['total_items'] * 100).toInt() 
                : 0,
            'topItems': [], 
          };
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('InsightsDashboard Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load insights: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error Boundary
    if (_error != null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Insights'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 2.h),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 1.h),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: _loadStats,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // DEBUG MODE
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 48, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "DEBUG MODE: DASHBOARD RENDERED",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("If you see this, the white screen is GONE."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text("Load Data Manually"),
            ),
            const SizedBox(height: 20),
            if (_error != null) 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _buildTimeRangeChip('Week', 0, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip('Month', 1, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip('Year', 2, theme),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, int index, ThemeData theme) {
    final isSelected = _selectedTimeRange == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimeRange = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsOverview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: 'Total Items',
                  value: '${_analyticsData['totalItems']}',
                  icon: Icons.checkroom,
                  trend: '+3',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: 'Outfits Logged',
                  value: '${_analyticsData['outfitsLogged']}',
                  icon: Icons.calendar_today,
                  trend: '+5',
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: 'Avg Cost/Wear',
                  value:
                      '\$${_analyticsData['avgCostPerWear'].toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  trend: '-\$2.30',
                  isPositiveTrend: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: 'Utilization',
                  value: '${_analyticsData['wardrobeUtilization']}%',
                  icon: Icons.pie_chart,
                  trend: '+8%',
                  isPositiveTrend: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      children: _aiInsights
          .map(
            (insight) => AIInsightCardWidget(
              type: insight['type'],
              title: insight['title'],
              description: insight['description'],
              icon: insight['icon'],
            ),
          )
          .toList(),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filter by Category'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Custom Date Range'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadStats();
  }

  void _handleNavigation(int index) {
    if (index == 3) return;

    final routes = [
      '/daily-log',
      '/wardrobe-management',
      '/smart-suggestions',
      '/insights-dashboard',
      '/learning-paths',
    ];

    Navigator.pushReplacementNamed(context, routes[index]);
  }
}
