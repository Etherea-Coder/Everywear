import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './user_tier_service.dart';

/// Service for managing outfit logs with Supabase
class OutfitLogService {
  SupabaseClient get _client => SupabaseService.instance.client;

  /// Fetch outfit logs for a specific date
  Future<List<Map<String, dynamic>>> fetchOutfitLogsForDate(
      DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      final logs = await _client
          .from('outfit_logs')
          .select('''
            id, outfit_name, worn_date, rating, notes, weather, occasion,
            outfit_items (
              item_id,
              wardrobe_items (
                id, name, category, image_url
              )
            )
          ''')
          .eq('user_id', userId)
          .gte('worn_date', startOfDay)
          .lte('worn_date', endOfDay)
          .order('worn_date', ascending: false);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching outfit logs: $e');
      return [];
    }
  }

  /// Fetch all dates that have outfit logs for a given month
  Future<List<String>> fetchLoggedDatesForMonth(DateTime month) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final startOfMonth =
          DateTime(month.year, month.month, 1).toIso8601String();
      final endOfMonth =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

      final logs = await _client
          .from('outfit_logs')
          .select('worn_date')
          .eq('user_id', userId)
          .gte('worn_date', startOfMonth)
          .lte('worn_date', endOfMonth);

      return List<Map<String, dynamic>>.from(logs)
          .map((log) {
            final date = DateTime.parse(log['worn_date']);
            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          })
          .toSet()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching logged dates: $e');
      return [];
    }
  }

  /// Fetch monthly stats
  Future<Map<String, dynamic>> fetchMonthlyStats(DateTime month) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'totalOutfits': 0, 'uniqueItems': 0, 'favoriteOccasion': 'None'};

      final startOfMonth =
          DateTime(month.year, month.month, 1).toIso8601String();
      final endOfMonth =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

      final logs = await _client
          .from('outfit_logs')
          .select('''
            id, occasion,
            outfit_items ( item_id )
          ''')
          .eq('user_id', userId)
          .gte('worn_date', startOfMonth)
          .lte('worn_date', endOfMonth);

      final logsList = List<Map<String, dynamic>>.from(logs);
      final totalOutfits = logsList.length;

      // Count unique items
      final Set<String> uniqueItems = {};
      for (final log in logsList) {
        final items = log['outfit_items'] as List<dynamic>? ?? [];
        for (final item in items) {
          uniqueItems.add(item['item_id'] as String);
        }
      }

      // Find favorite occasion
      final Map<String, int> occasionCount = {};
      for (final log in logsList) {
        final occasion = log['occasion'] as String? ?? 'Other';
        occasionCount[occasion] = (occasionCount[occasion] ?? 0) + 1;
      }
      final favoriteOccasion = occasionCount.isEmpty
          ? 'None'
          : occasionCount.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      return {
        'totalOutfits': totalOutfits,
        'uniqueItems': uniqueItems.length,
        'favoriteOccasion': favoriteOccasion,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching monthly stats: $e');
      return {'totalOutfits': 0, 'uniqueItems': 0, 'favoriteOccasion': 'None'};
    }
  }

  /// Create a new outfit log
  Future<String?> createOutfitLog({
    required String occasion,
    required List<String> itemIds,
    required DateTime wornDate,
    int? rating,
    String? notes,
    String? weather,
    String? outfitName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      // ── TIER CHECK ───────────────────────────────────────
      final tierService = UserTierService();
      final canLog = await tierService.canLogOutfit(userId);
      if (!canLog) {
        // Return a special sentinel value the UI can check
        return 'LIMIT_REACHED';
      }

      // Insert outfit log
      final log = await _client
          .from('outfit_logs')
          .insert({
            'user_id': userId,
            'outfit_name': outfitName ?? occasion,
            'worn_date': wornDate.toIso8601String(),
            'rating': rating,
            'notes': notes,
            'weather': weather,
            'occasion': occasion,
          })
          .select()
          .single();

      final outfitId = log['id'] as String;

      // Insert outfit items
      if (itemIds.isNotEmpty) {
        await _client.from('outfit_items').insert(
          itemIds
              .map((itemId) => {'outfit_id': outfitId, 'item_id': itemId})
              .toList(),
        );
      }

      // ── INCREMENT COUNT ──────────────────────────────────
      await tierService.incrementOutfitLogCount(userId);

      return outfitId;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating outfit log: $e');
      return null;
    }
  }

  /// Log the currently displayed outfit suggestion using known wardrobe item
  /// IDs. Called by "Save Displayed Outfit" when items were matched to real
  /// wardrobe entries.
  Future<String?> logOutfitWithItems({
    required DateTime wornDate,
    required List<String> itemIds,
    required String occasion,
    String? notes,
    String? outfitName,
  }) =>
      createOutfitLog(
        occasion: occasion,
        itemIds: itemIds,
        wornDate: wornDate,
        notes: notes,
        outfitName: outfitName,
      );

  /// Log the currently displayed outfit suggestion by name only, when the AI
  /// suggested items that are not yet in the user's wardrobe. Stores the item
  /// names as a JSON note so nothing is lost, but creates no outfit_items rows.
  Future<String?> logOutfitByName({
    required DateTime wornDate,
    required String outfitName,
    required String occasion,
    required List<String> itemNames,
    String? notes,
  }) {
    // Append the item names to the notes field so the log is still meaningful
    final itemSummary = itemNames.isNotEmpty
        ? 'Items: ${itemNames.join(', ')}'
        : null;
    final combinedNotes = [
      if (notes != null && notes.isNotEmpty) notes,
      if (itemSummary != null) itemSummary,
    ].join('\n');

    return createOutfitLog(
      occasion: occasion,
      itemIds: const [],       // no wardrobe links — items aren't in wardrobe yet
      wornDate: wornDate,
      notes: combinedNotes.isNotEmpty ? combinedNotes : null,
      outfitName: outfitName,
    );
  }

  /// Fetch recent outfit history for AI prompts (style-coach).
  /// Returns a compact list of the last [limit] outfits from the past [days] days.
  Future<List<Map<String, dynamic>>> fetchRecentOutfitHistory({
    int days = 7,
    int limit = 7,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();

      final logs = await _client
          .from('outfit_logs')
          .select('''
            worn_date, occasion, rating, outfit_name,
            outfit_items (
              wardrobe_items (
                name, category, color
              )
            )
          ''')
          .eq('user_id', userId)
          .gte('worn_date', since)
          .order('worn_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(logs).map((log) {
        final items = (log['outfit_items'] as List? ?? [])
            .map((oi) => oi['wardrobe_items'] as Map<String, dynamic>?)
            .where((w) => w != null)
            .map((w) => '${w!['name']} (${w['category'] ?? 'unknown'}${w['color'] != null ? ', ${w['color']}' : ''})')
            .toList();

        return {
          'date': log['worn_date'],
          'name': log['outfit_name'] ?? 'Unnamed outfit',
          'occasion': log['occasion'] ?? 'Other',
          'rating': log['rating'],
          'items': items,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching recent outfit history: $e');
      return [];
    }
  }
  /// Computes the average outfit rating for each wardrobe item.
  /// Joins outfit_logs (which have ratings) with outfit_items to attribute
  /// ratings to individual wardrobe items. Returns a map keyed by item_id.
  Future<Map<String, Map<String, dynamic>>> fetchItemRatingAverages() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      // Fetch all rated outfit logs with their items
      final logs = await _client
          .from('outfit_logs')
          .select('''
            rating,
            outfit_items (
              item_id
            )
          ''')
          .eq('user_id', userId)
          .not('rating', 'is', null);

      final logsList = List<Map<String, dynamic>>.from(logs);
      if (logsList.isEmpty) return {};

      // Accumulate ratings per item
      final Map<String, List<int>> itemRatings = {};
      for (final log in logsList) {
        final rating = log['rating'] as int?;
        if (rating == null) continue;
        final items = log['outfit_items'] as List? ?? [];
        for (final oi in items) {
          final itemId = oi['item_id'] as String?;
          if (itemId == null) continue;
          itemRatings.putIfAbsent(itemId, () => []).add(rating);
        }
      }

      // Compute averages
      final Map<String, Map<String, dynamic>> result = {};
      for (final entry in itemRatings.entries) {
        final ratings = entry.value;
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        result[entry.key] = {
          'avg_rating': double.parse(avg.toStringAsFixed(1)),
          'rated_count': ratings.length,
        };
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching item rating averages: $e');
      return {};
    }
  }
  /// Computes the silhouette evolution (fitted vs relaxed trend) over the
  /// last 3 months. Mirrors the logic in generate-ai-insights but runs
  /// client-side so it can be passed to style-coach prompts.
  Future<Map<String, dynamic>> fetchSilhouetteEvolution() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);

      final logs = await _client
          .from('outfit_logs')
          .select('''
            worn_date,
            outfit_items (
              wardrobe_items (
                id, name, semantic_label
              )
            )
          ''')
          .eq('user_id', userId)
          .gte('worn_date', threeMonthsAgo.toIso8601String());

      final logsList = List<Map<String, dynamic>>.from(logs);
      if (logsList.isEmpty) return {};

      const fittedKeywords = [
        'fitted', 'slim', 'skinny', 'tailored', 'formal',
        'structured', 'blazer', 'pencil',
      ];
      const relaxedKeywords = [
        'oversized', 'loose', 'relaxed', 'wide', 'baggy',
        'flowy', 'jogger', 'sweat', 'hoodie', 'casual',
      ];
      const monthLabels = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final evolution = <Map<String, dynamic>>[];

      for (int offset = 2; offset >= 0; offset--) {
        final monthDate = DateTime(now.year, now.month - offset, 1);
        int fitted = 0;
        int relaxed = 0;

        for (final log in logsList) {
          final wornDate = DateTime.tryParse(log['worn_date'] ?? '');
          if (wornDate == null ||
              wornDate.month != monthDate.month ||
              wornDate.year != monthDate.year) continue;

          final items = log['outfit_items'] as List? ?? [];
          for (final oi in items) {
            final w = oi['wardrobe_items'] as Map<String, dynamic>?;
            if (w == null) continue;
            final label = (w['semantic_label'] as String? ?? '').toLowerCase();
            if (fittedKeywords.any((k) => label.contains(k))) {
              fitted++;
            } else if (relaxedKeywords.any((k) => label.contains(k))) {
              relaxed++;
            }
          }
        }

        final total = fitted + relaxed;
        evolution.add({
          'month': monthLabels[monthDate.month - 1],
          'fitted': total > 0 ? (fitted / total * 100).round() : 0,
          'relaxed': total > 0 ? (relaxed / total * 100).round() : 0,
        });
      }

      // Generate a human-readable trend description
      String trend = 'stable';
      if (evolution.length >= 2) {
        final first = evolution.first;
        final last = evolution.last;
        final fittedDelta = (last['fitted'] as int) - (first['fitted'] as int);
        if (fittedDelta > 15) {
          trend = 'moving toward more fitted, structured silhouettes';
        } else if (fittedDelta < -15) {
          trend = 'gravitating toward more relaxed, comfortable fits';
        }
      }

      return {
        'months': evolution,
        'trend': trend,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching silhouette evolution: $e');
      return {};
    }
  }

  /// Aggregates occasion frequency broken down by weekday vs weekend
  /// from the last [days] days of outfit logs. Used by AI prompts.
  Future<Map<String, dynamic>> fetchOccasionPatterns({int days = 60}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();

      final logs = await _client
          .from('outfit_logs')
          .select('occasion, worn_date')
          .eq('user_id', userId)
          .gte('worn_date', since);

      final logsList = List<Map<String, dynamic>>.from(logs);
      if (logsList.isEmpty) return {};

      final Map<String, int> weekdayCounts = {};
      final Map<String, int> weekendCounts = {};
      final Map<String, int> overallCounts = {};

      for (final log in logsList) {
        final occasion = log['occasion'] as String? ?? 'Other';
        final date = DateTime.tryParse(log['worn_date'] ?? '');
        overallCounts[occasion] = (overallCounts[occasion] ?? 0) + 1;

        if (date != null) {
          final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
          if (isWeekend) {
            weekendCounts[occasion] = (weekendCounts[occasion] ?? 0) + 1;
          } else {
            weekdayCounts[occasion] = (weekdayCounts[occasion] ?? 0) + 1;
          }
        }
      }

      return {
        'weekday': weekdayCounts,
        'weekend': weekendCounts,
        'overall': overallCounts,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching occasion patterns: $e');
      return {};
    }
  }

  /// Update an existing outfit log
  Future<bool> updateOutfitLog({
    required String outfitId,
    String? occasion,
    int? rating,
    String? notes,
    String? outfitName,
    List<String>? itemIds,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (occasion != null) updates['occasion'] = occasion;
      if (rating != null) updates['rating'] = rating;
      if (notes != null) updates['notes'] = notes;
      if (outfitName != null) updates['outfit_name'] = outfitName;

      if (updates.isNotEmpty) {
        await _client
            .from('outfit_logs')
            .update(updates)
            .eq('id', outfitId);
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating outfit log: $e');
      return false;
    }
  }

  /// Delete an outfit log
  Future<bool> deleteOutfitLog(String outfitId) async {
    try {
      await _client.from('outfit_logs').delete().eq('id', outfitId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting outfit log: $e');
      return false;
    }
  }

  /// Repeat a previous outfit (creates a new log for today)
  Future<String?> repeatOutfitLog(String outfitId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      // Fetch original outfit
      final original = await _client
          .from('outfit_logs')
          .select('''
            outfit_name, occasion, notes, weather,
            outfit_items ( item_id )
          ''')
          .eq('id', outfitId)
          .single();

      final itemIds = (original['outfit_items'] as List<dynamic>)
          .map((item) => item['item_id'] as String)
          .toList();

      // Create new log for today
      return createOutfitLog(
        occasion: original['occasion'] ?? 'Other',
        itemIds: itemIds,
        wornDate: DateTime.now(),
        notes: original['notes'],
        weather: original['weather'],
        outfitName: original['outfit_name'],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error repeating outfit log: $e');
      return null;
    }
  }
}