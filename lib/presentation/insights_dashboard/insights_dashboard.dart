import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/app_localizations.dart';

import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/metric_card_widget.dart';
import './widgets/ai_insight_card_widget.dart';
import '../../services/wardrobe_service.dart';
import '../../services/user_tier_service.dart';
import '../../widgets/upgrade_prompt_widget.dart';
/// Insights Dashboard - AI-powered style analytics and wardrobe insights
///
/// Displays analytics including:
/// - Wardrobe usage and utilization
/// - Cost-per-wear highlights
/// - Sustainability metrics
/// - Personalized style insights
///
/// Navigation: Accessed from Profile screen
/// No bottom bar - uses app bar back navigation
class InsightsDashboard extends StatefulWidget {
  const InsightsDashboard({Key? key}) : super(key: key);

  @override
  State<InsightsDashboard> createState() => _InsightsDashboardState();
}

class _InsightsDashboardState extends State<InsightsDashboard> {
  int _selectedTimeRange = 1; // 0: Week, 1: Month, 2: Year
  bool _isLoading = true;
  bool _isPremium = false;

  final WardrobeService _wardrobeService = WardrobeService();
  final UserTierService _tierService = UserTierService();

  Map<String, dynamic> _rawStats = {};
  List<Map<String, dynamic>> _outfitHistory = [];

  Map<String, dynamic> _analyticsData = {
    'totalItems': 0,
    'favoriteItems': 0,
    'outfitsLogged': 0,
    'avgCostPerWear': 0.0,
    'sustainabilityScore': 0,
    'wardrobeUtilization': 0,
    'topItems': <Map<String, dynamic>>[],
    'uniqueWornItems': 0,
    'unwornItems': 0,
    'topCategory': '—',
    'topOccasion': '—',
    'wearEvents': 0,
  };

  List<Map<String, dynamic>> _aiInsights = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final isPremium = await _tierService.isPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _wardrobeService.getWardrobeStatistics();
      final history = await _wardrobeService.fetchOutfitHistory(limit: 200);

      if (!mounted) return;

      _rawStats = Map<String, dynamic>.from(stats);
      _outfitHistory = List<Map<String, dynamic>>.from(history);

      _recomputeAnalytics();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      _rawStats = {};
      _outfitHistory = [];
      _recomputeAnalytics();

      setState(() => _isLoading = false);
    }
  }

  void _recomputeAnalytics() {
    final filteredHistory = _filterHistoryByTimeRange(_outfitHistory);

    final totalItems = _toInt(
      _rawStats['total_items'] ??
          _rawStats['totalItems'] ??
          _rawStats['items_count'] ??
          0,
    );

    final Map<String, int> wearCountByItem = {};
    final Map<String, Map<String, dynamic>> itemMetaById = {};
    final Map<String, int> categoryCounts = {};
    final Map<String, int> occasionCounts = {};

    int wearEvents = 0;

    for (final entry in filteredHistory) {
      final occasion = (entry['occasion'] ?? '').toString().trim();
      if (occasion.isNotEmpty) {
        occasionCounts[occasion] = (occasionCounts[occasion] ?? 0) + 1;
      }

      final outfitItems = _extractOutfitItems(entry);

      for (final outfitItem in outfitItems) {
        final wardrobeItem = _extractWardrobeItem(outfitItem);
        if (wardrobeItem == null) continue;

        final id = (wardrobeItem['id'] ?? wardrobeItem['item_id'] ?? '')
            .toString()
            .trim();
        if (id.isEmpty) continue;

        final name = (wardrobeItem['name'] ?? 'Item').toString();
        final category = (wardrobeItem['category'] ?? 'Other').toString();
        final imageUrl = (wardrobeItem['image_url'] ??
                wardrobeItem['imageUrl'] ??
                '')
            .toString();
        final price = _toDouble(
          wardrobeItem['purchase_price'] ??
              wardrobeItem['price'] ??
              wardrobeItem['cost'] ??
              0,
        );

        wearCountByItem[id] = (wearCountByItem[id] ?? 0) + 1;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        wearEvents++;

        itemMetaById[id] = {
          'id': id,
          'name': name,
          'category': category,
          'imageUrl': imageUrl,
          'price': price,
        };
      }
    }

    final uniqueWornItems = wearCountByItem.length;
    final unwornItems = totalItems > uniqueWornItems ? totalItems - uniqueWornItems : 0;
    final outfitsLogged = filteredHistory.length;

    final wardrobeUtilization = totalItems > 0
        ? ((uniqueWornItems / totalItems) * 100).round()
        : 0;

    final topItems = wearCountByItem.entries.map((entry) {
      final meta = itemMetaById[entry.key] ?? {};
      final wearCount = entry.value;
      final price = _toDouble(meta['price'] ?? 0);
      final cpw = wearCount > 0 && price > 0 ? price / wearCount : 0.0;

      return {
        'id': entry.key,
        'name': meta['name'] ?? 'Item',
        'category': meta['category'] ?? 'Other',
        'imageUrl': meta['imageUrl'] ?? '',
        'price': price,
        'wearCount': wearCount,
        'cpw': cpw,
      };
    }).toList()
      ..sort((a, b) {
        final aHasPrice = (_toDouble(a['price']) > 0);
        final bHasPrice = (_toDouble(b['price']) > 0);

        if (aHasPrice && bHasPrice) {
          return _toDouble(a['cpw']).compareTo(_toDouble(b['cpw']));
        }
        return _toInt(b['wearCount']).compareTo(_toInt(a['wearCount']));
      });

    final pricedItems = topItems.where((item) => _toDouble(item['price']) > 0).toList();
    final avgCostPerWear = pricedItems.isNotEmpty
        ? pricedItems
                .map((item) => _toDouble(item['cpw']))
                .fold<double>(0.0, (sum, value) => sum + value) /
            pricedItems.length
        : 0.0;

    final topCategory = categoryCounts.isNotEmpty
        ? categoryCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key
        : '—';

    final topOccasion = occasionCounts.isNotEmpty
        ? occasionCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key
        : '—';

    final favoriteItems = wearCountByItem.values.where((count) => count >= 2).length;
    final sustainabilityScore = _calculateSustainabilityScore(
      wardrobeUtilization: wardrobeUtilization,
      avgCostPerWear: avgCostPerWear,
      outfitsLogged: outfitsLogged,
      unwornItems: unwornItems,
    );

    _analyticsData = {
      'totalItems': totalItems,
      'favoriteItems': favoriteItems,
      'outfitsLogged': outfitsLogged,
      'avgCostPerWear': avgCostPerWear,
      'sustainabilityScore': sustainabilityScore,
      'wardrobeUtilization': wardrobeUtilization,
      'topItems': topItems.take(8).toList(),
      'uniqueWornItems': uniqueWornItems,
      'unwornItems': unwornItems,
      'topCategory': topCategory,
      'topOccasion': topOccasion,
      'wearEvents': wearEvents,
    };

    _aiInsights = _generateInsights();
  }

  List<Map<String, dynamic>> _filterHistoryByTimeRange(
    List<Map<String, dynamic>> history,
  ) {
    final now = DateTime.now();
    late DateTime threshold;

    switch (_selectedTimeRange) {
      case 0:
        threshold = now.subtract(const Duration(days: 7));
        break;
      case 1:
        threshold = now.subtract(const Duration(days: 30));
        break;
      case 2:
      default:
        threshold = now.subtract(const Duration(days: 365));
        break;
    }

    return history.where((entry) {
      final date = _parseDate(
        entry['worn_date'] ??
            entry['date'] ??
            entry['created_at'],
      );
      if (date == null) return false;
      return !date.isBefore(threshold);
    }).toList();
  }

  List<Map<String, dynamic>> _extractOutfitItems(Map<String, dynamic> entry) {
    final raw = entry['outfit_items'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _extractWardrobeItem(Map<String, dynamic> outfitItem) {
    final nested = outfitItem['wardrobe_items'] ?? outfitItem['wardrobe_item'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    if (outfitItem.containsKey('id') && outfitItem.containsKey('name')) {
      return outfitItem;
    }

    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _calculateSustainabilityScore({
    required int wardrobeUtilization,
    required double avgCostPerWear,
    required int outfitsLogged,
    required int unwornItems,
  }) {
    double score = 0;

    score += wardrobeUtilization * 0.55;

    if (avgCostPerWear > 0) {
      final cpwComponent = (20 - avgCostPerWear).clamp(0, 20);
      score += cpwComponent * 1.5;
    }

    score += (outfitsLogged / 2).clamp(0, 15);

    score -= (unwornItems * 1.2).clamp(0, 15);

    return score.clamp(0, 100).round();
  }

  List<Map<String, dynamic>> _generateInsights() {
    final totalItems = _toInt(_analyticsData['totalItems']);
    final uniqueWornItems = _toInt(_analyticsData['uniqueWornItems']);
    final unwornItems = _toInt(_analyticsData['unwornItems']);
    final wardrobeUtilization = _toInt(_analyticsData['wardrobeUtilization']);
    final avgCostPerWear = _toDouble(_analyticsData['avgCostPerWear']);
    final topCategory = (_analyticsData['topCategory'] ?? '—').toString();
    final topOccasion = (_analyticsData['topOccasion'] ?? '—').toString();
    final topItems = (_analyticsData['topItems'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final insights = <Map<String, dynamic>>[];

    final l10n = AppLocalizations.of(context);

    if (totalItems == 0) {
      insights.add({
        'type': 'suggestion',
        'title': l10n.insightStartTitle,
        'description': l10n.insightStartDesc,
        'icon': Icons.lightbulb_outline,
      });
      return insights;
    }

    if (wardrobeUtilization >= 60) {
      insights.add({
        'type': 'positive',
        'title': l10n.insightStrongUtilTitle,
        'description': l10n.insightStrongUtilDesc(wardrobeUtilization),
        'icon': Icons.trending_up,
      });
    } else {
      insights.add({
        'type': 'suggestion',
        'title': l10n.insightUntappedPotentialTitle,
        'description': l10n.insightUntappedPotentialDesc(uniqueWornItems, totalItems),
        'icon': Icons.lightbulb_outline,
      });
    }

    if (topCategory != '—') {
      insights.add({
        'type': 'achievement',
        'title': l10n.insightWardrobeSignatureTitle,
        'description': l10n.insightWardrobeSignatureDesc(topCategory),
        'icon': Icons.checkroom,
      });
    }

    if (topOccasion != '—') {
      insights.add({
        'type': 'positive',
        'title': l10n.insightCurrentRhythmTitle,
        'description': l10n.insightCurrentRhythmDesc(topOccasion),
        'icon': Icons.calendar_today,
      });
    }

    if (unwornItems > 0) {
      insights.add({
        'type': 'suggestion',
        'title': l10n.insightPiecesAttentionTitle,
        'description': l10n.insightPiecesAttentionDesc(unwornItems),
        'icon': Icons.auto_fix_high,
      });
    }

    if (avgCostPerWear > 0) {
      final valStr = '\$${avgCostPerWear.toStringAsFixed(2)}';
      final description = avgCostPerWear <= 10
          ? l10n.insightCpwCheckSolidDesc(valStr)
          : l10n.insightCpwCheckImproveDesc(valStr);
      insights.add({
        'type': avgCostPerWear <= 10 ? 'achievement' : 'suggestion',
        'title': l10n.insightCpwCheckTitle,
        'description': description,
        'icon': Icons.attach_money,
      });
    }

    if (topItems.isNotEmpty) {
      final item = topItems.first;
      final wearCount = _toInt(item['wearCount']);
      insights.add({
        'type': 'positive',
        'title': l10n.insightReliablePieceTitle,
        'description': l10n.insightReliablePieceDesc(item['name'] ?? 'Item', wearCount),
        'icon': Icons.star_outline,
      });
    }

    return insights.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.styleInsightsTitle,
        variant: CustomAppBarVariant.detail,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.aiIntelligence);
            },
            tooltip: l10n.aiIntelligenceTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.personalProgressDashboard);
            },
            tooltip: l10n.myProgressTooltip,
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
                    SizedBox(height: 1.h),
                    _buildHeroCard(theme),
                    SizedBox(height: 2.5.h),
                    _buildMetricsOverview(),
                    SizedBox(height: 3.h),
                    _buildSectionHeader(l10n.wardrobeUsageHeader, theme),
                    SizedBox(height: 1.h),
                    _buildUsageSection(theme),
                    SizedBox(height: 3.h),
                    _buildSectionHeader(l10n.bestValueHeader, theme),
                    SizedBox(height: 1.h),
                    _isPremium
                        ? _buildCostPerWearSection(theme)
                        : _buildSignatureLockedCard(theme, l10n.bestValueHeader),
                    SizedBox(height: 3.h),
                    _buildSectionHeader(l10n.sustainabilityHeader, theme),
                    SizedBox(height: 1.h),
                    _isPremium
                        ? _buildSustainabilitySection(theme)
                        : _buildSignatureLockedCard(theme, l10n.sustainabilityHeader),
                    SizedBox(height: 3.h),
                    _buildSectionHeader(l10n.aiInsightsHeader, theme),
                    SizedBox(height: 1.h),
                    _isPremium
                        ? _buildAIInsights()
                        : _buildSignatureLockedCard(theme, l10n.aiInsightsHeader),
                    SizedBox(height: 2.h),

                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.achievementGallery,
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.06),
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
                                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color: theme.colorScheme.secondary,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.achievementGalleryTitle,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 0.3.h),
                                  Text(
                                    l10n.achievementGallerySubtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: theme.colorScheme.secondary,
                              size: 18,
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

  Widget _buildHeroCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final utilization = _toInt(_analyticsData['wardrobeUtilization']);
    final totalItems = _toInt(_analyticsData['totalItems']);
    final topCategory = (_analyticsData['topCategory'] ?? '—').toString();

    String title = l10n.heroInsightTitleNew;
    String subtitle = l10n.heroInsightSubtitleNew;

    if (totalItems == 0) {
      title = l10n.heroInsightTitleEmpty;
      subtitle = l10n.heroInsightSubtitleEmpty;
    } else if (utilization >= 60) {
      title = l10n.heroInsightTitleStrong;
      subtitle = l10n.heroInsightSubtitleStrong(topCategory);
    } else if (topCategory != '—') {
      title = l10n.heroInsightTitlePotential;
      subtitle = l10n.heroInsightSubtitlePotential(topCategory);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 4,
              color: theme.colorScheme.secondary.withValues(alpha: 0.45),
            ),
            SizedBox(width: 4.w),
            Container(
              width: 13.w,
              height: 13.w,
              margin: EdgeInsets.symmetric(vertical: 4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.secondary,
                size: 26,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 3.w),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _buildTimeRangeChip(l10n.labelWeek, 0, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip(l10n.labelMonth, 1, theme),
          SizedBox(width: 2.w),
          _buildTimeRangeChip(l10n.labelYear, 2, theme),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, int index, ThemeData theme) {
    final isSelected = _selectedTimeRange == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimeRange = index;
            _recomputeAnalytics();
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
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
    final l10n = AppLocalizations.of(context);
    final favoriteItems = _toInt(_analyticsData['favoriteItems']);
    final wearEvents = _toInt(_analyticsData['wearEvents']);
    final uniqueWornItems = _toInt(_analyticsData['uniqueWornItems']);
    final avgCostPerWear = _toDouble(_analyticsData['avgCostPerWear']);
    final utilization = _toInt(_analyticsData['wardrobeUtilization']);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: l10n.metricTotalItems,
                  value: '${_analyticsData['totalItems']}',
                  icon: Icons.checkroom,
                  trend: l10n.metricReliableTrend(favoriteItems),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: l10n.metricOutfitsLogged,
                  value: '${_analyticsData['outfitsLogged']}',
                  icon: Icons.calendar_today,
                  trend: l10n.metricWearEventsTrend(wearEvents),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: MetricCardWidget(
                  title: l10n.metricAvgCpw,
                  value: avgCostPerWear > 0
                      ? '\$${avgCostPerWear.toStringAsFixed(2)}'
                      : '—',
                  icon: Icons.attach_money,
                  trend: avgCostPerWear > 0
                      ? l10n.metricCpwLowerHint
                      : l10n.metricCpwNoData,
                  isPositiveTrend:
                      avgCostPerWear > 0 &&
                          avgCostPerWear <= 10,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: MetricCardWidget(
                  title: l10n.metricUtilization,
                  value: '$utilization%',
                  icon: Icons.pie_chart,
                  trend: l10n.metricPiecesWornTrend(uniqueWornItems),
                  isPositiveTrend:
                      utilization >= 60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(ThemeData theme) {
    final totalItems = _toInt(_analyticsData['totalItems']);
    final uniqueWornItems = _toInt(_analyticsData['uniqueWornItems']);
    final unwornItems = _toInt(_analyticsData['unwornItems']);
    final utilization = _toInt(_analyticsData['wardrobeUtilization']);
    final topCategory = (_analyticsData['topCategory'] ?? '—').toString();
    final topOccasion = (_analyticsData['topOccasion'] ?? '—').toString();

    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.usageUtilizationTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            totalItems > 0
                ? l10n.usageSummaryText(uniqueWornItems, totalItems)
                : l10n.usageNoData,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 1.8.h),
          LinearProgressIndicator(
            value: totalItems > 0 ? utilization / 100 : 0,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
          SizedBox(height: 1.2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(theme, l10n.labelWorn, '$uniqueWornItems'),
              _buildMiniMetric(theme, l10n.labelUnworn, '$unwornItems'),
              _buildMiniMetric(theme, l10n.labelTopCategory, topCategory),
              _buildMiniMetric(theme, l10n.labelTopOccasion, topOccasion),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostPerWearSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final topItems = (_analyticsData['topItems'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    if (topItems.isEmpty) {
      return _buildEmptyInfoCard(
        theme,
        icon: Icons.attach_money,
        title: l10n.cpwNoDataTitle,
        subtitle: l10n.cpwNoDataSubtitle,
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: topItems.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final hasPrice = _toDouble(item['price']) > 0;

          return Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: index < topItems.take(5).length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'Item',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        '${item['category'] ?? 'Other'} · ${l10n.wornXTimes(item['wearCount'] ?? 0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  hasPrice
                      ? '\$${_toDouble(item['cpw']).toStringAsFixed(2)}'
                      : '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasPrice
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSustainabilitySection(ThemeData theme) {
    final score = _toInt(_analyticsData['sustainabilityScore']);
    final utilization = _toInt(_analyticsData['wardrobeUtilization']);
    final avgCpw = _toDouble(_analyticsData['avgCostPerWear']);
    final unworn = _toInt(_analyticsData['unwornItems']);

    final l10n = AppLocalizations.of(context);
    String summary;
    if (score >= 75) {
      summary = l10n.sustainabilitySummaryStrong;
    } else if (score >= 50) {
      summary = l10n.sustainabilitySummaryGood;
    } else {
      summary = l10n.sustainabilitySummaryImprove;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$score',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      l10n.sustainabilityScoreLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 22.w,
                height: 22.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.eco,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 1.8.h),
          Row(
            children: [
              Expanded(
                child: _buildSustainabilityPill(
                  theme,
                  label: l10n.metricUtilization,
                  value: '$utilization%',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSustainabilityPill(
                  theme,
                  label: l10n.metricAvgCpw,
                  value: avgCpw > 0 ? '\$${avgCpw.toStringAsFixed(2)}' : '—',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSustainabilityPill(
                  theme,
                  label: l10n.labelUnworn,
                  value: '$unworn',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityPill(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInfoCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          SizedBox(height: 1.5.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.6.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureLockedCard(ThemeData theme, String feature) {
    final l10n = AppLocalizations.of(context);
    return UpgradePromptWidget(
      compact: true,
      title: l10n.signatureFeatureTitle,
      message: l10n.signatureFeatureMessage(feature),
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
    if (_aiInsights.isEmpty) {
      return const SizedBox.shrink();
    }

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

  Future<void> _refreshData() async {
    await _loadStats();
  }
}
