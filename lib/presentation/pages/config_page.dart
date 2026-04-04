import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../l10n/app_localizations.dart';
import '../../../data/datasource/remote/openclaw_client.dart';
import '../providers/connection_provider.dart';

final configProvider = FutureProvider<String>((ref) async {
  final connection = ref.watch(connectionProvider);
  if (!connection.isConnected) {
    throw Exception('Not connected');
  }

  final client = ref.read(connectionProvider.notifier).client;
  final result = await client.request('config.get', {});
  
  if (result is Map && result.containsKey('result')) {
    final configJson = result['result'];
    return const JsonEncoder.withIndent('  ').convert(configJson);
  }
  
  return '';
});

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  bool _isEditing = false;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
    });

    try {
      final json = jsonDecode(_controller.text);
      final connection = ref.read(connectionProvider);
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('config.set', {
        'config': json,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(l10n.configSaved),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        ref.refresh(configProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('${l10n.configSaveError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final configAsync = ref.watch(configProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.config),
        actions: [
          if (!_isEditing && connection.isConnected)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final currentConfig = configAsync.valueOrNull ?? '';
                _controller.text = currentConfig;
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: l10n.edit,
            ),
          if (_isEditing)
            _saving
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _saveConfig,
                    tooltip: l10n.save,
                  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(configProvider);
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: !connection.isConnected
          ? Center(
              child: Text(l10n.notConnected),
            )
          : configAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${l10n.error}: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(configProvider),
                      child: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
              data: (config) {
                if (_isEditing) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                    ),
                  );
                }

                if (config.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noConfig, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(l10n.noConfigHint),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    config,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
