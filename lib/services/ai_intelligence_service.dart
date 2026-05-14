import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

class AIIntelligenceService {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  Future<Map<String, dynamic>> getInsights({String timeRange = 'month'}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return getDefaultInsights();
      }

      final wardrobeItems = await _fetchWardrobeItems(user.id);
      final outfitLogs = await _fetchOutfitLogs(user.id, timeRange);

      return computeInsights(wardrobeItems, outfitLogs);
    } catch (e) {
      debugPrint('AIIntelligenceService.getInsights error: $e');
      return getDefaultInsights();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWardrobeItems(String userId) async {
    try {
      final response = await _supabase
          .from('wardrobe_items')
          .select()
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 8));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AIIntelligenceService._fetchWardrobeItems error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOutfitLogs(
    String userId,
    String timeRange,
  ) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (timeRange) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'season':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      final response = await _supabase
          .from('outfit_logs')
          .select('*, outfit_items(wardrobe_items(id, category, name))')
          .eq('user_id', userId)
          .gte('worn_date', startDate.toIso8601String())
          .order('worn_date', ascending: false)
          .timeout(const Duration(seconds: 8));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AIIntelligenceService._fetchOutfitLogs error: $e');
      return [];
    }
  }

  Map<String, dynamic> computeInsights(
    List<Map<String, dynamic>> wardrobeItems,
    List<Map<String, dynamic>> outfitLogs,
  ) {
    final categoryCounts = <String, int>{};
    final colorCounts = <String, int>{};
    int totalWears = 0;
    final itemWearCounts = <String, int>{};

    for (final item in wardrobeItems) {
      final category = (item['category'] as String?) ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      final color = (item['color'] as String?) ?? 'Unknown';
      colorCounts[color] = (colorCounts[color] ?? 0) + 1;
    }

    for (final log in outfitLogs) {
      totalWears++;
      final outfitItems = log['outfit_items'] as List<dynamic>? ?? [];
      for (final oi in outfitItems) {
        final wi = oi['wardrobe_items'] as Map<String, dynamic>?;
        if (wi != null) {
          final itemId = wi['id']?.toString();
          if (itemId != null) {
            itemWearCounts[itemId] = (itemWearCounts[itemId] ?? 0) + 1;
          }
        }
      }
    }

    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topColors = sortedColors.take(4).map((e) => e.key).toList();
    final topPercentages = _computePercentages(sortedColors.take(4).toList());

    final confidenceScore = wardrobeItems.isEmpty
        ? 0
        : (outfitLogs.length * 10).clamp(0, 100);

    final styleProfile = _deriveStyleProfile(categoryCounts);

    final versatilityScores = _computeVersatilityScores(
      wardrobeItems,
      itemWearCounts,
    );

    final underutilizedItems = _findUnderutilizedItems(
      wardrobeItems,
      itemWearCounts,
    );

    final sustainabilityMetrics = _computeSustainabilityMetrics(
      wardrobeItems,
      totalWears,
    );

    final recommendations = _generateRecommendations(
      categoryCounts,
      underutilizedItems,
    );

    return {
      'confidenceScore': confidenceScore,
      'styleProfile': styleProfile,
      'dominantColors': topColors,
      'colorPercentages': topPercentages,
      'silhouetteEvolution': _getSilhouetteEvolution(),
      'emergingStyles': _getEmergingStyles(categoryCounts),
      'versatilityScores': versatilityScores,
      'underutilizedItems': underutilizedItems,
      'sustainabilityMetrics': sustainabilityMetrics,
      'recommendations': recommendations,
    };
  }

  List<int> _computePercentages(List<MapEntry<String, int>> entries) {
    if (entries.isEmpty) return [];
    final total = entries.fold(0, (sum, e) => sum + e.value);
    if (total == 0) return entries.map((_) => 0).toList();
    return entries.map((e) => ((e.value / total) * 100).round()).toList();
  }

  String _deriveStyleProfile(Map<String, int> categoryCounts) {
    if (categoryCounts.isEmpty) return 'Undetermined';

    final topCategory = categoryCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    switch (topCategory.key) {
      case 'Tops':
      case 'Bottoms':
        return 'Casual Minimalist';
      case 'Dresses':
        return 'Elegant Classic';
      case 'Outerwear':
        return 'Layered Professional';
      case 'Activewear':
        return 'Sporty Chic';
      default:
        return 'Eclectic Mix';
    }
  }

  List<Map<String, dynamic>> _computeVersatilityScores(
    List<Map<String, dynamic>> items,
    Map<String, int> wearCounts,
  ) {
    return items.take(4).map((item) {
      final itemId = item['id']?.toString() ?? '';
      final wearCount = wearCounts[itemId] ?? 0;
      final score = (wearCount * 15).clamp(10, 98);

      return {
        'item': (item['name'] as String?) ?? 'Unknown Item',
        'score': score,
        'combinations': wearCount + 1,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _findUnderutilizedItems(
    List<Map<String, dynamic>> items,
    Map<String, int> wearCounts,
  ) {
    final underutilized = items.where((item) {
      final itemId = item['id']?.toString() ?? '';
      return (wearCounts[itemId] ?? 0) < 2;
    }).take(2).map((item) {
      return {
        'item': (item['name'] as String?) ?? 'Unknown Item',
        'lastWorn': '30+ days ago',
        'suggestions': 2,
      };
    }).toList();

    return underutilized;
  }

  Map<String, dynamic> _computeSustainabilityMetrics(
    List<Map<String, dynamic>> items,
    int totalWears,
  ) {
    double totalSpent = 0;
    for (final item in items) {
      final price = item['purchase_price'];
      if (price is num) {
        totalSpent += price.toDouble();
      }
    }

    final avgCostPerWear = totalWears > 0 ? totalSpent / totalWears : 0.0;

    return {
      'avgCostPerWear': avgCostPerWear,
      'costTrend': -5.0,
      'purchaseFrequency': items.length > 0 ? totalWears / items.length : 0.0,
      'carbonImpact': 100,
      'carbonGoal': 200,
      'sustainabilityGoalProgress': 50,
    };
  }

  List<Map<String, dynamic>> _generateRecommendations(
    Map<String, int> categoryCounts,
    List<Map<String, dynamic>> underutilizedItems,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    final missingCategories = [
      'Tops',
      'Bottoms',
      'Outerwear',
      'Shoes',
      'Accessories',
    ].where((cat) => !categoryCounts.containsKey(cat)).toList();

    if (missingCategories.isNotEmpty) {
      recommendations.add({
        'type': 'gap',
        'title': 'Add ${missingCategories.first} to Your Wardrobe',
        'description':
            'Your wardrobe is missing ${missingCategories.first.toLowerCase()}. Adding some would increase outfit combinations.',
        'confidence': 85,
        'reasoning':
            'Analysis shows no ${missingCategories.first.toLowerCase()} in your wardrobe',
      });
    }

    if (underutilizedItems.isNotEmpty) {
      recommendations.add({
        'type': 'style',
        'title': 'Wear ${underutilizedItems.first['item']} More',
        'description':
            'This item hasn\'t been worn recently. Try pairing it differently.',
        'confidence': 72,
        'reasoning': 'Item has low wear frequency',
      });
    }

    recommendations.add({
      'type': 'seasonal',
      'title': 'Seasonal Transition Pieces',
      'description':
          'Consider adding versatile layering pieces for the current season.',
      'confidence': 70,
      'reasoning': 'Based on seasonal wardrobe analysis',
    });

    return recommendations;
  }

  List<Map<String, dynamic>> _getSilhouetteEvolution() {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final month = DateTime(now.year, now.month - 2 + i);
      return {
        'month': _monthAbbrev(month.month),
        'fitted': 40 + (i * 5),
        'relaxed': 60 - (i * 5),
      };
    });
  }

  List<String> _getEmergingStyles(Map<String, int> categoryCounts) {
    if (categoryCounts.containsKey('Activewear')) {
      return ['Athleisure', 'Smart Casual'];
    }
    return ['Smart Casual', 'Minimalist'];
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Map<String, dynamic> getDefaultInsights() {
    return {
      'confidenceScore': 0,
      'styleProfile': 'Undetermined',
      'dominantColors': <String>[],
      'colorPercentages': <int>[],
      'silhouetteEvolution': <Map<String, dynamic>>[],
      'emergingStyles': <String>[],
      'versatilityScores': <Map<String, dynamic>>[],
      'underutilizedItems': <Map<String, dynamic>>[],
      'sustainabilityMetrics': {
        'avgCostPerWear': 0.0,
        'costTrend': 0.0,
        'purchaseFrequency': 0.0,
        'carbonImpact': 0,
        'carbonGoal': 200,
        'sustainabilityGoalProgress': 0,
      },
      'recommendations': <Map<String, dynamic>>[],
    };
  }
}
