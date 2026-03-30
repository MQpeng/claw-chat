import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_session.dart';
import '../providers/session_provider.dart';

class SessionSearchDelegate extends SearchDelegate<ChatSession?> {
  final WidgetRef ref;

  SessionSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResults();
  }

  Widget _buildResults() {
    final sessions = ref.watch(sessionListProvider);
    final filtered = sessions.where((session) {
      return session.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No sessions found'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final session = filtered[index];
        return ListTile(
          title: Text(session.name),
          subtitle: Text(
            session.updatedAt.toString().split('.')[0],
          ),
          onTap: () {
            close(context, session);
          },
        );
      },
    );
  }
}
