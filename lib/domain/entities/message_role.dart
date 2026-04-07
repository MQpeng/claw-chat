import 'package:hive/hive.dart';

part 'message_role.g.dart';

@HiveType(typeId: 2)
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system;

  bool get isUser => this == MessageRole.user;
  bool get isAssistant => this == MessageRole.assistant;
  bool get isSystem => this == MessageRole.system;
}
