import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 0)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  bool isPinned;

  @HiveField(5)
  bool isArchived;

  @HiveField(6)
  int unreadCount;

  @HiveField(7)
  final String? modelId;

  @HiveField(8)
  final String? systemPrompt;

  ChatSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.unreadCount = 0,
    this.modelId,
    this.systemPrompt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isArchived': isArchived,
      'unreadCount': unreadCount,
      'modelId': modelId,
      'systemPrompt': systemPrompt,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
      modelId: json['modelId'] as String?,
      systemPrompt: json['systemPrompt'] as String?,
    );
  }

  ChatSession copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    int? unreadCount,
    String? modelId,
    String? systemPrompt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      unreadCount: unreadCount ?? this.unreadCount,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }

  void touch() {
    updatedAt = DateTime.now();
  }
}
