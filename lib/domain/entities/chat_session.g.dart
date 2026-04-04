// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final int typeId = 0;

  @override
  ChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSession(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      isPinned: fields[4] as bool,
      isArchived: fields[5] as bool,
      unreadCount: fields[6] as int,
      modelId: fields[7] as String?,
      systemPrompt: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.isPinned)
      ..writeByte(5)
      ..write(obj.isArchived)
      ..writeByte(6)
      ..write(obj.unreadCount)
      ..writeByte(7)
      ..write(obj.modelId)
      ..writeByte(8)
      ..write(obj.systemPrompt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
