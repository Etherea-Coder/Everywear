/// Single source of truth for all Essential vs Signature tier limits.
/// Never hardcode limits elsewhere — always reference this file.
class TierLimits {
  TierLimits._();

  // ── OUTFIT LOGS ─────────────────────────────────────────
  static const int essentialOutfitLogs = 30;
  static const int signatureOutfitLogs = 100;

  // ── DAILY SUGGESTIONS ───────────────────────────────────
  static const int essentialDailySuggestions = 1;
  static const int signatureDailySuggestions = 999; // effectively unlimited

  // ── AI COACHING ─────────────────────────────────────────
  static const int essentialCoachingPerWeek = 1;
  static const int signatureCoachingPerMonth = 50;

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
  static int itemsLimit(String tier) =>
      tier == 'premium' ? 999999 : 999999;

  /// Returns the daily suggestion limit for a given tier
  static int dailySuggestionLimit(String tier) =>
      tier == 'premium' ? signatureDailySuggestions : essentialDailySuggestions;

  /// Returns the coaching limit for a given tier
  /// Essential: per week, Signature: per month
  static int coachingLimit(String tier) =>
      tier == 'premium' ? signatureCoachingPerMonth : essentialCoachingPerWeek;
}