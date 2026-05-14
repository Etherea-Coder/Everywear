import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import '../core/tier_limits.dart';

/// Service for managing user tier limits and usage tracking.
/// All limit checks go through this service — never check limits inline.
///
/// ## Security Design Principle
///
/// All `canX()` methods return **false** on error (deny-by-default).
/// This prevents free users from bypassing paywalls when the backend
/// is unreachable. Callers should check [lastCheckError] to distinguish
/// "limit reached" from "service unavailable" and show appropriate UI.
class UserTierService {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  // ── ERROR TRACKING ────────────────────────────────────────

  /// If the most recent `canX()` check failed due to a network or
  /// server error (rather than the user simply hitting their limit),
  /// this will contain a short description of the error.
  ///
  /// Reset to `null` at the start of every check. Callers can use
  /// this to show "Service temporarily unavailable" instead of
  /// "Limit reached" when this is non-null.
  ///
  /// Example:
  /// ```dart
  /// final canSuggest = await userTier.canRequestSuggestion(userId);
  /// if (!canSuggest) {
  ///   if (userTier.lastCheckError != null) {
  ///     showSnackBar('Service unavailable — try again later');
  ///   } else {
  ///     showUpgradePrompt();
  ///   }
  /// }
  /// ```
  String? lastCheckError;

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
      // Safe fallback: unknown tier is treated as free.
      // This is not a limit check, so returning 'free' is correct.
      return 'free';
    }
  }

  /// Returns true if the current user is on the Signature (premium) plan
  Future<bool> isPremium() async {
    final tier = await getUserTier();
    return tier == 'premium';
  }

  // ── OUTFIT LOGS ─────────────────────────────────────────

  /// Returns true if user can still create a new outfit log.
  ///
  /// Returns **false** if the check fails, so a backend outage does NOT
  /// let free users log unlimited outfits. Check [lastCheckError] to
  /// distinguish "limit reached" from "service unavailable".
  Future<bool> canLogOutfit(String userId) async {
    lastCheckError = null;
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
      if (kDebugMode) debugPrint('canLogOutfit check failed: $e');
      lastCheckError = e.toString();
      // FIX: Deny by default — a failed check must not bypass the paywall.
      return false;
    }
  }

  /// Increments the outfit log count after a successful log
  Future<void> incrementOutfitLogCount(String userId) async {
    try {
      await _supabase.rpc(
        'increment_outfit_log_count',
        params: {'user_id_input': userId},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('incrementOutfitLogCount failed: $e');
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

  /// Returns true if user can request another suggestion today.
  /// Uses atomic edge function to avoid TOCTOU race condition.
  ///
  /// Returns **false** if the check fails, so a backend outage does NOT
  /// let free users request unlimited suggestions. Check [lastCheckError]
  /// to distinguish "limit reached" from "service unavailable".
  Future<bool> canRequestSuggestion(String userId) async {
    lastCheckError = null;
    try {
      final response = await _supabase.functions.invoke(
        'check-and-request-suggestion',
      );
      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Check failed';
        throw Exception(error);
      }
      return response.data?['allowed'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('canRequestSuggestion check failed: $e');
      lastCheckError = e.toString();
      // FIX: Deny by default — a failed check must not bypass the paywall.
      // Previously returned true, allowing over-limit requests when the
      // edge function was unreachable.
      return false;
    }
  }

  // ── AI COACHING ─────────────────────────────────────────

  /// Returns true if user can ask the coach a question.
  /// Essential: 1 per week, Signature: 50 per month.
  ///
  /// Returns **false** if the check fails, so a backend outage does NOT
  /// let free users bypass coaching limits. Check [lastCheckError] to
  /// distinguish "limit reached" from "service unavailable".
  Future<bool> canUseCoach(String userId) async {
    lastCheckError = null;
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
        await _supabase
            .from('user_profiles')
            .update({
              'coaching_sessions_used': 0,
              'coaching_reset_at': now.toIso8601String(),
            })
            .eq('id', userId);
        return true;
      }

      return used < limit;
    } catch (e) {
      if (kDebugMode) debugPrint('canUseCoach check failed: $e');
      lastCheckError = e.toString();
      // FIX: Deny by default — a failed check must not bypass the paywall.
      // Previously returned true, allowing unlimited coaching when the
      // backend was unreachable.
      return false;
    }
  }

  /// Increments coaching session count
  Future<void> incrementCoachingCount(String userId) async {
    try {
      await _supabase.rpc(
        'increment_coaching_sessions',
        params: {'user_id_input': userId},
      );
    } catch (e) {
      // RPC failed — fall back to safe read-then-write
      try {
        final response = await _supabase
            .from('user_profiles')
            .select('coaching_sessions_used')
            .eq('id', userId)
            .single();
        final current = response['coaching_sessions_used'] as int? ?? 0;
        await _supabase
            .from('user_profiles')
            .update({'coaching_sessions_used': current + 1})
            .eq('id', userId);
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('incrementCoachingCount fallback failed: $e2');
        }
      }
    }
  }

  /// Returns remaining coaching sessions for display in UI.
  ///
  /// On error, returns **0 remaining** so the UI never misleads the user
  /// into thinking they have quota when the service is down.
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
      if (kDebugMode) debugPrint('getCoachingQuota failed: $e');
      // FIX: Return 0 remaining on error instead of full quota.
      // Previously returned full remaining quota, which mislead users
      // into thinking they had access when the service was down.
      return {
        'used': 0,
        'limit': TierLimits.essentialCoachingPerWeek,
        'remaining': 0,
        'tier': 'free',
        'period': 'this week',
        'error': true,
      };
    }
  }

  // ── FULL TIER INFO ───────────────────────────────────────

  /// Returns comprehensive tier info for the current user.
  ///
  /// On error, returns **0 remaining** for all quotas so the UI never
  /// misleads the user into thinking they have access when the service
  /// is down.
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
      final suggestionsUsed =
          response['daily_suggestions_used'] as int? ?? 0;
      final suggestionsLimit = TierLimits.dailySuggestionLimit(tier);
      final coachingUsed =
          response['coaching_sessions_used'] as int? ?? 0;
      final coachingLimit = TierLimits.coachingLimit(tier);
      final outfitLogsCount =
          response['outfit_logs_count'] as int? ?? 0;
      final outfitLogsLimit = TierLimits.outfitLogLimit(tier);

      return {
        'tier': tier,
        'isPremium': tier == 'premium',
        'daily_suggestions_used': suggestionsUsed,
        'suggestions_limit': suggestionsLimit,
        'suggestions_remaining':
            (suggestionsLimit - suggestionsUsed).clamp(
          0,
          suggestionsLimit,
        ),
        'coaching_used': coachingUsed,
        'coaching_limit': coachingLimit,
        'coaching_remaining':
            (coachingLimit - coachingUsed).clamp(0, coachingLimit),
        'coaching_period':
            tier == 'premium' ? 'this month' : 'this week',
        'outfit_logs_count': outfitLogsCount,
        'outfit_logs_limit': outfitLogsLimit,
        'outfit_logs_remaining':
            (outfitLogsLimit - outfitLogsCount).clamp(
          0,
          outfitLogsLimit,
        ),
      };
    } catch (e) {
      if (kDebugMode) debugPrint('getUserTierInfo failed: $e');
      // FIX: Return 0 remaining on error instead of full quota.
      // Previously showed full remaining amounts, misleading users.
      return {
        'tier': 'free',
        'isPremium': false,
        'daily_suggestions_used': 0,
        'suggestions_limit': TierLimits.essentialDailySuggestions,
        'suggestions_remaining': 0,
        'coaching_used': 0,
        'coaching_limit': TierLimits.essentialCoachingPerWeek,
        'coaching_remaining': 0,
        'coaching_period': 'this week',
        'outfit_logs_count': 0,
        'outfit_logs_limit': TierLimits.essentialOutfitLogs,
        'outfit_logs_remaining': 0,
        'error': true,
      };
    }
  }

  /// Upgrade user to Signature (premium) tier
  Future<bool> upgradeToPremium(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase.functions.invoke(
        'verify-purchase',
        body: {'revenue_cat_user_id': userId},
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Verification failed';
        throw Exception(error);
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('upgradeToPremium failed: $e');
      return false;
    }
  }
}
