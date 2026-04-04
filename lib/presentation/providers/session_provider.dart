import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasource/local/hive_storage.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../../../data/repository/session_repository.dart';
import '../../../domain/entities/chat_session.dart';
import '../providers/connection_provider.dart';

final sessionListProvider = NotifierProvider<SessionListNotifier, List<ChatSession>>(SessionListNotifier.new);

class SessionListNotifier extends Notifier<List<ChatSession>> {
  late final SessionRepository _repository;
  bool _loading = false;

  @override
  List<ChatSession> build() {
    final storage = HiveStorage();
    _repository = SessionRepository(storage);
    _loadFromRemote();
    return _repository.getActiveSessions();
  }

  void refresh() {
    state = _repository.getActiveSessions();
  }

  Future<void> _loadFromRemote() async {
    final connection = ref.read(connectionProvider);
    if (!connection.isConnected) {
      refresh();
      return;
    }

    if (_loading) return;
    _loading = true;

    try {
      final client = ref.read(connectionProvider.notifier).client;
      // Request sessions.list from gateway
      final result = await client.request('sessions.list', {
        'includeGlobal': false,
        'includeUnknown': false,
        'activeMinutes': 0,
        'limit': 100,
      });

      if (result is Map && result.containsKey('result')) {
        final list = result['result'] as List;
        // Sync remote sessions to local storage
        for (final item in list) {
          final session = ChatSession(
            id: item['key'] as String,
            name: item['label'] as String? ?? 'Untitled',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (item['createdAt'] as int? ?? 0) * 1000,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              (item['updatedAt'] as int? ?? 0) * 1000,
            ),
            isPinned: item['pinned'] as bool? ?? false,
            isArchived: false,
            unreadCount: 0,
          );
          await _repository.saveSession(session);
        }
      } else if (result is List) {
        // For backwards compatibility if result is returned directly
        for (final item in result) {
          final session = ChatSession(
            id: item['key'] as String,
            name: item['label'] as String? ?? 'Untitled',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (item['createdAt'] as int? ?? 0) * 1000,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              (item['updatedAt'] as int? ?? 0) * 1000,
            ),
            isPinned: item['pinned'] as bool? ?? false,
            isArchived: false,
            unreadCount: 0,
          );
          await _repository.saveSession(session);
        }
      }
    } catch (e) {
      // If remote fails, still use cached local sessions
    } finally {
      _loading = false;
      // Always refresh state after attempting remote load
      refresh();
    }
  }

  Future<void> refreshFromRemote() async {
    await _loadFromRemote();
  }

  Future<ChatSession> createSession(String name) async {
    final connection = ref.read(connectionProvider);
    String? sessionId;
    if (connection.isConnected) {
      try {
        final client = ref.read(connectionProvider.notifier).client;
        final result = await client.request('sessions.create', {
          'label': name,
        });
        // result should be { "result": { "key": "...", "label": "...", ... } }
        if (result is Map && result.containsKey('result')) {
          final created = result['result'] as Map;
          sessionId = created['key'] as String;
        }
      } catch (_) {
        // If create fails remotely, still create locally
      }
    }
    final session = await _repository.createSession(name, sessionId: sessionId);
    refresh();
    return session;
  }

  Future<void> deleteSession(String sessionId) async {
    final connection = ref.read(connectionProvider);
    if (connection.isConnected) {
      try {
        final client = ref.read(connectionProvider.notifier).client;
        await client.request('sessions.delete', {
          'key': sessionId,
          'deleteTranscript': true,
        });
      } catch (_) {
        // Ignore errors, still delete locally
      }
    }
    await _repository.deleteSession(sessionId);
    refresh();
  }

  Future<void> togglePin(String sessionId) async {
    await _repository.togglePin(sessionId);
    refresh();

    // Sync to remote
    final connection = ref.read(connectionProvider);
    if (connection.isConnected) {
      final client = ref.read(connectionProvider.notifier).client;
      final session = _repository.getActiveSessions().firstWhere(
        (s) => s.id == sessionId,
        orElse: () => ChatSession(
          id: sessionId,
          name: 'Untitled',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (session.id.isNotEmpty) {
        try {
          await client.request('sessions.patch', {
            'key': sessionId,
            'label': session.name,
          });
        } catch (_) {
          // Ignore
        }
      }
    }
  }

  Future<void> toggleArchive(String sessionId) async {
    await _repository.toggleArchive(sessionId);
    refresh();
  }

  Future<void> renameSession(String sessionId, String newName) async {
    await _repository.renameSession(sessionId, newName);
    refresh();

    // Sync to remote
    final connection = ref.read(connectionProvider);
    if (connection.isConnected) {
      try {
        final client = ref.read(connectionProvider.notifier).client;
        await client.request('sessions.patch', {
          'key': sessionId,
          'label': newName,
        });
      } catch (_) {
        // Ignore
      }
    }
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
