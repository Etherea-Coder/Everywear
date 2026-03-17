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
      debugPrint('Error fetching outfit logs: $e');
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
      debugPrint('Error fetching logged dates: $e');
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
      debugPrint('Error fetching monthly stats: $e');
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
      debugPrint('Error creating outfit log: $e');
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
      debugPrint('Error updating outfit log: $e');
      return false;
    }
  }

  /// Delete an outfit log
  Future<bool> deleteOutfitLog(String outfitId) async {
    try {
      await _client.from('outfit_logs').delete().eq('id', outfitId);
      return true;
    } catch (e) {
      debugPrint('Error deleting outfit log: $e');
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
      debugPrint('Error repeating outfit log: $e');
      return null;
    }
  }
}