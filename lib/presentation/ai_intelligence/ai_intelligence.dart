import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/providers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/ai_hero_section_widget.dart';
import './widgets/style_trends_card_widget.dart';
import './widgets/versatility_scores_card_widget.dart';
import './widgets/sustainability_impact_card_widget.dart';
import './widgets/recommendations_card_widget.dart';

class AIIntelligence extends ConsumerStatefulWidget {
  const AIIntelligence({Key? key}) : super(key: key);

  @override
  ConsumerState<AIIntelligence> createState() => _AIIntelligenceState();
}

class _AIIntelligenceState extends ConsumerState<AIIntelligence> {
  int _selectedTimeRange = 1;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(aiInsightsProvider);

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
        child: insightsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load insights: $e')),
          data: (aiData) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AIHeroSectionWidget(
                  confidenceScore: aiData['confidenceScore'] as int? ?? 0,
                  styleProfile: aiData['styleProfile'] as String? ?? 'Undetermined',
                ),
                SizedBox(height: 2.h),
                _buildTimeRangeSelector(theme),
                SizedBox(height: 3.h),
                _buildSectionHeader('Style Trends Analysis', theme),
                StyleTrendsCardWidget(
                  dominantColors: (aiData['dominantColors'] as List<dynamic>? ?? []).cast<String>(),
                  colorPercentages: (aiData['colorPercentages'] as List<dynamic>? ?? []).cast<int>(),
                  silhouetteEvolution: (aiData['silhouetteEvolution'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
                  emergingStyles: (aiData['emergingStyles'] as List<dynamic>? ?? []).cast<String>(),
                ),
                SizedBox(height: 3.h),
                _buildSectionHeader('Outfit Versatility Scores', theme),
                VersatilityScoresCardWidget(
                  versatilityScores: (aiData['versatilityScores'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
                  underutilizedItems: (aiData['underutilizedItems'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
                ),
                SizedBox(height: 3.h),
                _buildSectionHeader('Sustainability Impact', theme),
                SustainabilityImpactCardWidget(
                  metrics: (aiData['sustainabilityMetrics'] as Map<String, dynamic>?) ?? {},
                ),
                SizedBox(height: 3.h),
                _buildSectionHeader('Personalized Recommendations', theme),
                RecommendationsCardWidget(
                  recommendations: (aiData['recommendations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
                ),
                SizedBox(height: 3.h),
                _buildGenerateInsightsButton(theme),
                SizedBox(height: 10.h),
              ],
            ),
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
        onTap: () {
          setState(() => _selectedTimeRange = index);
          final ranges = ['week', 'month', 'season'];
          ref.read(aiIntelligenceTimeRangeProvider.notifier).state = ranges[index];
        },
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
    ref.invalidate(aiInsightsProvider);
  }

  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);
    ref.invalidate(aiInsightsProvider);
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
