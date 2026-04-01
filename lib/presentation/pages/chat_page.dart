import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/message_role.dart';
import '../../../domain/entities/message_status.dart';
import '../../../domain/entities/file_item.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
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

  Future<void> _executeSlashCommand(
    String command,
    String args,
    String fullText,
    List<FileItem> attachments,
    OpenClawClient client,
    String currentSessionId,
  ) async {
    // Execute slash command and show result as system message
    final result = await client.request(command == 'clear' || command == 'reset'
        ? 'chat.clear'
        : command == 'compact'
            ? 'sessions.compact'
            : 'sessions.patch', {
      'key': currentSessionId,
      if (command == 'model' && args.isNotEmpty) 'model': args.trim(),
      if (command == 'think') 'thinkingLevel': args.trim(),
      if (command == 'fast') 'fastMode': args.trim() == 'on',
      if (command == 'verbose') 'verboseLevel': args.trim(),
    });

    // Special handling for commands with side effects
    switch (command) {
      case 'new':
        // Create new session
        ref.read(sessionListProvider.notifier).createSession(args.isNotEmpty ? args : 'New Session');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Created new session')),
          );
        }
        return;
      case 'clear':
        // Clear all messages in current session
        await ref.read(chatMessagesProvider.notifier).clearCurrentSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat history cleared')),
          );
        }
        return;
      case 'reset':
        // Reset conversation
        await ref.read(chatMessagesProvider.notifier).clearCurrentSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session reset')),
          );
        }
        return;
      case 'compact':
        // Context compacted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Context compacted successfully')),
          );
        }
        ref.refresh(sessionListProvider.notifier).refreshFromRemote();
        return;
      case 'focus':
        // toggle focus mode handled by gateway, refresh sessions
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Focus mode toggled')),
          );
        }
        return;
      case 'stop':
        // Stop current run
        if (ref.read(chatMessagesProvider.notifier).currentRunId != null) {
          // Gateway will handle abort
          await client.request('chat.abort', {'sessionKey': currentSessionId});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Current run stopped')),
            );
          }
        }
        return;
      case 'help':
        // Show help already handled by client, display result
        break;
      default:
        // Other commands let gateway respond
        break;
    }

    // Show command result as system message
    final content = result is Map ? result['content']?.toString() ?? '' : result.toString();
    if (content.isEmpty) return;

    final systemMessage = ChatMessage(
      id: const Uuid().v4(),
      sessionId: currentSessionId,
      role: MessageRole.system,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await ref.read(chatMessagesProvider.notifier).saveMessage(systemMessage);
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text, List<FileItem> attachments) async {
    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a session first')),
      );
      return;
    }

    final connection = ref.watch(connectionProvider);
    if (!connection.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to OpenClaw')),
      );
      return;
    }

    // Check if this is a slash command
    if (text.startsWith('/')) {
      final trimmed = text.trim();
      final firstSpace = trimmed.indexOf(' ');
      final commandName = firstSpace > 0
          ? trimmed.substring(1, firstSpace)
          : trimmed.substring(1);
      final args = firstSpace > 0 ? trimmed.substring(firstSpace + 1).trim() : '';
      final client = ref.read(connectionProvider.notifier).client;
      await _executeSlashCommand(commandName, args, trimmed, attachments, client, currentSessionId);
      return;
    }

    // Upload attachments first
    final uploadedAttachments = <FileItem>[];
    final client = ref.read(connectionProvider.notifier).client;

    for (final file in attachments) {
      if (file.localPath != null) {
        final url = await client.uploadFile(file.localPath!, file.name);
        if (url != null) {
          uploadedAttachments.add(file.copyWith(remoteUrl: url));
        }
      } else {
        uploadedAttachments.add(file);
      }
    }

    final content = text.trim();
    if (content.isEmpty && uploadedAttachments.isEmpty) return;

    // Send user message
    final message = await ref
        .read(chatMessagesProvider.notifier)
        .sendMessage(
          content: content,
          role: MessageRole.user,
        );

    message.attachments = uploadedAttachments;
    await ref.read(chatMessagesProvider.notifier).saveMessage(message);

    _scrollToBottom();

    // Get AI response
    final assistantMessage = ChatMessage(
      id: const Uuid().v4(),
      sessionId: currentSessionId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      attachments: null,
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
          InputBar(
            onSend: _sendMessage,
            enabled: connection.isConnected,
          ),
        ],
      ),
    );
  }
}
