import 'package:hive/hive.dart';

part 'message_status.g.dart';

@HiveType(typeId: 3)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  error;

  bool get isSending => this == MessageStatus.sending;
  bool get isSent => this == MessageStatus.sent;
  bool get isError => this == MessageStatus.error;
}
