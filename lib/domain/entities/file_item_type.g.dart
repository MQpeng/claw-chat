// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_item_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileItemTypeAdapter extends TypeAdapter<FileItemType> {
  @override
  final int typeId = 5;

  @override
  FileItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FileItemType.image;
      case 1:
        return FileItemType.video;
      case 2:
        return FileItemType.audio;
      case 3:
        return FileItemType.pdf;
      case 4:
        return FileItemType.other;
      default:
        return FileItemType.image;
    }
  }

  @override
  void write(BinaryWriter writer, FileItemType obj) {
    switch (obj) {
      case FileItemType.image:
        writer.writeByte(0);
        break;
      case FileItemType.video:
        writer.writeByte(1);
        break;
      case FileItemType.audio:
        writer.writeByte(2);
        break;
      case FileItemType.pdf:
        writer.writeByte(3);
        break;
      case FileItemType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
