/// Single source of truth for all Essential vs Signature tier limits.
/// Never hardcode limits elsewhere — always reference this file.
class TierLimits {
  TierLimits._();

  // ── OUTFIT LOGS ─────────────────────────────────────────
  static const int essentialOutfitLogs = 30;
  static const int signatureOutfitLogs = 100;

  // Provisional server policy. These are not published commercial promises.
  static const int essentialMonthlyAiActions = 20;
  static const int signatureMonthlyAiActions = 200;
  static const int essentialDailyAiActions = 3;
  static const int signatureDailyAiActions = 20;

  // Kept for old UI call sites; all AI features now share one allowance.
  static const int essentialDailySuggestions = essentialDailyAiActions;
  static const int signatureDailySuggestions = signatureDailyAiActions;

  // ── AI COACHING ─────────────────────────────────────────
  static const int essentialCoachingPerWeek = essentialMonthlyAiActions;
  static const int signatureCoachingPerMonth = signatureMonthlyAiActions;

  // ── WARDROBE ITEMS ──────────────────────────────────────
  // Items are unlimited for both tiers as of v1
  // Limits apply to outfit logs instead
  // (Removed: essentialItemsLimit = 30)
  // (Removed: signatureItemsLimit = 100)

  /// Returns the outfit log limit for a given tier
  static int outfitLogLimit(String tier) =>
      tier == 'premium' ? signatureOutfitLogs : essentialOutfitLogs;

  /// Items are unlimited — this method returns a very large number
  /// but the actual enforcement should check against unlimited
  static int itemsLimit(String tier) => tier == 'premium' ? 999999 : 999999;

  /// Returns the daily suggestion limit for a given tier
  static int dailySuggestionLimit(String tier) =>
      tier == 'premium' ? signatureDailySuggestions : essentialDailySuggestions;

  /// Returns the coaching limit for a given tier
  /// Compatibility getter for the shared monthly AI action allowance.
  static int coachingLimit(String tier) =>
      tier == 'premium' ? signatureCoachingPerMonth : essentialCoachingPerWeek;
}
