import 'isar';

part 'local_wardrobe_item.g.dart';

@collection
class LocalWardrobeItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? remoteId;

  String? name;
  String? category; // Maps to clothing_category enum in production
  String? brand;
  String? imageUrl;
  String? semanticLabel;
  int wearCount = 0;
  DateTime? lastWorn;
  double? purchasePrice;
  DateTime? purchaseDate;
  String? notes;
  bool isFavorite = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
