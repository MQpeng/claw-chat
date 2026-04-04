import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class ChannelInfo {
  final String key;
  final String label;
  final String type;
  final bool enabled;
  final Map<String, dynamic> config;

  ChannelInfo({
    required this.key,
    required this.label,
    required this.type,
    required this.enabled,
    required this.config,
  });

  factory ChannelInfo.fromJson(Map json) {
    return ChannelInfo(
      key: json['key'] as String,
      label: json['label'] as String? ?? json['key'],
      type: json['type'] as String? ?? 'unknown',
      enabled: json['enabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }
}

final channelsProvider = FutureProvider<List<ChannelInfo>>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    return [];
  }

  try {
    final client = ref.read(connectionProvider.notifier).client;
    final result = await client.request('channels.list', {});
    List channels = [];
    if (result is Map && result.containsKey('result')) {
      channels = result['result'] as List;
    } else if (result is List) {
      channels = result;
    }

    return channels.map((item) => ChannelInfo.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
});

class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final channelsAsync = ref.watch(channelsProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.channels),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new channel (scan QR)
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(l10n.comingSoon)),
              );
            },
            tooltip: l10n.addChannel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(channelsProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.error}: $error'),
              ),
              data: (channels) {
                if (channels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                         Text(l10n.noChannelsConfigured, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                         Text(l10n.addChannelHint),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: channel.enabled
                              ? Colors.green
                              : Colors.grey,
                          child: Icon(
                            _getChannelIcon(channel.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(channel.label),
                        subtitle: Text('${channel.type} • ${channel.key}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: channel.enabled,
                              onChanged: (value) {
                                // TODO: Toggle channel enabled
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                // TODO: Edit/Delete channel
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.comingSoon)),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: View channel details/test
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(l10n.comingSoon)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  IconData _getChannelIcon(String type) {
    switch (type.toLowerCase()) {
      case 'discord':
        return Icons.discord;
      case 'telegram':
        return Icons.send;
      case 'signal':
        return Icons.chat_bubble;
      case 'slack':
        return Icons.workspaces;
      case 'webhook':
        return Icons.webhook;
      default:
        return Icons.message;
    }
  }
}
