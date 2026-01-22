import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/local_wardrobe_item.dart';
import './wardrobe_service.dart';
import './local_database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WardrobeRepository {
  final WardrobeService _remoteService = WardrobeService();
  final LocalDatabaseService _localService = LocalDatabaseService();

  /// Fetches wardrobe items, prioritizing remote if online and syncing to local
  Future<List<Map<String, dynamic>>> getWardrobeItems({
    String? category,
    String? searchQuery,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final remoteItems = await _remoteService.fetchWardrobeItems(
          category: category,
          searchQuery: searchQuery,
        );
        // Sync to local for future offline use
        await _localService.syncItems(remoteItems);
        return remoteItems;
      } catch (e) {
        // Fallback to local if remote fails
        debugPrint('Remote fetch failed, falling back to local: $e');
        return _fetchLocalAsMap(category, searchQuery);
      }
    } else {
      return _fetchLocalAsMap(category, searchQuery);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLocalAsMap(String? category, String? searchQuery) async {
    final localItems = await _localService.getLocalItems();
    
    var filtered = localItems;
    if (category != null && category != 'All') {
      filtered = filtered.where((item) => item.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((item) => 
        (item.name?.toLowerCase().contains(query) ?? false) || 
        (item.brand?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return filtered.map((item) => {
      'id': item.remoteId ?? item.id.toString(),
      'name': item.name,
      'category': item.category,
      'brand': item.brand,
      'image_url': item.imageUrl,
      'semantic_label': item.semanticLabel,
      'purchase_price': item.price,
      'wear_count': item.wearCount,
      'last_worn': item.lastWorn?.toIso8601String(),
      'is_favorite': item.isFavorite,
      'created_at': item.createdAt?.toIso8601String(),
    }).toList();
  }

  /// Adds a new item, updating both remote and local
  Future<Map<String, dynamic>> addItem(Map<String, dynamic> itemData) async {
    final response = await _remoteService.createItem(itemData);
    if (response['success'] == true) {
      final newItem = response['item'] as Map<String, dynamic>;
      await _localService.syncItems([newItem]);
    }
    return response;
  }

  /// Deletes an item from both remote and local
  Future<void> deleteItem(String itemId) async {
    await _remoteService.deleteWardrobeItem(itemId);
    // Local deletion will happen on next sync or we can implement explicit local delete
    // For simplicity, we can let sync handle it or add a delete method to LocalDatabaseService
  }

  /// Subscribes to changes
  RealtimeChannel subscribeToChanges({
    required void Function(PostgresChangePayload payload) onInsert,
    required void Function(PostgresChangePayload payload) onUpdate,
    required void Function(PostgresChangePayload payload) onDelete,
  }) {
    return _remoteService.subscribeToWardrobeChanges(
      onInsert: onInsert,
      onUpdate: onUpdate,
      onDelete: onDelete,
    );
  }
}

// Add debugPrint import if needed, usually available in flutter/material.dart
import 'package:flutter/foundation.dart';
