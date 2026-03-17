import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import '../core/tier_limits.dart';

/// Service for managing user tier limits and usage tracking.
/// All limit checks go through this service — never check limits inline.
class UserTierService {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  // ── TIER ────────────────────────────────────────────────

  /// Returns the current user's tier ('free' or 'premium')
  Future<String> getUserTier() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'free';
      final response = await _supabase
          .from('user_profiles')
          .select('tier')
          .eq('id', user.id)
          .single();
      return response['tier'] as String? ?? 'free';
    } catch (e) {
      return 'free';
    }
  }

  /// Returns true if the current user is on the Signature (premium) plan
  Future<bool> isPremium() async {
    final tier = await getUserTier();
    return tier == 'premium';
  }

  // ── OUTFIT LOGS ─────────────────────────────────────────

  /// Returns true if user can still create a new outfit log
  Future<bool> canLogOutfit(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('tier, outfit_logs_count')
          .eq('id', userId)
          .single();
      final tier = response['tier'] as String? ?? 'free';
      final count = response['outfit_logs_count'] as int? ?? 0;
      return count < TierLimits.outfitLogLimit(tier);
    } catch (e) {
      return true;
    }
  }

  /// Increments the outfit log count after a successful log
  Future<void> incrementOutfitLogCount(String userId) async {
    try {
      await _supabase.rpc('increment_outfit_log_count',
          params: {'user_id_input': userId});
    } catch (e) {
      // Fail silently
    }
  }

  /// Returns how many outfit logs are stored for this user
  Future<int> getOutfitLogCount(String userId) async {
    try {
      final response = await _supabase
          .from('outfit_logs')
          .select('id')
          .eq('user_id', userId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ── DAILY SUGGESTIONS ───────────────────────────────────

  /// Returns true if user can request another suggestion today
  Future<bool> canRequestSuggestion(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('tier, daily_suggestions_used, suggestions_reset_at')
          .eq('id', userId)
          .single();

      final tier = response['tier'] as String? ?? 'free';

      // Reset daily count if it's a new day
      final resetAt = response['suggestions_reset_at'] as String?;
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (resetAt != today) {
        await _supabase.from('user_profiles').update({
          'daily_suggestions_used': 0,
          'suggestions_reset_at': today,
        }).eq('id', userId);
        return true;
      }

      final used = response['daily_suggestions_used'] as int? ?? 0;
      return used < TierLimits.dailySuggestionLimit(tier);
    } catch (e) {
      return true;
    }
  }

  /// Increments daily suggestion count
  Future<void> incrementSuggestionCount(String userId) async {
    try {
      await _supabase.rpc('increment_daily_suggestions',
          params: {'user_id_input': userId});
    } catch (e) {
      // Fail silently
    }
  }

  // ── AI COACHING ─────────────────────────────────────────

  /// Returns true if user can ask the coach a question
  /// Essential: 1 per week, Signature: 50 per month
  Future<bool> canUseCoach(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('tier, coaching_sessions_used, coaching_reset_at')
          .eq('id', userId)
          .single();

      final tier = response['tier'] as String? ?? 'free';
      final limit = TierLimits.coachingLimit(tier);
      final used = response['coaching_sessions_used'] as int? ?? 0;

      // Determine reset window
      final resetAt = response['coaching_reset_at'] != null
          ? DateTime.parse(response['coaching_reset_at'] as String)
          : DateTime.now();

      final now = DateTime.now();
      final shouldReset = tier == 'premium'
          ? now.month != resetAt.month || now.year != resetAt.year
          : now.difference(resetAt).inDays >= 7;

      if (shouldReset) {
        await _supabase.from('user_profiles').update({
          'coaching_sessions_used': 0,
          'coaching_reset_at': now.toIso8601String(),
        }).eq('id', userId);
        return true;
      }

      return used < limit;
    } catch (e) {
      return true;
    }
  }

  /// Increments coaching session count
  Future<void> incrementCoachingCount(String userId) async {
    try {
      await _supabase.from('user_profiles').update({
        'coaching_sessions_used':
            _supabase.rpc('increment_coaching_sessions',
                params: {'user_id_input': userId}),
      });
    } catch (e) {
      // Use a simpler approach
      final response = await _supabase
          .from('user_profiles')
          .select('coaching_sessions_used')
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      final current = response['coaching_sessions_used'] as int? ?? 0;
      await _supabase.from('user_profiles').update({
        'coaching_sessions_used': current + 1,
      }).eq('id', _supabase.auth.currentUser!.id);
    }
  }

  /// Returns remaining coaching sessions for display in UI
  Future<Map<String, dynamic>> getCoachingQuota(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('tier, coaching_sessions_used, coaching_reset_at')
          .eq('id', userId)
          .single();
      final tier = response['tier'] as String? ?? 'free';
      final used = response['coaching_sessions_used'] as int? ?? 0;
      final limit = TierLimits.coachingLimit(tier);
      return {
        'used': used,
        'limit': limit,
        'remaining': (limit - used).clamp(0, limit),
        'tier': tier,
        'period': tier == 'premium' ? 'this month' : 'this week',
      };
    } catch (e) {
      return {
        'used': 0,
        'limit': TierLimits.essentialCoachingPerWeek,
        'remaining': TierLimits.essentialCoachingPerWeek,
        'tier': 'free',
        'period': 'this week',
      };
    }
  }

  // ── FULL TIER INFO ───────────────────────────────────────

  Future<Map<String, dynamic>> getUserTierInfo(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select(
            'tier, daily_suggestions_used, '
            'suggestions_reset_at, coaching_sessions_used, coaching_reset_at, '
            'outfit_logs_count',
          )
          .eq('id', userId)
          .single();

      final tier = response['tier'] as String? ?? 'free';
      final suggestionsUsed = response['daily_suggestions_used'] as int? ?? 0;
      final suggestionsLimit = TierLimits.dailySuggestionLimit(tier);
      final coachingUsed = response['coaching_sessions_used'] as int? ?? 0;
      final coachingLimit = TierLimits.coachingLimit(tier);
      final outfitLogsCount = response['outfit_logs_count'] as int? ?? 0;
      final outfitLogsLimit = TierLimits.outfitLogLimit(tier);

      return {
        'tier': tier,
        'isPremium': tier == 'premium',
        'daily_suggestions_used': suggestionsUsed,
        'suggestions_limit': suggestionsLimit,
        'suggestions_remaining': suggestionsLimit - suggestionsUsed,
        'coaching_used': coachingUsed,
        'coaching_limit': coachingLimit,
        'coaching_remaining': (coachingLimit - coachingUsed).clamp(0, coachingLimit),
        'coaching_period': tier == 'premium' ? 'this month' : 'this week',
        'outfit_logs_count': outfitLogsCount,
        'outfit_logs_limit': outfitLogsLimit,
        'outfit_logs_remaining': (outfitLogsLimit - outfitLogsCount).clamp(0, outfitLogsLimit),
      };
    } catch (e) {
      return {
        'tier': 'free',
        'isPremium': false,
        'daily_suggestions_used': 0,
        'suggestions_limit': TierLimits.essentialDailySuggestions,
        'suggestions_remaining': TierLimits.essentialDailySuggestions,
        'coaching_used': 0,
        'coaching_limit': TierLimits.essentialCoachingPerWeek,
        'coaching_remaining': TierLimits.essentialCoachingPerWeek,
        'coaching_period': 'this week',
        'outfit_logs_count': 0,
        'outfit_logs_limit': TierLimits.essentialOutfitLogs,
        'outfit_logs_remaining': TierLimits.essentialOutfitLogs,
      };
    }
  }

  /// Upgrade user to Signature (premium) tier
  Future<bool> upgradeToPremium(String userId) async {
    try {
      await _supabase.from('user_profiles').update({
        'tier': 'premium',
      }).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}