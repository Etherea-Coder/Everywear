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

  @visibleForTesting
  static bool hasVerifiedPremiumAccess({
    required String? tier,
    required String? status,
    required String? expiresAt,
    DateTime? now,
  }) {
    if (tier != 'premium') return false;
    final instant = now ?? DateTime.now().toUtc();
    final expiry = expiresAt == null ? null : DateTime.tryParse(expiresAt);
    if (status == 'active') return expiry == null || expiry.isAfter(instant);
    return (status == 'grace_period' || status == 'cancelled') &&
        expiry != null &&
        expiry.isAfter(instant);
  }

  String _effectiveTier(Map<String, dynamic> profile) =>
      hasVerifiedPremiumAccess(
        tier: profile['tier'] as String?,
        status: profile['subscription_status'] as String?,
        expiresAt: profile['subscription_expires_at'] as String?,
      )
      ? 'premium'
      : 'free';

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
  Future<String> getUserTier({String? expectedUserId}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null ||
          (expectedUserId != null && user.id != expectedUserId)) {
        return 'free';
      }
      final response = await _supabase
          .from('user_profiles')
          .select('tier, subscription_status, subscription_expires_at')
          .eq('id', user.id)
          .single();
      if (_supabase.auth.currentUser?.id != user.id) return 'free';
      return _effectiveTier(response);
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
          .select(
            'tier, subscription_status, subscription_expires_at, outfit_logs_count',
          )
          .eq('id', userId)
          .single();
      final tier = _effectiveTier(response);
      final count = response['outfit_logs_count'] as int? ?? 0;
      return count < TierLimits.outfitLogLimit(tier);
    } catch (e) {
      if (kDebugMode) debugPrint('canLogOutfit check failed: $e');
      lastCheckError = e.toString();
      // FIX: Deny by default — a failed check must not bypass the paywall.
      return false;
    }
  }

  /// Retained for source compatibility. The database trigger maintains this
  /// counter after a successful outfit-log insert or delete.
  @Deprecated('Counter is maintained by the outfit_logs database trigger')
  Future<void> incrementOutfitLogCount(String userId) async {
    return;
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
          .select(
            'tier, subscription_status, subscription_expires_at, coaching_sessions_used, coaching_reset_at',
          )
          .eq('id', userId)
          .single();

      final tier = _effectiveTier(response);
      final limit = TierLimits.coachingLimit(tier);
      final used = response['coaching_sessions_used'] as int? ?? 0;

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

  /// Retained for source compatibility. Quota is consumed atomically by the
  /// authenticated style-coach Edge Function, never by the client.
  @Deprecated('Quota is enforced by the style-coach Edge Function')
  Future<void> incrementCoachingCount(String userId) async {
    return;
  }

  /// Returns remaining coaching sessions for display in UI.
  ///
  /// On error, returns **0 remaining** so the UI never misleads the user
  /// into thinking they have quota when the service is down.
  Future<Map<String, dynamic>> getCoachingQuota(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select(
            'tier, subscription_status, subscription_expires_at, coaching_sessions_used, coaching_reset_at',
          )
          .eq('id', userId)
          .single();
      final tier = _effectiveTier(response);
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
            'tier, subscription_status, subscription_expires_at, daily_suggestions_used, '
            'suggestions_reset_at, coaching_sessions_used, coaching_reset_at, '
            'outfit_logs_count',
          )
          .eq('id', userId)
          .single();

      final tier = _effectiveTier(response);
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
        'suggestions_remaining': (suggestionsLimit - suggestionsUsed).clamp(
          0,
          suggestionsLimit,
        ),
        'coaching_used': coachingUsed,
        'coaching_limit': coachingLimit,
        'coaching_remaining': (coachingLimit - coachingUsed).clamp(
          0,
          coachingLimit,
        ),
        'coaching_period': tier == 'premium' ? 'this month' : 'this week',
        'outfit_logs_count': outfitLogsCount,
        'outfit_logs_limit': outfitLogsLimit,
        'outfit_logs_remaining': (outfitLogsLimit - outfitLogsCount).clamp(
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
      if (user == null || user.id != userId) return false;

      final response = await _supabase.functions.invoke('verify-purchase');

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
