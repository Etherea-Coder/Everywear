import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './wardrobe_service.dart';
import './local_database_service.dart';

class WardrobeRepository {
  final WardrobeService _remoteService = WardrobeService();
  final LocalDatabaseService _localService = LocalDatabaseService();

  /// Fetches wardrobe items, prioritizing remote if online and syncing to local
  Future<List<Map<String, dynamic>>> getWardrobeItems({
    String? category,
    String? searchQuery,
  }) async {
    var isOnline = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      isOnline =
          connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);
    } catch (error) {
      // A failed connectivity probe is not proof the service is offline.
      // Attempt the remote request and fall back to the scoped cache if it fails.
      if (kDebugMode) debugPrint('Connectivity probe failed: $error');
    }

    if (isOnline) {
      List<Map<String, dynamic>> remoteItems;
      try {
        remoteItems = await _remoteService
            .fetchWardrobeItems(category: category, searchQuery: searchQuery)
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'Remote wardrobe fetch failed, trying cached data: $error',
          );
        }
        final cached = await _fetchLocalAsMap(category, searchQuery);
        if (cached.isNotEmpty) return cached;
        throw WardrobeUnavailableException(
          'Your wardrobe could not be loaded. Check your connection and retry.',
          cause: error,
        );
      }

      try {
        // Cache failures do not turn a successful remote read into an error.
        await _localService
            .syncItems(
              remoteItems,
              replaceAll:
                  category == null &&
                  (searchQuery == null || searchQuery.isEmpty),
            )
            .timeout(const Duration(seconds: 3));
      } catch (error) {
        if (kDebugMode) debugPrint('Wardrobe cache update failed: $error');
      }
      return remoteItems;
    }

    final cached = await _fetchLocalAsMap(category, searchQuery);
    if (cached.isNotEmpty) return cached;
    throw const WardrobeUnavailableException(
      'You are offline and no saved wardrobe is available on this device.',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLocalAsMap(
    String? category,
    String? searchQuery,
  ) async {
    final localItems = await _localService.getLocalItems();

    var filtered = localItems;
    if (category != null && category != 'All') {
      filtered = filtered.where((item) => item.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (item) =>
                (item.name?.toLowerCase().contains(query) ?? false) ||
                (item.brand?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return filtered
        .map(
          (item) => {
            'id': item.remoteId ?? item.id.toString(),
            'name': item.name,
            'category': item.category,
            'brand': item.brand,
            'image_url': item.imageUrl,
            'image_ref': item.imageUrl,
            'semantic_label': item.semanticLabel,
            'purchase_price': item.purchasePrice,
            'wear_count': item.wearCount,
            'last_worn': item.lastWorn?.toIso8601String(),
            'is_favorite': item.isFavorite,
            'created_at': item.createdAt?.toIso8601String(),
          },
        )
        .toList();
  }

  /// Adds a new item, updating both remote and local
  Future<Map<String, dynamic>> addItem(Map<String, dynamic> itemData) async {
    final response = await _remoteService.createItem(itemData);
    if (response['success'] == true) {
      final newItem = response['item'] as Map<String, dynamic>;
      await _localService.syncItems([newItem], replaceAll: false);
    }
    return response;
  }

  /// Deletes an item from both remote and local
  Future<void> deleteItem(String itemId) async {
    await _remoteService.deleteWardrobeItem(itemId);
    await _localService.deleteLocalItem(itemId);
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

class WardrobeUnavailableException implements Exception {
  const WardrobeUnavailableException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
