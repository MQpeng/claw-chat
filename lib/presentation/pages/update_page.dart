import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String? releaseNotes;
  final String? downloadUrl;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    this.releaseNotes,
    this.downloadUrl,
  });

  factory UpdateInfo.fromJson(Map json) {
    return UpdateInfo(
      currentVersion: json['currentVersion'] as String? ?? '',
      latestVersion: json['latestVersion'] as String? ?? '',
      updateAvailable: json['updateAvailable'] as bool? ?? false,
      releaseNotes: json['releaseNotes'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}

final updateProvider = FutureProvider<UpdateInfo>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    throw Exception('Not connected');
  }

  final client = ref.read(connectionProvider.notifier).client;
  final result = await client.request('update.check', {});
  
  if (result is Map && result.containsKey('result')) {
    return UpdateInfo.fromJson(result['result'] as Map);
  }
  
  return UpdateInfo(
    currentVersion: '',
    latestVersion: '',
    updateAvailable: false,
  );
});

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  bool _updating = false;

  Future<void> _performUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _updating = true;
    });

    try {
      final connection = ref.read(connectionProvider);
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('update.perform', {});
      
      if (mounted) {
        if (result is Map && result.containsKey('result') && result['result']['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.updateStarted),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(l10n.updateFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${l10n.updateFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
        ref.refresh(updateProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final updateAsync = ref.watch(updateProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.update),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(updateProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : updateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${l10n.error}: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(updateProvider),
                      child: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
              data: (update) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          update.updateAvailable
                              ? Icons.system_update
                              : Icons.check_circle_outline,
                          size: 80,
                          color: update.updateAvailable
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(height: 24),
                         Text(
                          update.updateAvailable
                              ? l10n.updateAvailable
                              : l10n.upToDate,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (update.currentVersion.isNotEmpty)
                          Text(
                            '${l10n.currentVersion}: ${update.currentVersion}',
                            style: theme.textTheme.titleMedium,
                          ),
                        if (update.latestVersion.isNotEmpty && update.updateAvailable)
                          const SizedBox(height: 8),
                        if (update.latestVersion.isNotEmpty && update.updateAvailable)
                          Text(
                            '${l10n.latestVersion}: ${update.latestVersion}',
                            style: theme.textTheme.titleMedium,
                          ),
                        const SizedBox(height: 16),
                        if (update.releaseNotes != null && update.releaseNotes!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              update.releaseNotes!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (update.updateAvailable)
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: _updating ? null : _performUpdate,
                              child: _updating
                                  ? const CircularProgressIndicator()
                                  : Text(l10n.installUpdate),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
