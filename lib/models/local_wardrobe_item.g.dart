// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_wardrobe_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalWardrobeItemAdapter extends TypeAdapter<LocalWardrobeItem> {
  @override
  final int typeId = 0;

  @override
  LocalWardrobeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalWardrobeItem()
      ..id = fields[0] as String
      ..remoteId = fields[1] as String?
      ..name = fields[2] as String?
      ..category = fields[3] as String?
      ..brand = fields[4] as String?
      ..imageUrl = fields[5] as String?
      ..semanticLabel = fields[6] as String?
      ..wearCount = fields[7] as int
      ..lastWorn = fields[8] as DateTime?
      ..purchasePrice = fields[9] as double?
      ..purchaseDate = fields[10] as DateTime?
      ..notes = fields[11] as String?
      ..isFavorite = fields[12] as bool
      ..createdAt = fields[13] as DateTime?
      ..updatedAt = fields[14] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, LocalWardrobeItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.remoteId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.brand)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.semanticLabel)
      ..writeByte(7)
      ..write(obj.wearCount)
      ..writeByte(8)
      ..write(obj.lastWorn)
      ..writeByte(9)
      ..write(obj.purchasePrice)
      ..writeByte(10)
      ..write(obj.purchaseDate)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isFavorite)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalWardrobeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
