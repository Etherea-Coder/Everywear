import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/ai_intelligence_service.dart';

import './widgets/ai_hero_section_widget.dart';
import './widgets/style_trends_card_widget.dart';
import './widgets/versatility_scores_card_widget.dart';
import './widgets/sustainability_impact_card_widget.dart';
import './widgets/recommendations_card_widget.dart';

class AIIntelligence extends StatefulWidget {
  const AIIntelligence({Key? key}) : super(key: key);

  @override
  State<AIIntelligence> createState() => _AIIntelligenceState();
}

class _AIIntelligenceState extends State<AIIntelligence> {
  // ── State ────────────────────────────────────────────────────────────────
  int _selectedTimeRange = 1;       // 0=week 1=month 2=season
  bool _isGenerating = false;
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;        // null = all categories

  Map<String, dynamic> _aiData = {};

  static const _timeRangeKeys = ['week', 'month', 'season'];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  String get _currentTimeRange => _timeRangeKeys[_selectedTimeRange];

  Future<void> _loadInsights({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final data = await AIIntelligenceService.instance.getInsights(
        timeRange: _currentTimeRange,
        category: _selectedCategory,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() { _aiData = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Public actions ───────────────────────────────────────────────────────

  /// Pull-to-refresh: reload from network, update cache.
  Future<void> _refreshInsights() => _loadInsights(forceRefresh: true);

  /// "Generate New Insights" button: force AI re-generation.
  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);
    AIIntelligenceService.instance.clearCache();
    try {
      await _loadInsights(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New AI insights generated!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  /// Time range chip tap: change window and re-fetch.
  void _onTimeRangeChanged(int index) {
    if (_selectedTimeRange == index) return;
    setState(() => _selectedTimeRange = index);
    _loadInsights();
  }

  // ── Filter sheet ─────────────────────────────────────────────────────────
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterSheet(
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          Navigator.pop(ctx);
          if (category == _selectedCategory) return;
          setState(() => _selectedCategory = category);
          _loadInsights();
        },
        onCustomDateRange: () {
          Navigator.pop(ctx);
          _pickCustomDateRange();
        },
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (picked == null || !mounted) return;

    // Map the picked range to the closest time-range key
    final days = picked.end.difference(picked.start).inDays;
    int newIndex;
    if (days <= 9)       newIndex = 0; // week
    else if (days <= 45) newIndex = 1; // month
    else                 newIndex = 2; // season

    setState(() => _selectedTimeRange = newIndex);
    _loadInsights();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'AI Intelligence',
        actions: [
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text(_selectedCategory!,
                    style: TextStyle(fontSize: 11.sp)),
                onDeleted: () {
                  setState(() => _selectedCategory = null);
                  _loadInsights();
                },
                deleteIconColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter analytics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInsights,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _aiData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _aiData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text('Could not load insights', style: theme.textTheme.titleMedium),
              SizedBox(height: 1.h),
              Text(_error!, textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => _loadInsights(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show a slim loading bar while refreshing (data already present)
          if (_isLoading)
            LinearProgressIndicator(
                minHeight: 2, color: theme.colorScheme.primary),

          AIHeroSectionWidget(
            confidenceScore: (_aiData['confidenceScore'] as num?)?.toInt() ?? 0,
            styleProfile:    _aiData['styleProfile']    ?? '—',
          ),
          SizedBox(height: 2.h),
          _buildTimeRangeSelector(theme),
          SizedBox(height: 3.h),

          _buildSectionHeader('Style Trends Analysis', theme),
          StyleTrendsCardWidget(
            dominantColors:      List<String>.from(_aiData['dominantColors']     ?? []),
            colorPercentages: (_aiData['colorPercentages'] as List? ?? [])
                .map((e) => (e as num).toInt())
                .toList(),
            silhouetteEvolution: List<Map<String, dynamic>>.from(
                (_aiData['silhouetteEvolution'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e))),
            emergingStyles:      List<String>.from(_aiData['emergingStyles']     ?? []),
          ),
          SizedBox(height: 3.h),

          _buildSectionHeader('Outfit Versatility Scores', theme),
          VersatilityScoresCardWidget(
            versatilityScores: List<Map<String, dynamic>>.from(
                (_aiData['versatilityScores'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e))),
            underutilizedItems: List<Map<String, dynamic>>.from(
                (_aiData['underutilizedItems'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e))),
          ),
          SizedBox(height: 3.h),

          _buildSectionHeader('Sustainability Impact', theme),
          SustainabilityImpactCardWidget(
            metrics: Map<String, dynamic>.from(_aiData['sustainabilityMetrics'] ?? {}),
          ),
          SizedBox(height: 3.h),

          _buildSectionHeader('Personalized Recommendations', theme),
          RecommendationsCardWidget(
            recommendations: List<Map<String, dynamic>>.from(
                (_aiData['recommendations'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e))),
          ),
          SizedBox(height: 3.h),
          _buildGenerateInsightsButton(theme),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────
  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          _buildChip('Week',   0, theme),
          SizedBox(width: 2.w),
          _buildChip('Month',  1, theme),
          SizedBox(width: 2.w),
          _buildChip('Season', 2, theme),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index, ThemeData theme) {
    final selected = _selectedTimeRange == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTimeRangeChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Text(title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600)),
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
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: theme.colorScheme.onPrimary))
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
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ──────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onCustomDateRange;

  static const _categories = [
  'Tops',
  'Bottoms',
  'Dresses',
  'Shoes',
  'Accessories',
  ];

  const _FilterSheet({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onCustomDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Custom date range
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Custom Date Range'),
              onTap: onCustomDateRange,
            ),
            const Divider(),

            // Category filter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Text('Filter by Category',
                  style: theme.textTheme.titleSmall),
            ),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                // "All" chip
                FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                ),
                ..._categories.map(
                  (cat) => FilterChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (_) => onCategorySelected(cat),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
