import 'package:flutter/material.dart';
import '../../../domain/entities/chat_message.dart';

typedef SlashCommandSelected = void Function(String command, String args);

class SlashCommandAutocomplete extends StatelessWidget {
  final String currentText;
  final SlashCommandSelected onSelected;
  final FocusNode focusNode;

  const SlashCommandAutocomplete({
    super.key,
    required this.currentText,
    required this.onSelected,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Only show autocomplete if text starts with / and has at least one character
    if (!currentText.startsWith('/')) return const SizedBox.shrink();

    final input = currentText.substring(1);
    final commands = _getMatchingCommands(input);

    if (commands.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: commands.length,
        itemBuilder: (context, index) {
          final cmd = commands[index];
          return ListTile(
            leading: const Icon(Icons.bolt, size: 20),
            title: Text('/${cmd.name}'),
            subtitle: Text(cmd.description),
            onTap: () {
              onSelected(cmd.name, '');
              focusNode.requestFocus();
            },
          );
        },
      ),
    );
  }

  List<SlashCommand> _getMatchingCommands(String input) {
    final all = _allCommands;
    if (input.isEmpty) {
      return all;
    }
    final lower = input.toLowerCase();
    return all.where((cmd) {
      return cmd.name.toLowerCase().contains(lower);
    }).toList();
  }
}

class SlashCommand {
  final String name;
  final String description;
  final String? args;
  final String category;

  const SlashCommand({
    required this.name,
    required this.description,
    this.args,
    required this.category,
  });
}

const List<SlashCommand> _allCommands = [
  SlashCommand(
    name: 'help',
    description: 'Show available commands',
    category: 'session',
  ),
  SlashCommand(
    name: 'new',
    description: 'Start new session',
    category: 'session',
  ),
  SlashCommand(
    name: 'clear',
    description: 'Clear chat history',
    category: 'session',
  ),
  SlashCommand(
    name: 'compact',
    description: 'Compact context for current session',
    category: 'session',
  ),
  SlashCommand(
    name: 'reset',
    description: 'Reset current session',
    category: 'session',
  ),
  SlashCommand(
    name: 'stop',
    description: 'Stop current running session',
    category: 'session',
  ),
  SlashCommand(
    name: 'focus',
    description: 'Toggle focus mode',
    category: 'session',
  ),
  SlashCommand(
    name: 'model',
    description: 'Show or set current model',
    args: '[model]',
    category: 'model',
  ),
  SlashCommand(
    name: 'think',
    description: 'Set thinking level (off, low, high)',
    args: '[level]',
    category: 'model',
  ),
  SlashCommand(
    name: 'fast',
    description: 'Toggle fast mode (on/off)',
    args: '[on/off]',
    category: 'model',
  ),
  SlashCommand(
    name: 'verbose',
    description: 'Set verbose level (off/on/full)',
    args: '[level]',
    category: 'model',
  ),
  SlashCommand(
    name: 'usage',
    description: 'Show token usage for current session',
    category: 'session',
  ),
  SlashCommand(
    name: 'agents',
    description: 'List available agents',
    category: 'agent',
  ),
  SlashCommand(
    name: 'kill',
    description: 'Kill sub-agent sessions',
    args: '<id|all>',
    category: 'agent',
  ),
  SlashCommand(
    name: 'steer',
    description: 'Steer active sub-agent session',
    args: '[id] <message>',
    category: 'agent',
  ),
  SlashCommand(
    name: 'redirect',
    description: 'Restart stopped sub-agent session',
    args: '[id] <message>',
    category: 'agent',
  ),
  SlashCommand(
    name: 'export-session',
    description: 'Export current session',
    category: 'session',
  ),
];
