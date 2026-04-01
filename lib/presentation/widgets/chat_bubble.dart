import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role.isUser;
    final isSystem = message.role.isSystem;
    final theme = Theme.of(context);
    final primaryColor = isUser
        ? theme.colorScheme.primary
        : isSystem
            ? theme.colorScheme.secondaryContainer
            : (theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceVariant
                : Colors.grey[200]);
    final textColor = isUser
        ? Colors.white
        : isSystem
            ? theme.colorScheme.onSecondaryContainer
            : (theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87);

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(
                  color: Colors.blueGrey[100]!,
                  icon: Icons.smart_toy,
                  iconColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : Radius.zero,
                      bottomRight: isUser
                          ? Radius.zero
                          : const Radius.circular(20),
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      // TODO: Open link
                    },
                    styleSheet: _markdownStyle(theme, textColor, isUser),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  icon: Icons.person,
                  iconColor: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          if (message.status.isSending && message.role.isAssistant)
            Padding(
              padding: EdgeInsets.only(
                left: (!isUser) ? 40 : 0,
                right: isUser ? 40 : 0,
                top: 4,
              ),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 18,
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(
    ThemeData theme,
    Color textColor,
    bool isUser,
  ) {
    return MarkdownStyleSheet(
      p: TextStyle(
        color: textColor,
        fontSize: 16,
        height: 1.4,
      ),
      a: TextStyle(
        color: isUser
            ? Colors.white.withOpacity(0.9)
            : theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        backgroundColor: (theme.brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[100])!
            .withOpacity(0.8),
        color: textColor,
        fontSize: 14,
        height: 1.4,
      ),
      codeblockDecoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[100])!
            .withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      blockSpacing: 8,
      listIndent: 24,
    );
  }
}
