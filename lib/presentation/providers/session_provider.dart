import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../data/datasource/local/hive_storage.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../../../data/repository/session_repository.dart';
import '../../../domain/entities/chat_session.dart';
import 'connection_provider.dart';

// Exactly as OpenClaw Control UI:
// - sessionListProvider provides all active (unarchived) sessions
// - sorted by pinned first, then updatedAt descending
// - currentSessionIdProvider tracks selected session

final sessionListProvider = NotifierProvider<SessionListNotifier, List<ChatSession>>(
  SessionListNotifier.new,
);

class SessionListNotifier extends Notifier<List<ChatSession>> {
  late final SessionRepository _repo;
  bool _initialized = false;

  @override
  List<ChatSession> build() {
    final storage = HiveStorage();
    _repo = SessionRepository(storage);

    // Initialize Hive async then load from remote
    storage.init().then((_) async {
      _initialized = true;
      await _syncFromRemote();
      _updateState();
    });

    return _repo.getActiveSessions();
  }

  void _updateState() {
    state = _repo.getActiveSessions();
  }

  /// Full sync from gateway - exactly like Control UI
  Future<void> _syncFromRemote() async {
    if (!_initialized) return;

    final conn = ref.read(connectionProvider);
    if (!conn.isConnected) {
      _updateState();
      return;
    }

    try {
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('sessions.list', {
        'includeGlobal': false,
        'includeUnknown': false,
        'activeMinutes': 0,
        'limit': 100,
      });

      List sessions = [];
      if (result is Map && result.containsKey('result')) {
        sessions = result['result'] as List;
      } else if (result is List) {
        sessions = result;
      }

      // Sync each remote session to local
      for (final item in sessions) {
        final m = item as Map;
        final session = ChatSession(
          id: m['key'] as String,
          name: m['label'] as String? ?? 'Untitled',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as int? ?? 0) * 1000,
          ),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (m['updatedAt'] as int? ?? 0) * 1000,
          ),
          isPinned: m['pinned'] as bool? ?? false,
          isArchived: false,
          unreadCount: 0,
        );
        await _repo.saveSession(session);
      }
    } catch (e) {
      // Keep local cache on error
    } finally {
      _updateState();
    }
  }

  /// Public refresh - called after connection completes
  Future<void> refreshFromRemote() async {
    await _syncFromRemote();
  }

  /// Create new session - always create on gateway first
  Future<ChatSession> create(String name) async {
    String? remoteKey;

    final conn = ref.read(connectionProvider);
    if (conn.isConnected) {
      try {
        final client = ref.read(connectionProvider.notifier).client;
        final resp = await client.request('sessions.create', {
          'label': name,
        });
        if (resp is Map && resp.containsKey('result')) {
          final created = resp['result'] as Map;
          remoteKey = created['key'] as String;
        }
      } catch (_) {
        // Fallback to local
      }
    }

    final session = await _repo.create(name, sessionId: remoteKey);
    _updateState();
    return session;
  }

  /// Delete session - delete on gateway first
  Future<void> delete(String sessionId) async {
    final conn = ref.read(connectionProvider);
    if (conn.isConnected) {
      try {
        final client = ref.read(connectionProvider.notifier).client;
        await client.request('sessions.delete', {
          'key': sessionId,
          'deleteTranscript': true,
        });
      } catch (_) {
        // Still delete locally
      }
    }

    await _repo.delete(sessionId);
    _updateState();
  }

  /// Toggle pin - sync to gateway
  Future<void> togglePin(String sessionId) async {
    await _repo.togglePin(sessionId);

    final conn = ref.read(connectionProvider);
    if (conn.isConnected) {
      try {
        final sessions = _repo.getActiveSessions();
        final session = sessions.firstWhereOrNull((s) => s.id == sessionId);
        if (session != null) {
          final client = ref.read(connectionProvider.notifier).client;
          await client.request('sessions.patch', {
            'key': sessionId,
            'label': session.name,
            'pinned': session.isPinned,
          });
        }
      } catch (_) {
        // Ignore
      }
    }

    _updateState();
  }

  /// Toggle archive
  Future<void> toggleArchive(String sessionId) async {
    await _repo.toggleArchive(sessionId);
    _updateState();
  }

  /// Rename - sync to gateway
  Future<void> rename(String sessionId, String newName) async {
    await _repo.rename(sessionId, newName);

    final conn = ref.read(connectionProvider);
    if (conn.isConnected) {
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

    _updateState();
  }

  /// Clear unread
  Future<void> clearUnread(String sessionId) async {
    await _repo.clearUnread(sessionId);
    _updateState();
  }
}

// Current selected session
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

final currentSessionProvider = Provider<ChatSession?>((ref) {
  final id = ref.watch(currentSessionIdProvider);
  if (id == null) return null;
  final sessions = ref.watch(sessionListProvider);
  return sessions.firstWhereOrNull((s) => s.id == id);
});
