import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/message_role.dart';
import '../../../domain/entities/message_status.dart';
import '../providers/session_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/input_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    setState(() {
      _showScrollToBottom = !atBottom;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session first')),
      );
      return;
    }

    final connection = ref.read(connectionProvider);
    if (!connection.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to OpenClaw')),
      );
      return;
    }

    // Send user message
    final message = await ref
        .read(chatMessagesProvider.notifier)
        .sendMessage(content: text.trim(), role: MessageRole.user);

    _scrollToBottom();

    // Get AI response
    final client = ref.read(connectionProvider.notifier).client;
    final assistantMessage = ChatMessage(
      id: const Uuid().v4(),
      sessionId: currentSessionId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    await ref.read(chatMessagesProvider.notifier).saveMessage(assistantMessage);
    _scrollToBottom();

    client.sendMessage(
      currentSessionId,
      message,
      onChunk: (chunk) {
        ref
            .read(chatMessagesProvider.notifier)
            .appendToMessage(assistantMessage.id, chunk);
        _scrollToBottom();
      },
      onDone: () {
        ref
            .read(chatMessagesProvider.notifier)
            .updateMessageStatus(assistantMessage.id, MessageStatus.sent);
      },
      onError: (error) {
        ref
            .read(chatMessagesProvider.notifier)
            .updateMessageStatus(assistantMessage.id, MessageStatus.error);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(currentSessionProvider);
    final messages = ref.watch(chatMessagesProvider);
    final connection = ref.watch(connectionProvider);

    if (currentSession == null) {
      return const Scaffold(
        body: Center(
          child: Text('Select a session to start chatting'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSession.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connection.isConnected)
            Container(
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Disconnected',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),
          if (_showScrollToBottom)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 16),
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ),
          InputBar(onSend: _sendMessage),
        ],
      ),
    );
  }
}
