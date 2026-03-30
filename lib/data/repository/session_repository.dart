import '../../../domain/entities/chat_session.dart';
import '../datasource/local/hive_storage.dart';

class SessionRepository {
  final HiveStorage _storage;

  SessionRepository(this._storage);

  Future<ChatSession> createSession(String name) {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _storage.saveSession(session).then((_) => session);
  }

  Future<void> deleteSession(String sessionId) {
    return _storage.deleteSession(sessionId);
  }

  Future<void> saveSession(ChatSession session) {
    return _storage.saveSession(session);
  }

  List<ChatSession> getActiveSessions() {
    return _storage.getActiveSessions();
  }

  List<ChatSession> getAllSessions() {
    return _storage.getAllSessions();
  }

  Future<void> togglePin(String sessionId) async {
    final session = _storage.sessionsBox.get(sessionId);
    if (session != null) {
      session.isPinned = !session.isPinned;
      await _storage.saveSession(session);
    }
  }

  Future<void> toggleArchive(String sessionId) async {
    final session = _storage.sessionsBox.get(sessionId);
    if (session != null) {
      session.isArchived = !session.isArchived;
      await _storage.saveSession(session);
    }
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final session = _storage.sessionsBox.get(sessionId);
    if (session != null) {
      session.name = newName;
      await _storage.saveSession(session);
    }
  }

  Future<void> clearUnread(String sessionId) async {
    final session = _storage.sessionsBox.get(sessionId);
    if (session != null) {
      session.unreadCount = 0;
      await _storage.saveSession(session);
    }
  }
}
