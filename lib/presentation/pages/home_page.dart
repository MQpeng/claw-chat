import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../data/datasource/remote/openclaw_client.dart';
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
import 'settings_page.dart';
import 'pairing_page.dart';
import 'client_logs_page.dart';
import 'skills_page.dart';
import 'chat_page.dart';
import '../widgets/session_list_item.dart';

enum HomeMenuItem {
  overview(icon: Icons.dashboard_outlined, label: 'Overview'),
  chat(icon: Icons.chat_bubble_outline, label: 'Chat'),
  channels(icon: Icons.message_outlined, label: 'Channels'),
  sessions(icon: Icons.forum_outlined, label: 'Sessions'),
  cronJobs(icon: Icons.schedule_outlined, label: 'Cron Jobs'),
  skills(icon: Icons.widgets_outlined, label: 'Skills'),
  nodes(icon: Icons.devices_outlined, label: 'Nodes'),
  exec(icon: Icons.terminal_outlined, label: 'Exec'),
  config(icon: Icons.settings_outlined, label: 'Config'),
  logs(icon: Icons.bug_report_outlined, label: 'Logs'),
  debug(icon: Icons.bug_report_outlined, label: 'Debug'),
  update(icon: Icons.update_outlined, label: 'Update'),
  settings(icon: Icons.tune_outlined, label: 'Settings');

  const HomeMenuItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _didAutoCreate = false;
  bool _didInit = false;
  HomeMenuItem _selectedMenuItem = HomeMenuItem.overview;

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
          // Switch to chat page after creating
          setState(() {
            _selectedMenuItem = HomeMenuItem.chat;
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
            setState(() {
              _selectedMenuItem = HomeMenuItem.chat;
            });
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
    final status = connection.status;
    final (statusColor, statusText) = _getStatusInfo(context, status);

    // Mobile layout - show session list or chat page
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer header with app info
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'OpenClaw',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.openClawMobileClient,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            ...HomeMenuItem.values.map((item) {
              final isSelected = _selectedMenuItem == item;
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                title: Text(
                  _getMenuItemLabel(item, l10n),
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedMenuItem = item;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const Spacer(),
            // Status info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getMenuItemLabel(_selectedMenuItem, l10n),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (_selectedMenuItem == HomeMenuItem.chat) ...[
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
          if (_selectedMenuItem == HomeMenuItem.settings)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              tooltip: l10n.settings,
            ),
        ],
      ),
      body: _buildBody(
        context,
        _selectedMenuItem,
        sessions,
        currentSessionId,
        isTablet,
      ),
    );
  }

  (Color, String) _getStatusInfo(BuildContext context, ConnectionStatus status) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ConnectionStatus.loading:
        return (Colors.blue, l10n.loading);
      case ConnectionStatus.disconnected:
        return (Colors.grey[600]!, l10n.disconnected);
      case ConnectionStatus.connecting:
        return (Colors.orange, l10n.connecting);
      case ConnectionStatus.connected:
        return (Colors.green, l10n.connected);
      case ConnectionStatus.error:
        return (Colors.red, l10n.connectionError);
    }
  }

  String _getMenuItemLabel(HomeMenuItem item, AppLocalizations l10n) {
    switch (item) {
      case HomeMenuItem.overview:
        return l10n.overview;
      case HomeMenuItem.chat:
        return l10n.chat;
      case HomeMenuItem.channels:
        return l10n.channels;
      case HomeMenuItem.sessions:
        return l10n.chat;
      case HomeMenuItem.cronJobs:
        return l10n.cronJobs;
      case HomeMenuItem.skills:
        return l10n.skills;
      case HomeMenuItem.nodes:
        return l10n.nodes;
      case HomeMenuItem.exec:
        return l10n.exec;
      case HomeMenuItem.config:
        return l10n.config;
      case HomeMenuItem.logs:
        return l10n.logs;
      case HomeMenuItem.debug:
        return l10n.debug;
      case HomeMenuItem.update:
        return l10n.update;
      case HomeMenuItem.settings:
        return l10n.settings;
    }
  }

  Widget _buildBody(
    BuildContext context,
    HomeMenuItem selected,
    List<ChatSession> sessions,
    String? currentSessionId,
    bool isTablet,
  ) {
    switch (selected) {
      case HomeMenuItem.overview:
        return const OverviewPage();
      case HomeMenuItem.chat:
      case HomeMenuItem.sessions:
        if (currentSessionId == null) {
          return _buildSessionList(context, sessions, currentSessionId);
        }
        return isTablet
            ? Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: _buildSessionList(context, sessions, currentSessionId),
                  ),
                  const Expanded(child: ChatPage()),
                ],
              )
            : const ChatPage();
      case HomeMenuItem.channels:
        return const ChannelsPage();
      case HomeMenuItem.cronJobs:
        return const CronJobsPage();
      case HomeMenuItem.skills:
        return const SkillsPage();
      case HomeMenuItem.nodes:
        return const NodesPage();
      case HomeMenuItem.exec:
        return const ExecApprovalsPage();
      case HomeMenuItem.config:
        return const ConfigPage();
      case HomeMenuItem.logs:
        return const ClientLogsPage();
      case HomeMenuItem.debug:
        return const DebugPage();
      case HomeMenuItem.update:
        return const Center(
          child: Text('Update coming soon...'),
        );
      case HomeMenuItem.settings:
        return const SettingsPage();
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
