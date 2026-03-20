import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class ProgressService {
  SupabaseClient get _client => SupabaseService.instance.client;

  // ── Streak ────────────────────────────────────────────────────────────────

  /// Calculates the current consecutive-day streak from outfit_logs.
  /// Also returns the longest streak ever recorded.
  Future<Map<String, int>> fetchStreakData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'current': 0, 'longest': 0};

      final rows = await _client
          .from('outfit_logs')
          .select('worn_date')
          .eq('user_id', userId)
          .order('worn_date', ascending: false);

      if (rows.isEmpty) return {'current': 0, 'longest': 0};

      // Collect unique dates (strip time component)
      final dates = rows
          .map((r) => DateTime.parse(r['worn_date'] as String))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // descending

      // Current streak: count backwards from today
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      int current = 0;
      DateTime expected = today;

      for (final date in dates) {
        if (date == expected || date == expected.subtract(const Duration(days: 1))) {
          // Allow today or yesterday as the start
          if (current == 0 && date == expected.subtract(const Duration(days: 1))) {
            expected = date;
          }
          if (date == expected) {
            current++;
            expected = expected.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else if (date.isBefore(expected)) {
          break;
        }
      }

      // Longest streak: scan all dates
      int longest = 0;
      int running = 1;
      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i - 1].difference(dates[i]).inDays;
        if (diff == 1) {
          running++;
          if (running > longest) longest = running;
        } else {
          running = 1;
        }
      }
      if (longest == 0 && dates.isNotEmpty) longest = 1;

      return {'current': current, 'longest': longest};
    } catch (e) {
      if (kDebugMode) debugPrint('fetchStreakData error: $e');
      return {'current': 0, 'longest': 0};
    }
  }

  // ── Active challenges ────────────────────────────────────────────────────

  /// Returns the user's active (not yet completed) challenges with full
  /// challenge details from style_challenges.
  Future<List<Map<String, dynamic>>> fetchActiveChallenges() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await _client
          .from('user_challenges')
          .select('''
            id,
            started_at,
            completed_at,
            progress,
            style_challenges (
              id,
              title,
              description,
              duration_days,
              goal,
              category,
              points,
              difficulty,
              icon,
              type
            )
          ''')
          .eq('user_id', userId)
          .isFilter('completed_at', null)
          .order('started_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map((row) {
        final challenge = row['style_challenges'] as Map<String, dynamic>? ?? {};
        final goal = (challenge['goal'] as int?) ?? 1;
        final progress = (row['progress'] as int?) ?? 0;
        final startedAt = DateTime.parse(row['started_at'] as String);
        final durationDays = (challenge['duration_days'] as int?) ?? 7;
        final dueDate = startedAt.add(Duration(days: durationDays));

        return {
          'id': row['id'],
          'title': challenge['title'] ?? '',
          'description': challenge['description'] ?? '',
          'type': challenge['type'] ?? challenge['category'] ?? 'general',
          'progress': goal > 0 ? (progress / goal).clamp(0.0, 1.0) : 0.0,
          'currentValue': progress,
          'targetValue': goal,
          'points': challenge['points'] ?? 0,
          'icon': challenge['icon'] ?? 'flag',
          'difficulty': challenge['difficulty'] ?? 'medium',
          'dueDate': dueDate,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('fetchActiveChallenges error: $e');
      return [];
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  /// Returns real stats derived from outfit_logs, wardrobe_items, purchases.
  Future<Map<String, dynamic>> fetchPersonalStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _emptyStats();

      final results = await Future.wait([
        // Total outfits logged
        _client
            .from('outfit_logs')
            .select('id')
            .eq('user_id', userId),

        // Total wardrobe items
        _client
            .from('wardrobe_items')
            .select('id')
            .eq('user_id', userId),

        // Purchases — for total spent
        _client
            .from('purchases')
            .select('price, purchase_date')
            .eq('user_id', userId),

        // Wardrobe items worn at least once (times_worn > 0)
        _client
            .from('wardrobe_items')
            .select('id, wear_count')
            .eq('user_id', userId),
      ]);

      final outfits = (results[0] as List).length;
      final wardrobeItems = results[1] as List;
      final purchases = results[2] as List;
      final itemsWithWear = results[3] as List;

      final totalItems = wardrobeItems.length;

      // Total amount spent on purchases
      final totalSpent = purchases.fold<double>(
        0,
        (sum, p) => sum + ((p['price'] as num?) ?? 0).toDouble(),
      );

      // Wardrobe utilization: % of items worn at least once
      final wornItems =
          itemsWithWear.where((i) => ((i['wear_count'] as int?) ?? 0) > 0).length;
      final utilization =
          totalItems > 0 ? ((wornItems / totalItems) * 100).round() : 0;

      // Cost per wear: total spent / total outfits logged
      final avgCostPerWear =
          outfits > 0 ? (totalSpent / outfits) : 0.0;

      // Purchases this month
      final now = DateTime.now();
      final thisMonthPurchases = purchases.where((p) {
        if (p['purchase_date'] == null) return false;
        final d = DateTime.parse(p['purchase_date'] as String);
        return d.year == now.year && d.month == now.month;
      }).length;

      return {
        'totalOutfitsLogged': outfits,
        'totalItems': totalItems,
        'totalSpent': totalSpent,
        'avgCostPerWear': double.parse(avgCostPerWear.toStringAsFixed(2)),
        'wardrobeUtilization': utilization,
        'purchasesThisMonth': thisMonthPurchases,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('fetchPersonalStats error: $e');
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() => {
        'totalOutfitsLogged': 0,
        'totalItems': 0,
        'totalSpent': 0.0,
        'avgCostPerWear': 0.0,
        'wardrobeUtilization': 0,
        'purchasesThisMonth': 0,
      };
}