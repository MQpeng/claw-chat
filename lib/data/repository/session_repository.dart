import '../../../domain/entities/chat_session.dart';
import '../datasource/local/hive_storage.dart';

// Exactly as Control UI:
// - Repository handles local storage operations
// - Sorts sessions: pinned first, then updatedAt descending
// - Only active (unarchived) sessions are returned for the list

class SessionRepository {
  final HiveStorage _storage;

  SessionRepository(this._storage);

  Future<ChatSession> create(String name, {String? sessionId}) async {
    final session = ChatSession(
      id: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _storage.saveSession(session);
    return session;
  }

  Future<void> delete(String sessionId) async {
    await _storage.deleteSession(sessionId);
  }

  Future<void> saveSession(ChatSession session) async {
    await _storage.saveSession(session);
  }

  Future<void> togglePin(String sessionId) async {
    final session = await _storage.getSession(sessionId);
    if (session == null) return;
    final updated = session.copyWith(isPinned: !session.isPinned);
    await _storage.saveSession(updated);
  }

  Future<void> toggleArchive(String sessionId) async {
    final session = await _storage.getSession(sessionId);
    if (session == null) return;
    final updated = session.copyWith(isArchived: !session.isArchived);
    await _storage.saveSession(updated);
  }

  Future<void> rename(String sessionId, String newName) async {
    final session = await _storage.getSession(sessionId);
    if (session == null) return;
    final updated = session.copyWith(name: newName);
    await _storage.saveSession(updated);
  }

  Future<void> clearUnread(String sessionId) async {
    final session = await _storage.getSession(sessionId);
    if (session == null) return;
    final updated = session.copyWith(unreadCount: 0);
    await _storage.saveSession(updated);
  }

  List<ChatSession> getActiveSessions() {
    return _storage.getActiveSessions();
  }

  List<ChatSession> getAllSessions() {
    return _storage.getAllSessions();
  }
}
