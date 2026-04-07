// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileItemAdapter extends TypeAdapter<FileItem> {
  @override
  final int typeId = 4;

  @override
  FileItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileItem(
      id: fields[0] as String,
      name: fields[1] as String,
      size: fields[2] as int,
      mimeType: fields[5] as String,
      type: fields[6] as FileItemType,
      remoteUrl: fields[3] as String?,
      localPath: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FileItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.remoteUrl)
      ..writeByte(4)
      ..write(obj.localPath)
      ..writeByte(5)
      ..write(obj.mimeType)
      ..writeByte(6)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
