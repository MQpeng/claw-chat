import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/entities/chat_session.dart';
import '../../../domain/entities/chat_message.dart';

// Exactly as OpenClaw Control UI requires:
// - Two boxes: sessions and messages
// - Sessions sorted by pinned first → updatedAt descending
// - Get active sessions = unarchived

class HiveStorage {
  static const String _sessionsBox = 'chat_sessions';
  static const String _messagesBox = 'chat_messages';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<ChatSession>(_sessionsBox);
    await Hive.openBox<ChatMessage>(_messagesBox);
  }

  Box<ChatSession> get sessions => Hive.box<ChatSession>(_sessionsBox);
  Box<ChatMessage> get messages => Hive.box<ChatMessage>(_messagesBox);

  Future<void> close() async {
    await Hive.close();
  }

  // Session operations
  Future<ChatSession?> getSession(String id) async {
    return sessions.get(id);
  }

  Future<void> saveSession(ChatSession session) async {
    await sessions.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    // Delete session and all its messages
    await sessions.delete(id);
    final allMessages = messages.values.toList();
    for (final msg in allMessages.where((m) => m.sessionId == id)) {
      await messages.delete(msg.id);
    }
  }

  List<ChatSession> getAllSessions() {
    return sessions.values.toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  List<ChatSession> getActiveSessions() {
    return getAllSessions().where((s) => !s.isArchived).toList();
  }

  // Message operations
  Future<void> saveMessage(ChatMessage message) async {
    await messages.put(message.id, message);
    // Update session's last updated time
    final session = sessions.get(message.sessionId);
    if (session != null) {
      final updated = session.copyWith(updatedAt: DateTime.now());
      await saveSession(updated);
    }
  }

  Future<void> deleteMessage(String id) async {
    await messages.delete(id);
  }

  List<ChatMessage> getMessagesForSession(String sessionId) {
    return messages.values
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> clearSessionMessages(String sessionId) async {
    final allMessages = messages.values.toList();
    for (final msg in allMessages.where((m) => m.sessionId == sessionId)) {
      await messages.delete(msg.id);
    }
  }
}
