import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/connection_provider.dart' as cp;
import '../providers/session_provider.dart';
import '../../../domain/entities/chat_session.dart';
import 'chat_page.dart';
import 'settings_page.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(sessionListProvider);
    final connection = ref.watch(cp.connectionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeSessionsCount = sessions.where((s) => !s.isArchived).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildStatusCard(context, connection, l10n, colorScheme),
            const SizedBox(height: 16),

            // Statistics Cards
            _buildStatisticsGrid(context, activeSessionsCount, l10n, colorScheme),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, ref, connection, l10n),
            const SizedBox(height: 24),

            // Recent Sessions
            if (sessions.isNotEmpty) ...[
              Text(
                l10n.recentSessions,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentSessions(context, ref, sessions.take(5).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    cp.ConnectionState connection,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final (statusColor, statusText) = _getStatusInfo(context, connection.status);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.connectionStatus,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                  if (connection.config != null && connection.config!.gatewayUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      connection.config!.gatewayUrl,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    int activeSessions,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 400 ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          context,
          icon: Icons.chat_bubble_outline,
          title: l10n.activeSessions,
          value: activeSessions.toString(),
          color: colorScheme.primary,
        ),
        // TODO: Add these when we implement the features
        _buildStatCard(
          context,
          icon: Icons.devices_outlined,
          title: l10n.connectedNodes,
          value: '0',
          color: colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    cp.ConnectionState connection,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (connection.status != cp.ConnectionStatus.connected)
          _buildActionChip(
            context,
            icon: Icons.refresh_outlined,
            label: l10n.reconnect,
            onTap: () {
              ref.read(cp.connectionProvider.notifier).connect();
            },
          ),
        _buildActionChip(
          context,
          icon: Icons.settings_outlined,
          label: l10n.settings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildRecentSessions(
    BuildContext context,
    WidgetRef ref,
    List<ChatSession> sessions,
  ) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(session.name),
            subtitle: session.isPinned
                ? Text(
                    'Pinned',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(currentSessionIdProvider.notifier).state = session.id;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            },
          );
        },
      ),
    );
  }

  (Color, String) _getStatusInfo(BuildContext context, cp.ConnectionStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case cp.ConnectionStatus.loading:
        return (Colors.blue, l10n.loading);
      case cp.ConnectionStatus.disconnected:
        return (Colors.grey[600]!, l10n.disconnected);
      case cp.ConnectionStatus.connecting:
        return (Colors.orange, l10n.connecting);
      case cp.ConnectionStatus.connected:
        return (Colors.green, l10n.connected);
      case cp.ConnectionStatus.error:
        return (Colors.red, l10n.connectionError);
    }
  }
}
