import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/file_item.dart';
import 'attachment_picker.dart';
import 'selected_attachments.dart';
import 'slash_command_autocomplete.dart';

class InputBar extends ConsumerStatefulWidget {
  final Function(String text, List<FileItem> attachments) onSend;
  final bool enabled;

  const InputBar({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  final _controller = TextEditingController();
  final List<FileItem> _selectedAttachments = [];
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addAttachment(FileItem file) {
    setState(() {
      _selectedAttachments.add(file);
    });
  }

  void _removeAttachment(FileItem file) {
    setState(() {
      _selectedAttachments.remove(file);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedAttachments.isEmpty) return;

    widget.onSend(text, List.from(_selectedAttachments));
    _controller.clear();
    setState(() {
      _selectedAttachments.clear();
    });
  }

  void _onSlashCommandSelected(String command, String args) {
    setState(() {
      _controller.text = '/$command $args';
    });
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.startsWith('/')) ...[
                SlashCommandAutocomplete(
                  currentText: _controller.text,
                  focusNode: _focusNode,
                  onSelected: _onSlashCommandSelected,
                ),
                const SizedBox(height: 8),
              ],
              if (_selectedAttachments.isNotEmpty) ...[
                SelectedAttachments(
                  files: _selectedAttachments,
                  onRemove: _removeAttachment,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.enabled
                        ? () async {
                            await AttachmentPicker.show(
                              context: context,
                              onFilePicked: _addAttachment,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.attach_file,
                      color: widget.enabled
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    tooltip: 'Add attachment',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 150,
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: widget.enabled,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          isDense: true,
                          filled: true,
                        ),
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onChanged: (_) {
                          setState(() {});
                        },
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: IconButton(
                      onPressed: widget.enabled &&
                              (_controller.text.trim().isNotEmpty ||
                                  _selectedAttachments.isNotEmpty)
                          ? _send
                          : null,
                      icon: Icon(
                        Icons.send_rounded,
                        color: _controller.text.trim().isNotEmpty ||
                                _selectedAttachments.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      tooltip: 'Send',
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
