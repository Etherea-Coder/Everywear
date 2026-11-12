import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_request_id.dart';
import 'ai_allowance_service.dart';

/// Handles all data fetching for the AI Intelligence screen.
/// Pure wardrobe stats are computed server-side (Edge Function).
/// Results are cached for [_cacheDuration] to avoid redundant calls.
class AIIntelligenceService {
  AIIntelligenceService._();
  static final instance = AIIntelligenceService._();

  // Resolve lazily so constructing the service during startup/tests does not
  // require Supabase to have completed initialization already.
  SupabaseClient get _supabase => Supabase.instance.client;

  Map<String, dynamic>? _cache;
  String? _cachedUserId;
  String? _cachedTimeRange;
  String? _cachedCategory;
  DateTime? _cacheTime;

  static const _cacheDuration = Duration(minutes: 30);

  bool _isValid(String userId, String timeRange, String? category) {
    if (_cache == null || _cacheTime == null) return false;
    if (_cachedUserId != userId) return false;
    if (_cachedTimeRange != timeRange || _cachedCategory != category)
      return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  /// Returns AI insights. Uses cache unless [forceRefresh] is true or
  /// the time range / category changed.
  Future<Map<String, dynamic>> getInsights({
    String timeRange = 'month',
    String? category,
    bool forceRefresh = false,
  }) async {
    await _supabase.auth.refreshSession();
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');
    final userId = session.user.id;
    if (!forceRefresh && _isValid(userId, timeRange, category)) {
      return _withAllowance(_cache!);
    }
    final response = await _supabase.functions.invoke(
      'generate-ai-insights',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'requestId': newAiRequestId(),
        'timeRange': timeRange,
        if (category != null) 'category': category,
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Edge Function error ${response.status}: ${response.data}',
      );
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    _cache = Map<String, dynamic>.from(data)..remove('allowance');
    _cachedUserId = userId;
    _cachedTimeRange = timeRange;
    _cachedCategory = category;
    _cacheTime = DateTime.now();
    return _withAllowance(_cache!);
  }

  Future<Map<String, dynamic>> _withAllowance(Map<String, dynamic> data) async {
    try {
      final allowance = await AiAllowanceService(_supabase).fetchCurrent();
      return {
        ...data,
        'allowance': {
          'month_remaining': allowance.monthRemaining,
          'month_limit': allowance.monthLimit,
          'day_remaining': allowance.dayRemaining,
          'burst_remaining': allowance.burstRemaining,
          'month_resets_at': allowance.monthResetsAt?.toIso8601String(),
        },
      };
    } catch (_) {
      // The successful insights payload remains useful when quota metadata is
      // unavailable; AI requests still fail closed at the Edge Function.
      return data;
    }
  }

  void clearCache() {
    _cache = null;
    _cachedUserId = null;
    _cachedTimeRange = null;
    _cachedCategory = null;
    _cacheTime = null;
  }
}
