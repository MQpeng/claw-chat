// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      role: fields[2] as MessageRole,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      status: fields[5] as MessageStatus,
      attachments: (fields[6] as List?)?.cast<FileItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.attachments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
