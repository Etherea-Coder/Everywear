import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_wardrobe_item.dart';

class LocalDatabaseService {
  late Future<Isar> db;

  LocalDatabaseService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [LocalWardrobeItemSchema],
        inspector: true,
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  /// Syncs remote items to local database
  Future<void> syncItems(List<Map<String, dynamic>> remoteItems) async {
    final isar = await db;
    final localItems = remoteItems.map((item) {
      return LocalWardrobeItem()
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
    }).toList();

    await isar.writeTxn(() async {
      await isar.localWardrobeItems.putAll(localItems);
    });
  }

  /// Fetches all items from local database
  Future<List<LocalWardrobeItem>> getLocalItems() async {
    final isar = await db;
    return await isar.localWardrobeItems.where().findAll();
  }
}
