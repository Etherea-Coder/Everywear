import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all data fetching for the AI Intelligence screen.
/// Pure wardrobe stats are computed server-side (Edge Function).
/// Results are cached for [_cacheDuration] to avoid redundant calls.
class AIIntelligenceService {
  AIIntelligenceService._();
  static final instance = AIIntelligenceService._();

  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _cache;
  String? _cachedTimeRange;
  String? _cachedCategory;
  DateTime? _cacheTime;

  static const _cacheDuration = Duration(minutes: 30);

  bool _isValid(String timeRange, String? category) {
    if (_cache == null || _cacheTime == null) return false;
    if (_cachedTimeRange != timeRange || _cachedCategory != category) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  /// Returns AI insights. Uses cache unless [forceRefresh] is true or
  /// the time range / category changed.
  Future<Map<String, dynamic>> getInsights({
    String timeRange = 'month',
    String? category,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isValid(timeRange, category)) return _cache!;

    final response = await _supabase.functions.invoke(
      'generate-ai-insights',
      body: {
        'timeRange': timeRange,
        if (category != null) 'category': category,
      },
    );

    if (response.status != 200) {
      throw Exception('Edge Function error ${response.status}: ${response.data}');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    _cache = data;
    _cachedTimeRange = timeRange;
    _cachedCategory = category;
    _cacheTime = DateTime.now();
    return data;
  }

  void clearCache() {
    _cache = null;
    _cachedTimeRange = null;
    _cachedCategory = null;
    _cacheTime = null;
  }
}
