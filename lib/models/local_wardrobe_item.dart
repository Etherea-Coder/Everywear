import 'isar';

part 'local_wardrobe_item.g.dart';

@collection
class LocalWardrobeItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? remoteId;

  String? name;
  String? category;
  String? brand;
  String? imageUrl;
  String? semanticLabel;
  double? price;
  int? wearCount;
  DateTime? lastWorn;
  bool isFavorite = false;
  DateTime? createdAt;
}
