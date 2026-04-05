import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:highlight/highlight.dart';
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
                    // Code highlight builder for flutter_markdown 0.7.x
                    builders: {
                      'code': CodeBuilder(theme: theme),
                      'pre': PreBuilder(theme: theme),
                    },
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

// Code block builder for inline code
class CodeBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  CodeBuilder({required this.theme});

  @override
  Widget? visitElementAfter(
    md.Element element,
    TextStyle? preferredStyle,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final text = element.textContent;
    return Text(
      text,
      style: (preferredStyle ?? const TextStyle()).merge(
        TextStyle(
          backgroundColor: (isDark ? Colors.grey[900] : Colors.grey[100])!
              .withOpacity(0.8),
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          height: 1.4,
          fontFamily: 'Menlo',
          fontFamilyFallback: const ['Courier', 'monospace'],
        ),
      ),
    );
  }
}

// Pre block builder for code blocks with highlight
class PreBuilder extends MarkdownElementBuilder {
  final ThemeData theme;
  PreBuilder({required this.theme});

  // Convert highlight Node to TextSpan
  List<InlineSpan> _convertNodes(Node node, TextStyle baseStyle, bool isDark) {
    final List<InlineSpan> spans = [];
    if (node.value != null && node.value!.isNotEmpty) {
      spans.add(TextSpan(
        text: node.value,
        style: baseStyle.merge(
          node.className != null && node.className!.isNotEmpty
              ? TextStyle(
                  color: Color(
                    int.parse('0xFF${_getColorForClass(node.className!, isDark)}'),
                  ),
                )
              : null,
        ),
      ));
    }
    if (node.children != null) {
      for (final child in node.children!) {
        spans.addAll(_convertNodes(child, baseStyle, isDark));
      }
    }
    return spans;
  }

  // Get color from highlight class (simplified)
  String _getColorForClass(String className, bool isDark) {
    switch (className) {
      case 'keyword':
        return '0000FF';
      case 'string':
        return '008000';
      case 'comment':
        return '808080';
      case 'number':
        return 'FF0000';
      case 'function':
        return '800080';
      case 'title':
        return '000000';
      case 'params':
        return '000000';
      default:
        return isDark ? 'FFFFFF' : '000000';
    }
  }

  @override
  Widget? visitElementAfter(
    md.Element element,
    TextStyle? preferredStyle,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    String code = element.textContent.trim();
    String? language;
    
    // Extract language from class name (language-dart → dart)
    if (element.attributes['class'] != null) {
      final className = element.attributes['class']!;
      if (className.startsWith('language-')) {
        language = className.substring(9);
      }
    }

    late Result highlighted;
    if (language != null && language.isNotEmpty) {
      highlighted = highlight.parse(code, language: language);
    } else {
      highlighted = highlight.parse(code);
    }

    final baseStyle = (preferredStyle ?? const TextStyle()).merge(
      TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
        height: 1.4,
        fontFamily: 'Menlo',
        fontFamilyFallback: const ['Courier', 'monospace'],
      ),
    );

    List<InlineSpan> spans = [];
    if (highlighted.nodes != null && highlighted.nodes!.isNotEmpty) {
      for (final node in highlighted.nodes!) {
        spans.addAll(_convertNodes(node, baseStyle, isDark));
      }
    } else {
      spans = [TextSpan(text: code, style: baseStyle)];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: spans,
        ),
      ),
    );
  }
}
