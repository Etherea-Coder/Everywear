import 'package:hive/hive.dart';

part 'local_wardrobe_item.g.dart';

@HiveType(typeId: 0)
class LocalWardrobeItem extends HiveObject {
  @HiveField(0)
  String id = '';

  @HiveField(1)
  String? remoteId;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? category;

  @HiveField(4)
  String? brand;

  @HiveField(5)
  String? imageUrl;

  @HiveField(6)
  String? semanticLabel;

  @HiveField(7)
  int wearCount = 0;

  @HiveField(8)
  DateTime? lastWorn;

  @HiveField(9)
  double? purchasePrice;

  @HiveField(10)
  DateTime? purchaseDate;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  bool isFavorite = false;

  @HiveField(13)
  DateTime? createdAt;

  @HiveField(14)
  DateTime? updatedAt;
}
