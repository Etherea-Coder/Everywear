import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import './supabase_service.dart';

class DailyLogService {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation().timeout(const Duration(seconds: 10));
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        debugPrint('DailyLog operation failed, retrying in ${delay.inSeconds}s... (attempt $attempts/$maxRetries)');
        await Future.delayed(delay);
        delay *= 2;
      }
    }

    throw Exception('Max retries reached');
  }

  Future<List<Map<String, dynamic>>> fetchOutfitEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _retryOperation(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) return [];

        var query = _client
            .from('outfit_logs')
            .select('*, outfit_items(*, wardrobe_items(*))')
            .eq('user_id', userId);

        if (startDate != null) {
          query = query.gte('worn_date', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('worn_date', endDate.toIso8601String());
        }

        final response = await query.order('worn_date', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('DailyLog fetch error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createOutfitEntry({
    required List<String> itemIds,
    String? outfitName,
    int? rating,
    String? notes,
    String? weather,
    String? occasion,
    DateTime? wornDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final outfitLog = await _client
          .from('outfit_logs')
          .insert({
            'user_id': userId,
            'outfit_name': outfitName,
            'rating': rating,
            'notes': notes,
            'weather': weather,
            'occasion': occasion,
            'worn_date': (wornDate ?? DateTime.now()).toIso8601String(),
          })
          .select()
          .single();

      try {
        final outfitItems = itemIds
            .map((itemId) => {'outfit_id': outfitLog['id'], 'item_id': itemId})
            .toList();

        await _client.from('outfit_items').insert(outfitItems);
      } catch (itemInsertError) {
        debugPrint('Failed to insert outfit items, rolling back outfit log: $itemInsertError');
        try {
          await _client.from('outfit_logs').delete().eq('id', outfitLog['id']);
        } catch (_) {}
        return {'success': false, 'error': 'Failed to create outfit entry: item association failed'};
      }

      return {'success': true, 'entry': outfitLog};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> deleteOutfitEntry(String entryId) async {
    try {
      await _client.from('outfit_items').delete().eq('outfit_id', entryId);
      await _client.from('outfit_logs').delete().eq('id', entryId);
    } catch (e) {
      throw Exception('Failed to delete outfit entry: $e');
    }
  }

  Future<Map<String, dynamic>?> updateOutfitEntry({
    required String entryId,
    String? outfitName,
    int? rating,
    String? notes,
    String? occasion,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (outfitName != null) updateData['outfit_name'] = outfitName;
      if (rating != null) updateData['rating'] = rating;
      if (notes != null) updateData['notes'] = notes;
      if (occasion != null) updateData['occasion'] = occasion;

      if (updateData.isEmpty) return null;

      final response = await _client
          .from('outfit_logs')
          .update(updateData)
          .eq('id', entryId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update outfit entry: $e');
    }
  }

  Future<Map<String, dynamic>> getMonthlyStats(DateTime month) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'total_outfits': 0, 'unique_items': 0, 'favorite_occasion': 'None', 'avg_rating': 0.0};
      }

      final startDate = DateTime(month.year, month.month, 1).toIso8601String();
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

      final response = await _client
          .from('outfit_logs')
          .select('occasion, rating, outfit_items(wardrobe_items(id))')
          .eq('user_id', userId)
          .gte('worn_date', startDate)
          .lte('worn_date', endDate);

      final totalOutfits = response.length;
      final Set<String> uniqueItems = {};
      final Map<String, int> occasionCount = {};
      double totalRating = 0;

      for (final entry in response) {
        final occasion = entry['occasion'] as String?;
        if (occasion != null) {
          occasionCount[occasion] = (occasionCount[occasion] ?? 0) + 1;
        }
        final rating = entry['rating'] as int?;
        if (rating != null) totalRating += rating;

        final outfitItems = entry['outfit_items'] as List<dynamic>?;
        if (outfitItems != null) {
          for (final item in outfitItems) {
            final wardrobeItem = item['wardrobe_items'] as Map<String, dynamic>?;
            if (wardrobeItem != null && wardrobeItem['id'] != null) {
              uniqueItems.add(wardrobeItem['id'].toString());
            }
          }
        }
      }

      String favoriteOccasion = 'None';
      if (occasionCount.isNotEmpty) {
        favoriteOccasion = occasionCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      return {
        'total_outfits': totalOutfits,
        'unique_items': uniqueItems.length,
        'favorite_occasion': favoriteOccasion,
        'avg_rating': totalOutfits > 0 ? totalRating / totalOutfits : 0.0,
      };
    } catch (e) {
      debugPrint('Monthly stats error: $e');
      return {'total_outfits': 0, 'unique_items': 0, 'favorite_occasion': 'None', 'avg_rating': 0.0};
    }
  }

  RealtimeChannel subscribeToOutfitChanges({
    required void Function(PostgresChangePayload payload) onInsert,
    required void Function(PostgresChangePayload payload) onUpdate,
    required void Function(PostgresChangePayload payload) onDelete,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to subscribe to changes');
    }

    return _client
        .channel('outfit_log_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'outfit_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: onInsert,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'outfit_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: onUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'outfit_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: onDelete,
        )
        .subscribe();
  }
}
