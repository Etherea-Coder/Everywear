import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/ai_hero_section_widget.dart';
import './widgets/style_trends_card_widget.dart';
import './widgets/versatility_scores_card_widget.dart';
import './widgets/sustainability_impact_card_widget.dart';
import './widgets/recommendations_card_widget.dart';

/// AI Intelligence Screen - Comprehensive wardrobe analytics powered by local AI
/// Displays style trends, outfit versatility, sustainability metrics, and personalized recommendations
class AIIntelligence extends StatefulWidget {
  const AIIntelligence({Key? key}) : super(key: key);

  @override
  State<AIIntelligence> createState() => _AIIntelligenceState();
}

class _AIIntelligenceState extends State<AIIntelligence> {
  int _selectedTimeRange = 1;
  bool _isGenerating = false;

  final Map<String, dynamic> _aiData = {
    'confidenceScore': 87,
    'styleProfile': 'Casual Minimalist',
    'dominantColors': ['Blue', 'Black', 'White', 'Gray'],
    'colorPercentages': [35, 25, 20, 15],
    'silhouetteEvolution': [
      {'month': 'Jan', 'fitted': 40, 'relaxed': 60},
      {'month': 'Feb', 'fitted': 45, 'relaxed': 55},
      {'month': 'Mar', 'fitted': 50, 'relaxed': 50},
    ],
    'emergingStyles': ['Athleisure', 'Smart Casual'],
    'versatilityScores': [
      {'item': 'Black Jeans', 'score': 92, 'combinations': 18},
      {'item': 'White T-Shirt', 'score': 88, 'combinations': 16},
      {'item': 'Denim Jacket', 'score': 75, 'combinations': 12},
      {'item': 'Red Dress', 'score': 35, 'combinations': 4},
    ],
    'underutilizedItems': [
      {'item': 'Formal Blazer', 'lastWorn': '45 days ago', 'suggestions': 3},
      {'item': 'Floral Skirt', 'lastWorn': '32 days ago', 'suggestions': 2},
    ],
    'sustainabilityMetrics': {
      'avgCostPerWear': 8.75,
      'costTrend': -12.5,
      'purchaseFrequency': 2.3,
      'carbonImpact': 145,
      'carbonGoal': 200,
      'sustainabilityGoalProgress': 72,
    },
    'recommendations': [
      {
        'type': 'gap',
        'title': 'Add Versatile Bottoms',
        'description':
            'Your wardrobe lacks neutral-colored pants. Consider adding khaki or gray trousers for more outfit combinations.',
        'confidence': 85,
        'reasoning': 'Analysis shows 60% of your tops lack compatible bottoms',
      },
      {
        'type': 'seasonal',
        'title': 'Spring Transition Pieces',
        'description':
            'Light cardigans and linen shirts would expand your spring wardrobe options.',
        'confidence': 78,
        'reasoning':
            'Seasonal analysis indicates limited transitional layering options',
      },
      {
        'type': 'style',
        'title': 'Elevate Your Casual Style',
        'description':
            'Adding structured blazers could bridge your casual and professional looks.',
        'confidence': 72,
        'reasoning':
            'Style evolution suggests growing interest in smart casual aesthetics',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'AI Intelligence',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter analytics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInsights,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AIHeroSectionWidget(
                confidenceScore: _aiData['confidenceScore'],
                styleProfile: _aiData['styleProfile'],
              ),
              SizedBox(height: 2.h),
              _buildTimeRangeSelector(theme),
              SizedBox(height: 3.h),
              _buildSectionHeader('Style Trends Analysis', theme),
              StyleTrendsCardWidget(
                dominantColors: _aiData['dominantColors'],
                colorPercentages: _aiData['colorPercentages'],
                silhouetteEvolution: _aiData['silhouetteEvolution'],
                emergingStyles: _aiData['emergingStyles'],
              ),
              SizedBox(height: 3.h),
              _buildSectionHeader('Outfit Versatility Scores', theme),
              VersatilityScoresCardWidget(
                versatilityScores: _aiData['versatilityScores'],
                underutilizedItems: _aiData['underutilizedItems'],
              ),
              SizedBox(height: 3.h),
              _buildSectionHeader('Sustainability Impact', theme),
              SustainabilityImpactCardWidget(
                metrics: _aiData['sustainabilityMetrics'],
              ),
              SizedBox(height: 3.h),
              _buildSectionHeader('Personalized Recommendations', theme),
              RecommendationsCardWidget(
                recommendations: _aiData['recommendations'],
              ),
              SizedBox(height: 3.h),
              _buildGenerateInsightsButton(theme),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          _buildTimeRangeChip('Week', 0, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip('Month', 1, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip('Season', 2, theme),
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
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenerateInsightsButton(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateNewInsights,
        icon: _isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating ? 'Generating...' : 'Generate New Insights',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshInsights() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New AI insights generated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              leading: const Icon(Icons.calendar_today),
              title: const Text('Custom Date Range'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filter by Category'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.style),
              title: const Text('Filter by Style'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 3) return;

    final routes = [
      AppRoutes.dailyLog,
      AppRoutes.wardrobeManagement,
      AppRoutes.smartSuggestions,
      AppRoutes.insightsDashboard,
      AppRoutes.purchaseTracking,
    ];

    Navigator.pushReplacementNamed(context, routes[index]);
  }
}
