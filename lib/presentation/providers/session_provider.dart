import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasource/local/hive_storage.dart';
import '../../../data/repository/session_repository.dart';
import '../../../domain/entities/chat_session.dart';

final sessionListProvider = NotifierProvider<SessionListNotifier, List<ChatSession>>(SessionListNotifier.new);

class SessionListNotifier extends Notifier<List<ChatSession>> {
  late final SessionRepository _repository;

  @override
  List<ChatSession> build() {
    final storage = HiveStorage();
    _repository = SessionRepository(storage);
    return _repository.getActiveSessions();
  }

  void refresh() {
    state = _repository.getActiveSessions();
  }

  Future<ChatSession> createSession(String name) async {
    final session = await _repository.createSession(name);
    refresh();
    return session;
  }

  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteSession(sessionId);
    refresh();
  }

  Future<void> togglePin(String sessionId) async {
    await _repository.togglePin(sessionId);
    refresh();
  }

  Future<void> toggleArchive(String sessionId) async {
    await _repository.toggleArchive(sessionId);
    refresh();
  }

  Future<void> renameSession(String sessionId, String newName) async {
    await _repository.renameSession(sessionId, newName);
    refresh();
  }

  Future<void> clearUnread(String sessionId) async {
    await _repository.clearUnread(sessionId);
    refresh();
  }
}

final currentSessionIdProvider = StateProvider<String?>((ref) => null);

final currentSessionProvider = Provider<ChatSession?>((ref) {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return null;
  final sessions = ref.watch(sessionListProvider);
  return sessions.firstWhere((s) => s.id == sessionId);
});
