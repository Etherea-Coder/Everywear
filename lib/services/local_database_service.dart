import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/local_wardrobe_item.dart';
import './supabase_service.dart';

class LocalDatabaseService {
  static const String _boxPrefix = 'wardrobe_items';
  Box<LocalWardrobeItem>? _box;
  String? _activeUserId;
  bool _isInitialized = false;

  Future<void> init() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Local wardrobe cache requires an authenticated user.');
    }
    if (_isInitialized && _activeUserId == userId) return;

    try {
      // Try to init Hive, may already be initialized from main.dart
      try {
        await Hive.initFlutter();
      } catch (_) {
        // Already initialized, ignore
      }
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LocalWardrobeItemAdapter());
      }
      _box = await Hive.openBox<LocalWardrobeItem>('${_boxPrefix}_$userId');
      _activeUserId = userId;
      _isInitialized = true;
      if (kDebugMode) debugPrint('✅ LocalDatabaseService initialized');
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Failed to initialize LocalDatabaseService: $e');
      _isInitialized = false;
    }
  }

  // Ensure box is initialized before use
  Box<LocalWardrobeItem> get box {
    if (!_isInitialized || _box == null) {
      throw StateError(
        'LocalDatabaseService not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  /// Syncs remote items to local database
  Future<void> syncItems(
    List<Map<String, dynamic>> remoteItems, {
    bool replaceAll = true,
  }) async {
    await init();

    final localItems = <String, LocalWardrobeItem>{};

    for (var item in remoteItems) {
      final localItem = LocalWardrobeItem()
        ..id = item['id']?.toString() ?? ''
        ..remoteId = item['id']?.toString()
        ..name = item['name']
        ..category = item['category']
        ..brand = item['brand']
        // Persist the stable object reference, never the short lived signed URL
        // prepared for the current screen.
        ..imageUrl = item['image_ref'] ?? item['image_url']
        ..semanticLabel = item['semantic_label']
        ..purchasePrice = (item['purchase_price'] as num?)?.toDouble()
        ..wearCount = (item['wear_count'] as num?)?.toInt() ?? 0
        ..lastWorn = item['last_worn'] != null
            ? DateTime.parse(item['last_worn'])
            : null
        ..isFavorite = item['is_favorite'] ?? false
        ..createdAt = item['created_at'] != null
            ? DateTime.parse(item['created_at'])
            : null;

      localItems[localItem.id] = localItem;
    }

    if (replaceAll) await box.clear();
    await box.putAll(localItems);
  }

  /// Fetches all items from local database
  Future<List<LocalWardrobeItem>> getLocalItems() async {
    await init();
    return box.values.toList();
  }

  /// Deletes an item from the local cache.
  ///
  /// We store items keyed by their remote id string in most cases, but we also
  /// guard against older/local ids by scanning for matching `remoteId`.
  Future<void> deleteLocalItem(String itemId) async {
    await init();

    // Fast path: key matches the remote id.
    if (box.containsKey(itemId)) {
      await box.delete(itemId);
      return;
    }

    // Fallback: delete any entries whose remoteId matches.
    final keysToDelete = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final item = entry.value;
      if (item.remoteId == itemId) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }
  }

  /// Closes the database
  Future<void> close() async {
    if (_isInitialized) {
      await box.close();
      _isInitialized = false;
      _activeUserId = null;
    }
  }

  /// Removes only the authenticated user's cached wardrobe data.
  Future<void> clearCurrentUser() async {
    await init();
    await box.clear();
  }
}
