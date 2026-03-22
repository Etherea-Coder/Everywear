import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Derives achievements entirely from existing Supabase data.
/// No new table needed — everything is computed from outfit_logs, purchases, wardrobe_items.
class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<Map<String, dynamic>>> fetchAchievements() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _buildAchievements({});

      final results = await Future.wait([
        // Total outfit logs
        _client
            .from('outfit_logs')
            .select('id, worn_date')
            .eq('user_id', userId),
        // Purchases with notes
        _client
            .from('purchases')
            .select('id, notes')
            .eq('user_id', userId),
        // Wardrobe items with wear_count and last_worn
        _client
            .from('wardrobe_items')
            .select('id, wear_count, last_worn')
            .eq('user_id', userId),
        // Rated outfit logs
        _client
            .from('outfit_logs')
            .select('id, rating')
            .eq('user_id', userId)
            .not('rating', 'is', null),
      ]);

      final logs = (results[0] as List).cast<Map<String, dynamic>>();
      final purchases = (results[1] as List).cast<Map<String, dynamic>>();
      final wardrobeItems = (results[2] as List).cast<Map<String, dynamic>>();
      final ratedLogs = (results[3] as List).cast<Map<String, dynamic>>();

      // ── Compute stats ──────────────────────────────────────────────────
      final totalOutfits = logs.length;
      final totalPurchases = purchases.length;
      final purchasesWithNotes =
          purchases.where((p) => (p['notes'] as String? ?? '').isNotEmpty).length;

      // Streak calculation
      final streak = _computeStreak(logs);

      // Unique days logged
      final uniqueDays = logs
          .map((l) => DateTime.parse(l['worn_date'] as String))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .length;

      // All wardrobe items worn at least once
      final totalItems = wardrobeItems.length;
      final wornItems =
          wardrobeItems.where((i) => (i['wear_count'] as int? ?? 0) > 0).length;

      // High-value items (wear_count >= 10)
      final highValueItems =
          wardrobeItems.where((i) => (i['wear_count'] as int? ?? 0) >= 10).length;

      // Outfit ratings given
      final ratingsGiven = ratedLogs.length;

      final stats = {
        'totalOutfits': totalOutfits,
        'totalPurchases': totalPurchases,
        'purchasesWithNotes': purchasesWithNotes,
        'currentStreak': streak,
        'uniqueDays': uniqueDays,
        'totalItems': totalItems,
        'wornItems': wornItems,
        'highValueItems': highValueItems,
        'ratingsGiven': ratingsGiven,
      };

      return _buildAchievements(stats);
    } catch (e) {
      if (kDebugMode) debugPrint('AchievementService.fetchAchievements error: $e');
      return _buildAchievements({});
    }
  }

  int _computeStreak(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;
    final dates = logs
        .map((r) => DateTime.parse(r['worn_date'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int streak = 0;
    DateTime expected = today;
    for (final date in dates) {
      if (date == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (date == today.subtract(const Duration(days: 1)) && streak == 0) {
        streak++;
        expected = date.subtract(const Duration(days: 1));
      } else if (date.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  List<Map<String, dynamic>> _buildAchievements(Map<String, dynamic> stats) {
    final totalOutfits = stats['totalOutfits'] as int? ?? 0;
    final totalPurchases = stats['totalPurchases'] as int? ?? 0;
    final purchasesWithNotes = stats['purchasesWithNotes'] as int? ?? 0;
    final currentStreak = stats['currentStreak'] as int? ?? 0;
    final uniqueDays = stats['uniqueDays'] as int? ?? 0;
    final totalItems = stats['totalItems'] as int? ?? 0;
    final wornItems = stats['wornItems'] as int? ?? 0;
    final highValueItems = stats['highValueItems'] as int? ?? 0;
    final ratingsGiven = stats['ratingsGiven'] as int? ?? 0;

    return [
      // ── Consistency ──────────────────────────────────────────────────────
      {
        'id': '1',
        'title': 'First Steps',
        'description': 'Logged your first outfit',
        'category': 'Consistency',
        'icon': 'emoji_events',
        'rarity': 'Common',
        'requirement': 'Log 1 outfit',
        'backstory': 'Every journey begins with a single step. You\'ve started your mindful fashion journey!',
        'relatedChallenges': ['Daily Logger'],
        'isUnlocked': totalOutfits >= 1,
        'progress': (totalOutfits / 1).clamp(0.0, 1.0),
        'unlockedDate': totalOutfits >= 1 ? DateTime.now() : null,
      },
      {
        'id': '2',
        'title': 'Week Warrior',
        'description': 'Logged outfits for 7 consecutive days',
        'category': 'Consistency',
        'icon': 'local_fire_department',
        'rarity': 'Rare',
        'requirement': 'Log outfits for 7 days straight',
        'backstory': 'Consistency is the foundation of mindful living. Your dedication is inspiring!',
        'relatedChallenges': ['Streak Master'],
        'isUnlocked': currentStreak >= 7,
        'progress': (currentStreak / 7).clamp(0.0, 1.0),
        'unlockedDate': currentStreak >= 7 ? DateTime.now() : null,
      },
      {
        'id': '3',
        'title': 'Monthly Milestone',
        'description': 'Logged outfits on 30 different days',
        'category': 'Consistency',
        'icon': 'calendar_month',
        'rarity': 'Uncommon',
        'requirement': 'Log outfits on 30 days',
        'backstory': 'A month of mindfulness is a powerful achievement. You\'re building lasting change!',
        'relatedChallenges': ['Commitment Champion'],
        'isUnlocked': uniqueDays >= 30,
        'progress': (uniqueDays / 30).clamp(0.0, 1.0),
        'unlockedDate': uniqueDays >= 30 ? DateTime.now() : null,
      },
      {
        'id': '4',
        'title': 'Century Club',
        'description': 'Logged 100 outfits',
        'category': 'Consistency',
        'icon': 'military_tech',
        'rarity': 'Epic',
        'requirement': 'Log 100 total outfits',
        'backstory': 'Persistence creates transformation. You\'re building lasting habits!',
        'relatedChallenges': ['Long Hauler'],
        'isUnlocked': totalOutfits >= 100,
        'progress': (totalOutfits / 100).clamp(0.0, 1.0),
        'unlockedDate': totalOutfits >= 100 ? DateTime.now() : null,
      },

      // ── Style ────────────────────────────────────────────────────────────
      {
        'id': '5',
        'title': 'Style Innovator',
        'description': 'Created 10 unique outfit logs',
        'category': 'Style',
        'icon': 'palette',
        'rarity': 'Uncommon',
        'requirement': 'Log 10 different outfits',
        'backstory': 'Creativity flourishes when you explore your wardrobe\'s potential!',
        'relatedChallenges': ['Mix Master'],
        'isUnlocked': totalOutfits >= 10,
        'progress': (totalOutfits / 10).clamp(0.0, 1.0),
        'unlockedDate': totalOutfits >= 10 ? DateTime.now() : null,
      },
      {
        'id': '6',
        'title': 'Wardrobe Optimizer',
        'description': 'Wore every wardrobe item at least once',
        'category': 'Style',
        'icon': 'check_circle',
        'rarity': 'Rare',
        'requirement': 'Wear all wardrobe items',
        'backstory': 'Every piece deserves its moment. You\'re maximizing your wardrobe\'s potential!',
        'relatedChallenges': ['Full Utilization'],
        'isUnlocked': totalItems > 0 && wornItems >= totalItems,
        'progress': totalItems > 0 ? (wornItems / totalItems).clamp(0.0, 1.0) : 0.0,
        'unlockedDate': (totalItems > 0 && wornItems >= totalItems) ? DateTime.now() : null,
      },
      {
        'id': '7',
        'title': 'Power Dresser',
        'description': 'Have 3 items worn 10+ times each',
        'category': 'Style',
        'icon': 'star',
        'rarity': 'Rare',
        'requirement': '3 items with 10+ wears',
        'backstory': 'You know your staples. These pieces are the backbone of your wardrobe!',
        'relatedChallenges': ['Staple Finder'],
        'isUnlocked': highValueItems >= 3,
        'progress': (highValueItems / 3).clamp(0.0, 1.0),
        'unlockedDate': highValueItems >= 3 ? DateTime.now() : null,
      },
      {
        'id': '8',
        'title': 'Style Critic',
        'description': 'Rated 10 outfits',
        'category': 'Style',
        'icon': 'rate_review',
        'rarity': 'Common',
        'requirement': 'Rate 10 outfits',
        'backstory': 'Self-awareness is the first step to better style. Keep reflecting!',
        'relatedChallenges': ['Thoughtful Dresser'],
        'isUnlocked': ratingsGiven >= 10,
        'progress': (ratingsGiven / 10).clamp(0.0, 1.0),
        'unlockedDate': ratingsGiven >= 10 ? DateTime.now() : null,
      },

      // ── Mindful ──────────────────────────────────────────────────────────
      {
        'id': '9',
        'title': 'Mindful Shopper',
        'description': 'Tracked 5 purchases with reflection notes',
        'category': 'Mindful',
        'icon': 'shopping_bag',
        'rarity': 'Uncommon',
        'requirement': 'Log 5 purchases with notes',
        'backstory': 'Mindful consumption starts with awareness. You\'re making intentional choices!',
        'relatedChallenges': ['Thoughtful Buyer'],
        'isUnlocked': purchasesWithNotes >= 5,
        'progress': (purchasesWithNotes / 5).clamp(0.0, 1.0),
        'unlockedDate': purchasesWithNotes >= 5 ? DateTime.now() : null,
      },
      {
        'id': '10',
        'title': 'Wardrobe Curator',
        'description': 'Added 20 items to your wardrobe',
        'category': 'Mindful',
        'icon': 'collections_bookmark',
        'rarity': 'Common',
        'requirement': 'Have 20 wardrobe items',
        'backstory': 'A curated wardrobe is a joy to dress from every morning!',
        'relatedChallenges': ['Collection Builder'],
        'isUnlocked': totalItems >= 20,
        'progress': (totalItems / 20).clamp(0.0, 1.0),
        'unlockedDate': totalItems >= 20 ? DateTime.now() : null,
      },

      // ── Sustainability ───────────────────────────────────────────────────
      {
        'id': '11',
        'title': 'Sustainability Champion',
        'description': 'Logged 50+ outfits (maximizing what you own)',
        'category': 'Sustainability',
        'icon': 'eco',
        'rarity': 'Epic',
        'requirement': 'Log 50 outfits',
        'backstory': 'True sustainability means maximizing what you already own!',
        'relatedChallenges': ['Eco Warrior'],
        'isUnlocked': totalOutfits >= 50,
        'progress': (totalOutfits / 50).clamp(0.0, 1.0),
        'unlockedDate': totalOutfits >= 50 ? DateTime.now() : null,
      },
      {
        'id': '12',
        'title': 'Purchase Conscious',
        'description': 'Tracked 10 purchases mindfully',
        'category': 'Sustainability',
        'icon': 'savings',
        'rarity': 'Uncommon',
        'requirement': 'Log 10 purchases',
        'backstory': 'Tracking your spending is the first step to a more intentional wardrobe!',
        'relatedChallenges': ['Budget Aware'],
        'isUnlocked': totalPurchases >= 10,
        'progress': (totalPurchases / 10).clamp(0.0, 1.0),
        'unlockedDate': totalPurchases >= 10 ? DateTime.now() : null,
      },
    ];
  }
}