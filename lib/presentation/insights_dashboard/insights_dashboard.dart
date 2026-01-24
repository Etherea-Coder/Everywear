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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _wardrobeService.getWardrobeStatistics();
      final history = await _wardrobeService.fetchOutfitHistory(limit: 50);
      
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Insights',
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.aiIntelligence);
            },
            tooltip: 'AI Intelligence',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.personalProgressDashboard);
            },
            tooltip: 'My Progress',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter insights',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settingsProfile);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(theme),
              SizedBox(height: 2.h),
              _buildMetricsOverview(),
              SizedBox(height: 3.h),
              _buildSectionHeader('Wardrobe Usage', theme),
              UsageChartWidget(timeRange: _selectedTimeRange),
              SizedBox(height: 3.h),
              _buildSectionHeader('Cost Per Wear Analysis', theme),
              CostPerWearChartWidget(topItems: _analyticsData['topItems']),
              SizedBox(height: 3.h),
              _buildSectionHeader('Sustainability Score', theme),
              SustainabilityScoreWidget(
                score: _analyticsData['sustainabilityScore'],
                wardrobeUtilization: _analyticsData['wardrobeUtilization'],
              ),
              SizedBox(height: 3.h),
              _buildSectionHeader('AI Insights', theme),
              _buildAIInsights(),
              SizedBox(height: 2.h),

              // Achievement Gallery Link
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.achievementGallery),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.secondary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSecondary.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: theme.colorScheme.onSecondary,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievement Gallery',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 0.3.h),
                            Text(
                              'View your earned badges and milestones',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: theme.colorScheme.onSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 3.h),
            ],
          ),
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
