import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class NodeInfo {
  final String nodeId;
  final String label;
  final String version;
  final bool connected;
  final String? address;

  NodeInfo({
    required this.nodeId,
    required this.label,
    required this.version,
    required this.connected,
    this.address,
  });

  factory NodeInfo.fromJson(Map json) {
    return NodeInfo(
      nodeId: json['nodeId'] as String,
      label: json['label'] as String? ?? json['nodeId'],
      version: json['version'] as String? ?? 'unknown',
      connected: json['connected'] as bool? ?? false,
      address: json['address'] as String?,
    );
  }
}

final nodesProvider = FutureProvider<List<NodeInfo>>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    return [];
  }

  try {
    final client = ref.read(connectionProvider.notifier).client;
    final result = await client.request('nodes.list', {});
    List nodes = [];
    if (result is Map && result.containsKey('result')) {
      nodes = result['result'] as List;
    } else if (result is List) {
      nodes = result;
    }

    return nodes.map((item) => NodeInfo.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
});

class NodesPage extends ConsumerStatefulWidget {
  const NodesPage({super.key});

  @override
  ConsumerState<NodesPage> createState() => _NodesPageState();
}

class _NodesPageState extends ConsumerState<NodesPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nodesAsync = ref.watch(nodesProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nodes),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(nodesProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : nodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.error}: $error'),
              ),
              data: (nodes) {
                if (nodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noConnectedNodes, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(l10n.noConnectedNodesHint),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: node.connected ? Colors.green : Colors.grey,
                          child: Icon(
                            node.connected ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(node.label),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${node.nodeId}'),
                            if (node.address != null)
                              Text('${node.address!} • v${node.version}')
                            else
                              Text('v${node.version}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // TODO: Node actions: disconnect, forget, etc.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.comingSoon)),
                            );
                          },
                        ),
                        onTap: () {
                          // TODO: Node details
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
}
