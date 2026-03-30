import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat_message.dart';

class HiveStorage {
  static const String _sessionsBoxName = 'chat_sessions';
  static const String _messagesBoxName = 'chat_messages';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<ChatSession>(_sessionsBoxName);
    await Hive.openBox<ChatMessage>(_messagesBoxName);
  }

  Box<ChatSession> get sessionsBox => Hive.box<ChatSession>(_sessionsBoxName);
  Box<ChatMessage> get messagesBox => Hive.box<ChatMessage>(_messagesBoxName);

  Future<void> close() async {
    await Hive.close();
  }

  // Session operations
  Future<void> saveSession(ChatSession session) async {
    await sessionsBox.put(session.id, session);
  }

  Future<void> deleteSession(String sessionId) async {
    // Delete session and all its messages
    await sessionsBox.delete(sessionId);
    final allMessages = messagesBox.values.toList();
    for (final message in allMessages.where((m) => m.sessionId == sessionId)) {
      await messagesBox.delete(message.id);
    }
  }

  List<ChatSession> getAllSessions() {
    return sessionsBox.values.toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  List<ChatSession> getActiveSessions() {
    return getAllSessions().where((s) => !s.isArchived).toList();
  }

  // Message operations
  Future<void> saveMessage(ChatMessage message) async {
    await messagesBox.put(message.id, message);
    // Update session's updatedAt
    final session = sessionsBox.get(message.sessionId);
    if (session != null) {
      session.touch();
      await saveSession(session);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    await messagesBox.delete(messageId);
  }

  List<ChatMessage> getMessagesForSession(String sessionId) {
    return messagesBox.values
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> clearSessionMessages(String sessionId) async {
    final allMessages = messagesBox.values.toList();
    for (final message in allMessages.where((m) => m.sessionId == sessionId)) {
      await messagesBox.delete(message.id);
    }
  }
}
