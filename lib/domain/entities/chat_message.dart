import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'message_role.dart';
import 'message_status.dart';
import 'file_item.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final MessageRole role;

  @HiveField(3)
  String content;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  MessageStatus status;

  @HiveField(6)
  List<FileItem>? attachments;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => FileItem.fromJson(a as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    List<FileItem>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
}
