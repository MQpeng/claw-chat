import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../providers/connection_provider.dart';
import '../../domain/entities/chat_session.dart';
import 'session_search_delegate.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import '../widgets/session_list_item.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize Hive and connect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).loadSavedConfig();
    });
  }

  Future<void> _createNewSession() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            hintText: 'Enter session name',
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final session = await ref.read(sessionListProvider.notifier).createSession(name);
      ref.read(currentSessionIdProvider.notifier).state = session.id;
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentId = ref.read(currentSessionIdProvider);
      if (currentId == session.id) {
        ref.read(currentSessionIdProvider.notifier).state = null;
      }
      await ref.read(sessionListProvider.notifier).deleteSession(session.id);
    }
  }

  Future<void> _renameSession(ChatSession session) async {
    final controller = TextEditingController(text: session.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != session.name) {
      await ref.read(sessionListProvider.notifier).renameSession(session.id, newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionListProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final connection = ref.watch(connectionProvider);

    // Check if we have any sessions, if not create one automatically
    if (sessions.isEmpty && connection.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createNewSession();
      });
    }

    // Mobile layout - show session list or chat page
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      drawer: isTablet
          ? null
          : Drawer(
              child: _buildSessionList(context, sessions, currentSessionId),
            ),
      appBar: AppBar(
        centerTitle: true,
        leading: isTablet
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final selected = await showSearch<ChatSession?>(
                context: context,
                delegate: SessionSearchDelegate(ref),
              );
              if (selected != null && context.mounted) {
                ref.read(currentSessionIdProvider.notifier).state = selected.id;
                if (!ref.read(connectionProvider).isConnected) {
                  ref.read(connectionProvider.notifier).connect();
                }
              }
            },
            tooltip: 'Search Sessions',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSession,
            tooltip: 'New Session',
          ),
        ],
      ),
      body: isTablet
          ? Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _buildSessionList(context, sessions, currentSessionId),
                ),
              ],
            )
          : currentSessionId == null
              ? _buildSessionList(context, sessions, currentSessionId)
              : const ChatPage(),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<ChatSession> sessions,
    String? currentSessionId,
  ) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No sessions yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createNewSession,
              child: const Text('Create First Session'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return SessionListItem(
          session: session,
          isSelected: session.id == currentSessionId,
          onTap: () {
            ref.read(currentSessionIdProvider.notifier).state = session.id;
            if (!ref.read(connectionProvider).isConnected) {
              ref.read(connectionProvider.notifier).connect();
            }
            // Close drawer on mobile
            if (!MediaQuery.of(context).size.width.isFinite ||
                MediaQuery.of(context).size.width < 600) {
              Scaffold.of(context).closeDrawer();
            }
          },
          onDelete: () => _deleteSession(session),
          onRename: () => _renameSession(session),
          onTogglePin: () =>
              ref.read(sessionListProvider.notifier).togglePin(session.id),
          onToggleArchive: () =>
              ref.read(sessionListProvider.notifier).toggleArchive(session.id),
        );
      },
    );
  }
}
