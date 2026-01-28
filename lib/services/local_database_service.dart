import 'package:hive_flutter/hive_flutter.dart';
import '../models/local_wardrobe_item.dart';

class LocalDatabaseService {
  static const String _boxName = 'wardrobe_items';
  Box<LocalWardrobeItem>? _box;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
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
      _box = await Hive.openBox<LocalWardrobeItem>(_boxName);
      _isInitialized = true;
      debugPrint('✅ LocalDatabaseService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize LocalDatabaseService: $e');
      _isInitialized = false;
    }
  }

  // Ensure box is initialized before use
  Box<LocalWardrobeItem> get box {
    if (!_isInitialized || _box == null) {
      throw StateError('LocalDatabaseService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Syncs remote items to local database
  Future<void> syncItems(List<Map<String, dynamic>> remoteItems) async {
    await init();
    
    final localItems = <String, LocalWardrobeItem>{};
    
    for (var item in remoteItems) {
      final localItem = LocalWardrobeItem()
        ..id = item['id']?.toString() ?? ''
        ..remoteId = item['id']?.toString()
        ..name = item['name']
        ..category = item['category']
        ..brand = item['brand']
        ..imageUrl = item['image_url']
        ..semanticLabel = item['semantic_label']
        ..purchasePrice = (item['purchase_price'] as num?)?.toDouble()
        ..wearCount = (item['wear_count'] as num?)?.toInt() ?? 0
        ..lastWorn = item['last_worn'] != null ? DateTime.parse(item['last_worn']) : null
        ..isFavorite = item['is_favorite'] ?? false
        ..createdAt = item['created_at'] != null ? DateTime.parse(item['created_at']) : null;
      
      localItems[localItem.id] = localItem;
    }

    await _box.putAll(localItems);
  }

  /// Fetches all items from local database
  Future<List<LocalWardrobeItem>> getLocalItems() async {
    await init();
    return _box.values.toList();
  }

  /// Closes the database
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}
