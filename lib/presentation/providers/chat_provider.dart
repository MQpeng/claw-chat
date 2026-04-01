import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasource/local/hive_storage.dart';
import '../../../data/repository/message_repository.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/message_role.dart';
import '../../../domain/entities/message_status.dart';
import 'session_provider.dart';

final chatMessagesProvider = NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  late final MessageRepository _repository;
  String? _currentRunId;

  String? get currentRunId => _currentRunId;
  set currentRunId(String? id) {
    _currentRunId = id;
  }

  @override
  List<ChatMessage> build() {
    final storage = HiveStorage();
    _repository = MessageRepository(storage);
    final currentSessionId = ref.watch(currentSessionIdProvider);
    if (currentSessionId == null) return [];
    return _repository.getMessagesForSession(currentSessionId);
  }

  void refreshForCurrentSession() {
    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      state = [];
    } else {
      state = _repository.getMessagesForSession(currentSessionId);
    }
  }

  Future<ChatMessage> sendMessage({
    required String content,
    required MessageRole role,
  }) async {
    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      throw Exception('No current session selected');
    }

    final message = ChatMessage(
      id: const Uuid().v4(),
      sessionId: currentSessionId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    await _repository.saveMessage(message);
    refreshForCurrentSession();
    if (role == MessageRole.assistant && message.status.isSending) {
      _currentRunId = message.id;
    }
    return message;
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final index = state.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final updated = state[index].copyWith(status: status);
      state = [...state];
      state[index] = updated;
      await _repository.saveMessage(updated);
    }
  }

  Future<void> appendToMessage(String messageId, String chunk) async {
    final index = state.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final updated = state[index].copyWith(
        content: state[index].content + chunk,
      );
      state = [...state];
      state[index] = updated;
      await _repository.saveMessage(updated);
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _repository.saveMessage(message);
    refreshForCurrentSession();
  }

  Future<void> deleteMessage(String messageId) async {
    await _repository.deleteMessage(messageId);
    refreshForCurrentSession();
  }

  Future<void> clearCurrentSession() async {
    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId == null) return;
    await _repository.clearSessionMessages(currentSessionId);
    refreshForCurrentSession();
  }
}
