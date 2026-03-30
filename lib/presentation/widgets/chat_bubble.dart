import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role.isUser;
    final theme = Theme.of(context);
    final primaryColor = isUser ? Colors.blue : theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: Colors.blueGrey[100],
                  radius: 16,
                  child: const Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomLeft: isUser
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isUser
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                      ),
                      child: MarkdownBody(
                        data: message.content,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          // TODO: Open link
                        },
                        styleSheet: _markdownStyle(theme, isUser),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  radius: 16,
                  child: const Icon(Icons.person, color: Colors.blue, size: 16),
                ),
              ],
            ],
          ),
          if (message.status.isSending && message.role.isAssistant)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 2),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUser ? Colors.white : Colors.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(ThemeData theme, bool isUser) {
    final textColor = isUser
        ? Colors.white
        : (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, fontSize: 16),
      a: TextStyle(color: isUser ? Colors.white : Colors.blue),
      code: TextStyle(
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        color: textColor,
        fontSize: 14,
      ),
    );
  }
}
