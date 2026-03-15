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
  static const int essentialItemsLimit = 30;
  static const int signatureItemsLimit = 100;

  /// Returns the outfit log limit for a given tier
  static int outfitLogLimit(String tier) =>
      tier == 'premium' ? signatureOutfitLogs : essentialOutfitLogs;

  /// Returns the items limit for a given tier
  static int itemsLimit(String tier) =>
      tier == 'premium' ? signatureItemsLimit : essentialItemsLimit;

  /// Returns the daily suggestion limit for a given tier
  static int dailySuggestionLimit(String tier) =>
      tier == 'premium' ? signatureDailySuggestions : essentialDailySuggestions;

  /// Returns the coaching limit for a given tier
  /// Essential: per week, Signature: per month
  static int coachingLimit(String tier) =>
      tier == 'premium' ? signatureCoachingPerMonth : essentialCoachingPerWeek;
}