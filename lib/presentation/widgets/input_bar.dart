import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import '../../../domain/entities/file_item.dart';
import 'attachment_picker.dart';
import 'selected_attachments.dart';

class InputBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<List<FileItem>>? onAttachmentsAdded;
  final List<FileItem> selectedAttachments;
  final ValueChanged<FileItem> onRemoveAttachment;

  const InputBar({
    super.key,
    required this.onSend,
    this.onAttachmentsAdded,
    this.selectedAttachments = const [],
    required this.onRemoveAttachment,
  });

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && widget.selectedAttachments.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SelectedAttachments(
            files: widget.selectedAttachments,
            onRemove: widget.onRemoveAttachment,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onAttachmentsAdded != null)
                AttachmentPicker(
                  onAttachmentSelected: widget.onAttachmentsAdded!,
                ),
              const SizedBox(width: 4),
              Expanded(
                child: AutoSizeTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 6,
                  minLines: 1,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _controller.text.trim().isEmpty &&
                        widget.selectedAttachments.isEmpty
                    ? null
                    : () => _handleSend(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
