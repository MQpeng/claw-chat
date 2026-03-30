import '../../../domain/entities/chat_message.dart';
import '../datasource/local/hive_storage.dart';

class MessageRepository {
  final HiveStorage _storage;

  MessageRepository(this._storage);

  Future<void> saveMessage(ChatMessage message) {
    return _storage.saveMessage(message);
  }

  Future<void> deleteMessage(String messageId) {
    return _storage.deleteMessage(messageId);
  }

  List<ChatMessage> getMessagesForSession(String sessionId) {
    return _storage.getMessagesForSession(sessionId);
  }

  Future<void> clearSessionMessages(String sessionId) {
    return _storage.clearSessionMessages(sessionId);
  }
}
