import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_config.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/message_role.dart';
import '../../../domain/entities/message_status.dart';
import '../../../domain/entities/file_item.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/session_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/theme_provider.dart';
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
  String? _currentStreamingMessageId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
    // Setup main stream listener for chat.stream events after connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connection = ref.read(connectionProvider);
      if (connection.isConnected) {
        _setupStreamListener(connection.config!);
      }
    });
  }

  void _setupStreamListener(AppConfig config) {
    final client = ref.read(connectionProvider.notifier).client;
    client.setupMainStreamListener(
      onStreamEvent: (chunk, messageId, state) {
        if (state == 'delta') {
          if (_currentStreamingMessageId == messageId) {
            ref
                .read(chatMessagesProvider.notifier)
                .appendToMessage(messageId, chunk);
            _scrollToBottom();
          }
        } else if (state == 'final') {
          if (_currentStreamingMessageId == messageId) {
            ref
                .read(chatMessagesProvider.notifier)
                .updateMessageStatus(messageId, MessageStatus.sent);
            _currentStreamingMessageId = null;
          }
        } else if (state == 'error') {
          if (_currentStreamingMessageId == messageId) {
            ref
                .read(chatMessagesProvider.notifier)
                .updateMessageStatus(messageId, MessageStatus.error);
            _currentStreamingMessageId = null;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Streaming error')),
              );
            }
          }
        } else if (state == 'aborted') {
          if (_currentStreamingMessageId == messageId) {
            ref
                .read(chatMessagesProvider.notifier)
                .updateMessageStatus(messageId, MessageStatus.error);
            _currentStreamingMessageId = null;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Response aborted')),
              );
            }
          }
        }
      },
      onStreamError: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stream error: $error')),
          );
        }
      },
      onStreamDone: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection closed')),
          );
        }
      },
    );
  }

  void _onScrollChanged() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.pixels;
      final maxPosition = _scrollController.position.maxScrollExtent;
      setState(() {
        _showScrollToBottom = position < maxPosition - 50;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCirc,
        );
      }
    });
  }

  Future<void> _handleSendSubmitted(
    String text,
    List<FileItem> attachments,
  ) async {
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
    _currentStreamingMessageId = assistantMessage.id;
    _scrollToBottom();

    // Use selected model from settings
    final selectedModel = ref.watch(modelProvider);
    client.sendMessage(
      currentSessionId,
      message,
      onChunk: (_) {},
      onDone: () {},
      onError: (error) {
        ref
            .read(chatMessagesProvider.notifier)
            .updateMessageStatus(assistantMessage.id, MessageStatus.error);
        _currentStreamingMessageId = null;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Streaming error')),
          );
        }
      },
      model: selectedModel.isNotEmpty ? selectedModel : null,
    );
  }

  Future<void> _executeSlashCommand(
    String commandName,
    String args,
    String originalText,
    List<FileItem> attachments,
    OpenClawClient client,
    String currentSessionId,
  ) async {
    switch (commandName) {
      case 'clear':
      case 'new':
        ref.read(chatMessagesProvider.notifier).clearCurrentSession();
        return;
      case 'stop':
        if (ref.read(chatMessagesProvider.notifier).currentRunId != null) {
          client.request('chat.stop', {
            'runId': ref.read(chatMessagesProvider.notifier).currentRunId,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Current run stopped')),
            );
          }
        }
        return;
      default:
        break;
    }

    // Other commands let gateway respond
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
                return ChatBubble(
                  message: message,
                );
              },
            ),
          ),
          if (_showScrollToBottom)
            Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToBottom,
                child: const Icon(Icons.arrow_downward),
              ),
            ),
          InputBar(
            onSend: _handleSendSubmitted,
            enabled: connection.isConnected,
          ),
        ],
      ),
    );
  }
}
