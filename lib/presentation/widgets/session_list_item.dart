import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../domain/entities/chat_session.dart';

class SessionListItem extends StatelessWidget {
  final ChatSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleArchive;

  const SessionListItem({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onTogglePin,
    required this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onTogglePin(),
            backgroundColor: Colors.blue,
            icon: session.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: session.isPinned ? 'Unpin' : 'Pin',
          ),
          SlidableAction(
            onPressed: (_) => onRename(),
            backgroundColor: Colors.orange,
            icon: Icons.edit,
            label: 'Rename',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        leading: session.isPinned
            ? const Icon(Icons.push_pin, size: 16, color: Colors.blue)
            : null,
        title: Text(
          session.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(session.updatedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: session.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
