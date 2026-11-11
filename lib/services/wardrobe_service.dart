import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import './supabase_service.dart';
import './storage_service.dart';

/// Service layer for wardrobe management with real-time synchronization
/// Provides CRUD operations and real-time subscription capabilities
class WardrobeService {
  SupabaseClient get _client => SupabaseService.instance.client;

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

        if (kDebugMode)
          debugPrint(
            'Operation failed, retrying in ${delay.inSeconds}s... (attempt $attempts/$maxRetries)',
          );
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
    if (!SupabaseService.isInitialized) return [];
    try {
      return await _retryOperation(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) {
          // User not authenticated - return empty list instead of crashing
          return [];
        }

        var query = _client
            .from('wardrobe_items')
            .select('*, image_url')
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
        final rows = List<Map<String, dynamic>>.from(response);
        return rows
            .map((row) => {...row, 'image_ref': row['image_url']})
            .toList();
      });
    } catch (error) {
      if (kDebugMode) debugPrint('Wardrobe fetch failed: $error');
      rethrow;
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

  /// Create new wardrobe item
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
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
            'image_url': imageUrl == null
                ? null
                : StorageService.stableStorageReference(imageUrl) ?? imageUrl,
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (category != null) updateData['category'] = category;
      if (brand != null) updateData['brand'] = brand;
      if (imageUrl != null) {
        updateData['image_url'] =
            StorageService.stableStorageReference(imageUrl) ?? imageUrl;
      }
      if (semanticLabel != null) updateData['semantic_label'] = semanticLabel;
      if (wearCount != null) updateData['wear_count'] = wearCount;
      if (lastWorn != null) {
        updateData['last_worn'] = lastWorn.toIso8601String();
      }
      if (costPerWear != null) updateData['cost_per_wear'] = costPerWear;
      if (purchasePrice != null) updateData['purchase_price'] = purchasePrice;
      if (purchaseDate != null) {
        updateData['purchase_date'] = purchaseDate.toIso8601String();
      }
      if (notes != null) updateData['notes'] = notes;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;

      String? previousImage;
      if (updateData.containsKey('image_url')) {
        final existing = await _client
            .from('wardrobe_items')
            .select('image_url')
            .eq('id', itemId)
            .eq('user_id', userId)
            .maybeSingle();
        previousImage = existing?['image_url'] as String?;
      }

      final response = await _client
          .from('wardrobe_items')
          .update(updateData)
          .eq('id', itemId)
          .eq('user_id', userId)
          .select()
          .single();

      final newImage = response['image_url'] as String?;
      if (previousImage != newImage && _client.auth.currentUser?.id == userId) {
        await _deleteOwnedWardrobeImage(previousImage, userId);
      }

      return response;
    } catch (error) {
      throw Exception('Failed to update wardrobe item: $error');
    }
  }

  /// Deletes a wardrobe item
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      final existing = await _client
          .from('wardrobe_items')
          .select('image_url')
          .eq('id', itemId)
          .eq('user_id', userId)
          .maybeSingle();
      final deleted = await _client
          .from('wardrobe_items')
          .delete()
          .eq('id', itemId)
          .eq('user_id', userId)
          .select('id');
      if (deleted.isNotEmpty && _client.auth.currentUser?.id == userId) {
        await _deleteOwnedWardrobeImage(
          existing?['image_url'] as String?,
          userId,
        );
      }
    } catch (error) {
      throw Exception('Failed to delete wardrobe item: $error');
    }
  }

  /// Deletes multiple wardrobe items
  Future<void> deleteMultipleItems(List<String> itemIds) async {
    try {
      if (itemIds.isEmpty) return;
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      final existing = await _client
          .from('wardrobe_items')
          .select('id, image_url')
          .eq('user_id', userId)
          .inFilter('id', itemIds);
      final deleted = await _client
          .from('wardrobe_items')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', itemIds)
          .select('id');
      if (deleted.isNotEmpty && _client.auth.currentUser?.id == userId) {
        final deletedIds = deleted.map((row) => row['id']).toSet();
        for (final row in existing) {
          if (deletedIds.contains(row['id'])) {
            await _deleteOwnedWardrobeImage(
              row['image_url'] as String?,
              userId,
            );
          }
        }
      }
    } catch (error) {
      throw Exception('Failed to delete wardrobe items: $error');
    }
  }

  Future<void> _deleteOwnedWardrobeImage(String? value, String ownerId) async {
    final reference = StorageService.ownedWardrobeImageReference(
      value,
      ownerId: ownerId,
    );
    if (reference == null) return;
    final deleted = await StorageService().deleteImageReference(
      reference,
      expectedBucket: 'wardrobe-images',
    );
    if (!deleted && kDebugMode) {
      debugPrint('Wardrobe image cleanup failed after row change');
    }
  }

  /// Gets wardrobe statistics for the authenticated user
  Future<Map<String, dynamic>> getWardrobeStatistics() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return _emptyStats();
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
        final category = item['category'] as String? ?? 'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return {
        'total_items': totalItemsData.count,
        'favorite_items': favoriteItemsData.count,
        'category_counts': categoryCounts,
      };
    } catch (error) {
      if (kDebugMode) debugPrint('Error getting wardrobe statistics: $error');
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() => {
    'total_items': 0,
    'favorite_items': 0,
    'category_counts': <String, int>{},
  };

  /// Fetches outfit history for the authenticated user
  Future<List<Map<String, dynamic>>> fetchOutfitHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('outfit_logs')
          .select('*, outfit_items(*, wardrobe_items(*))')
          .eq('user_id', userId)
          .order('worn_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      if (kDebugMode) debugPrint('Error fetching outfit history: $error');
      return [];
    }
  }
}
