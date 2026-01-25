import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../services/user_tier_service.dart';
import './supabase_service.dart';

/// Service layer for wardrobe management with real-time synchronization
/// Provides CRUD operations and real-time subscription capabilities
class WardrobeService {
  SupabaseClient get _client => SupabaseService.instance.client;
  final UserTierService _tierService = UserTierService();
  RealtimeChannel? _realtimeChannel;

  /// Retry mechanism with exponential backoff
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
        
        debugPrint('Operation failed, retrying in ${delay.inSeconds}s... (attempt $attempts/$maxRetries)');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
    
    throw Exception('Max retries reached');
  }

  /// Fetches all wardrobe items for the authenticated user
  Future<List<Map<String, dynamic>>> fetchWardrobeItems({
    String? category,
    String? searchQuery,
  }) async {
    try {
      return await _retryOperation(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) {
          // User not authenticated - return empty list instead of crashing
          return [];
        }
        
        var query = _client
            .from('wardrobe_items')
            .select()
            .eq('user_id', userId);

        if (category != null && category != 'All') {
          query = query.eq('category', category);
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          query = query.or(
            'name.ilike.%$searchQuery%,brand.ilike.%$searchQuery%',
          );
        }

        final response = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      // Return empty list on any error (including Supabase not initialized)
      // This prevents white screen crashes
      debugPrint('Wardrobe fetch error: $error');
      return [];
    }
  }

  /// Subscribes to real-time changes for wardrobe items
  /// Returns a RealtimeChannel that can be unsubscribed later
  RealtimeChannel subscribeToWardrobeChanges({
    required void Function(PostgresChangePayload payload) onInsert,
    required void Function(PostgresChangePayload payload) onUpdate,
    required void Function(PostgresChangePayload payload) onDelete,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to subscribe to changes');
    }

    return _client
        .channel('wardrobe_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wardrobe_items',
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
          table: 'wardrobe_items',
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
          table: 'wardrobe_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: onDelete,
        )
        .subscribe();
  }

  /// Create new wardrobe item with tier limit checking
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check tier limit before allowing item creation
      final canAdd = await _tierService.canAddItem(user.id);
      if (!canAdd) {
        final tierInfo = await _tierService.getUserTierInfo(user.id);
        final tier = tierInfo['tier'] as String;
        final limit = tierInfo['items_limit'] as int;

        throw Exception(
          'Item limit reached. You have reached your $tier tier limit of $limit items. '
          'Upgrade to premium for 100 items.',
        );
      }

      final response = await _client.from('wardrobe_items').insert({
        ...itemData,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      return {'success': true, 'item': response.first};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Adds a new wardrobe item
  Future<Map<String, dynamic>> addWardrobeItem({
    required String name,
    required String category,
    String? brand,
    String? imageUrl,
    String? semanticLabel,
    double? purchasePrice,
    DateTime? purchaseDate,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to add items');
      }

      final response = await _client
          .from('wardrobe_items')
          .insert({
            'user_id': userId,
            'name': name,
            'category': category,
            'brand': brand,
            'image_url': imageUrl,
            'semantic_label': semanticLabel,
            'purchase_price': purchasePrice,
            'purchase_date': purchaseDate?.toIso8601String(),
            'notes': notes,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add wardrobe item: $error');
    }
  }

  /// Updates an existing wardrobe item
  Future<Map<String, dynamic>> updateWardrobeItem({
    required String itemId,
    String? name,
    String? category,
    String? brand,
    String? imageUrl,
    String? semanticLabel,
    int? wearCount,
    DateTime? lastWorn,
    double? costPerWear,
    double? purchasePrice,
    DateTime? purchaseDate,
    String? notes,
    bool? isFavorite,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (category != null) updateData['category'] = category;
      if (brand != null) updateData['brand'] = brand;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (semanticLabel != null) updateData['semantic_label'] = semanticLabel;
      if (wearCount != null) updateData['wear_count'] = wearCount;
      if (lastWorn != null)
        updateData['last_worn'] = lastWorn.toIso8601String();
      if (costPerWear != null) updateData['cost_per_wear'] = costPerWear;
      if (purchasePrice != null) updateData['purchase_price'] = purchasePrice;
      if (purchaseDate != null) {
        updateData['purchase_date'] = purchaseDate.toIso8601String();
      }
      if (notes != null) updateData['notes'] = notes;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;

      final response = await _client
          .from('wardrobe_items')
          .update(updateData)
          .eq('id', itemId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update wardrobe item: $error');
    }
  }

  /// Deletes a wardrobe item
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      await _client.from('wardrobe_items').delete().eq('id', itemId);
    } catch (error) {
      throw Exception('Failed to delete wardrobe item: $error');
    }
  }

  /// Deletes multiple wardrobe items
  Future<void> deleteMultipleItems(List<String> itemIds) async {
    try {
      await _client.from('wardrobe_items').delete().inFilter('id', itemIds);
    } catch (error) {
      throw Exception('Failed to delete wardrobe items: $error');
    }
  }

  /// Gets wardrobe statistics for the authenticated user
  Future<Map<String, dynamic>> getWardrobeStatistics() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final totalItemsData = await _client
          .from('wardrobe_items')
          .select('id')
          .eq('user_id', userId)
          .count();

      final favoriteItemsData = await _client
          .from('wardrobe_items')
          .select('id')
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .count();

      final categoryCountsResponse = await _client
          .from('wardrobe_items')
          .select('category')
          .eq('user_id', userId);

      final categoryCounts = <String, int>{};
      for (final item in categoryCountsResponse) {
        final category = item['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return {
        'total_items': totalItemsData.count ?? 0,
        'favorite_items': favoriteItemsData.count ?? 0,
        'category_counts': categoryCounts,
      };
    } catch (error) {
      throw Exception('Failed to get wardrobe statistics: $error');
    }
  }

  /// Creates an outfit log with associated items
  Future<Map<String, dynamic>> createOutfitLog({
    required List<String> itemIds,
    String? outfitName,
    int? rating,
    String? notes,
    String? weather,
    String? occasion,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      // Create outfit log
      final outfitLog = await _client
          .from('outfit_logs')
          .insert({
            'user_id': userId,
            'outfit_name': outfitName,
            'rating': rating,
            'notes': notes,
            'weather': weather,
            'occasion': occasion,
          })
          .select()
          .single();

      // Associate items with outfit
      final outfitItems = itemIds
          .map((itemId) => {'outfit_id': outfitLog['id'], 'item_id': itemId})
          .toList();

      await _client.from('outfit_items').insert(outfitItems);

      return outfitLog;
    } catch (error) {
      throw Exception('Failed to create outfit log: $error');
    }
  }

  /// Fetches outfit history for the authenticated user
  Future<List<Map<String, dynamic>>> fetchOutfitHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('outfit_logs')
          .select('*, outfit_items(*, wardrobe_items(*))')
          .eq('user_id', userId)
          .order('worn_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch outfit history: $error');
    }
  }
}
