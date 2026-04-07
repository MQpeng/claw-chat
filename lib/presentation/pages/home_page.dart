import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../providers/session_provider.dart';
import '../providers/connection_provider.dart';
import '../../domain/entities/chat_session.dart';
import 'session_search_delegate.dart';
import 'overview_page.dart';
import 'channels_page.dart';
import 'nodes_page.dart';
import 'cron_jobs_page.dart';
import 'exec_approvals_page.dart';
import 'config_page.dart';
import 'debug_page.dart';
import 'update_page.dart';
import 'settings_page.dart';
import 'pairing_page.dart';
import 'client_logs_page.dart';
import 'skills_page.dart';
import 'chat_page.dart';
import '../widgets/session_list_item.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  bool _didAutoCreate = false;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    // Initialize Hive and connect - only once in initState
    // loadSavedConfig is now done in ConnectionNotifier.build() automatically
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didInit) return;
      _didInit = true;
      // After connection, refresh sessions from gateway if already connected
      if (ref.watch(connectionProvider).isConnected) {
        await ref.read(sessionListProvider.notifier).refreshFromRemote();
      }
    });
  }

  Future<void> _createNewSession() async {
    final connection = ref.watch(connectionProvider);
    if (!connection.isConnected) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(l10n.notConnectedCannotCreateSession),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(connectionProvider.notifier).connect();
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: 'default');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.newSession),
        content: TextField(
          controller: controller,
          decoration:  InputDecoration(
            labelText: l10n.sessionName,
            hintText: l10n.enterSessionName,
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:  Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(context).pop(text.isEmpty ? null : text);
            },
            child:  Text(l10n.create),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      try {
        final session = await ref.read(sessionListProvider.notifier).create(name);
        if (mounted) {
          ref.read(currentSessionIdProvider.notifier).state = session.id;
          // If not on sessions tab, switch to it
          setState(() {
            _currentIndex = 0;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('${l10n.failedToCreateSession}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.deleteSession),
        content: Text('${l10n.areYouSureYouWantToDelete} "${session.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:  Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentId = ref.watch(currentSessionIdProvider);
      if (currentId == session.id) {
        ref.read(currentSessionIdProvider.notifier).state = null;
      }
      await ref.read(sessionListProvider.notifier).delete(session.id);
    }
  }

  Future<void> _renameSession(ChatSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: session.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.renameSession),
        content: TextField(
          controller: controller,
          decoration:  InputDecoration(
            labelText: l10n.sessionName,
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            Navigator.of(context).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:  Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child:  Text(l10n.save),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != session.name) {
      await ref.read(sessionListProvider.notifier).rename(session.id, newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(sessionListProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final connection = ref.watch(connectionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if we have any sessions, if not create one automatically
    if (sessions.isEmpty && connection.isConnected && !_didAutoCreate) {
      _didAutoCreate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Auto-create 'default' session without asking
        try {
          final session = await ref.read(sessionListProvider.notifier).create('default');
          if (mounted) {
            ref.read(currentSessionIdProvider.notifier).state = session.id;
          }
        } catch (e) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text('${l10n.failedToCreateSession}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }

    // Get connection status visual
    final (statusColor, statusText) = _getStatusInfo(context, connection.status);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCurrentTitle(_currentIndex, l10n),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: connection.status == ConnectionStatus.error &&
                      connection.errorMessage != null
                  ? () => _showErrorDetails(context, connection.errorMessage!)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0 && currentSessionId == null) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final selected = await showSearch<ChatSession?>(
                  context: context,
                  delegate: SessionSearchDelegate(ref),
                );
                if (selected != null && context.mounted) {
                  ref.read(currentSessionIdProvider.notifier).state = selected.id;
                  if (!ref.watch(connectionProvider).isConnected) {
                    ref.read(connectionProvider.notifier).connect();
                  }
                }
              },
              tooltip: l10n.searchSessions,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createNewSession,
              tooltip: l10n.createNew,
            ),
          ],
        ],
      ),
      body: _buildBody(context, _currentIndex, sessions, currentSessionId),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            label: l10n.sessions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.control,
          ),
          NavigationDestination(
            icon: const Icon(Icons.devices_outlined),
            label: l10n.nodes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && currentSessionId == null
          ? FloatingActionButton(
              onPressed: _createNewSession,
              child: const Icon(Icons.add),
              tooltip: l10n.createNew,
            )
          : null,
    );
  }

  String _getCurrentTitle(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.sessions;
      case 1:
        return l10n.control;
      case 2:
        return l10n.nodes;
      case 3:
        return l10n.settings;
      default:
        return 'Claw Chat';
    }
  }

  Widget _buildBody(
    BuildContext context,
    int currentTab,
    List<ChatSession> sessions,
    String? currentSessionId,
  ) {
    switch (currentTab) {
      case 0: // Sessions
        if (currentSessionId == null) {
          return _buildSessionList(context, sessions, currentSessionId);
        }
        return const ChatPage();
      case 1: // Control - all management pages
        return _buildControlList(context);
      case 2: // Nodes
        return const NodesPage();
      case 3: // Settings
        return const SettingsPage();
      default:
        return _buildSessionList(context, sessions, currentSessionId);
    }
  }

  Widget _buildSessionList(
    BuildContext context,
    List<ChatSession> sessions,
    String? currentSessionId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(l10n.selectASessionToStartChatting),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createNewSession,
              child:  Text(l10n.newSession),
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
            // Allow opening session even when disconnected (read offline)
            ref.read(currentSessionIdProvider.notifier).state = session.id;
            // Try connect if not connected, but still open session
            final connection = ref.watch(connectionProvider);
            if (!connection.isConnected) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                  content: Text(AppLocalizations.of(context)!.notConnectedWillOpenOffline),
                  backgroundColor: Colors.orange,
                ),
              );
              ref.read(connectionProvider.notifier).connect();
            }
            // Close drawer on mobile already handled by bottom nav
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

  Widget _buildControlList(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.message_outlined),
          title: Text(AppLocalizations.of(context)!.channels),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChannelsPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(AppLocalizations.of(context)!.cronJobs),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CronJobsPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.widgets_outlined),
          title: Text(AppLocalizations.of(context)!.skills),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SkillsPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.terminal_outlined),
          title: Text(AppLocalizations.of(context)!.exec),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExecApprovalsPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(AppLocalizations.of(context)!.config),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConfigPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: Text(AppLocalizations.of(context)!.logs),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientLogsPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: Text(AppLocalizations.of(context)!.debug),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DebugPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.update_outlined),
          title: Text(AppLocalizations.of(context)!.update),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UpdatePage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_outlined),
          title: Text(AppLocalizations.of(context)!.overview),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OverviewPage()),
            );
          },
        ),
      ],
    );
  }

  (Color, String) _getStatusInfo(BuildContext context, ConnectionStatus status) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ConnectionStatus.loading:
        return (Colors.blue, l10n.loading);
      case ConnectionStatus.disconnected:
        return (theme.colorScheme.onSurface.withOpacity(0.6), l10n.disconnected);
      case ConnectionStatus.connecting:
        return (Colors.orange, l10n.connecting);
      case ConnectionStatus.connected:
        return (Colors.green, l10n.connected);
      case ConnectionStatus.error:
        return (Colors.red, l10n.connectionError);
    }
  }

  void _showErrorDetails(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.connectionError),
        content: SelectableText(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:  Text(l10n.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(connectionProvider.notifier).connect();
            },
            child:  Text(l10n.reconnect),
          ),
        ],
      ),
    );
  }
}
