import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/datasource/local/hive_storage.dart';
import '../providers/theme_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final defaultModel = ref.watch(modelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Theme Mode'),
                    subtitle: Text(_themeModeToString(themeMode)),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      onChanged: (newMode) {
                        if (newMode != null) {
                          ref.read(themeProvider.notifier).setTheme(newMode);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Theme Color'),
                    subtitle: Text(themeColor.name),
                    trailing: DropdownButton<AppThemeColor>(
                      value: themeColor,
                      onChanged: (newColor) {
                        if (newColor != null) {
                          ref.read(themeColorProvider.notifier).setThemeColor(newColor);
                        }
                      },
                      items: AppThemeColor.values.map((color) {
                        return DropdownMenuItem<AppThemeColor>(
                          value: color,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(color.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Default Model'),
                    subtitle: Text(defaultModel.isEmpty ? 'Server default' : defaultModel),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showModelSelection(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Clear All Sessions',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Delete all sessions and messages'),
                    onTap: () => _clearAllData(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Reconnect to OpenClaw'),
                    subtitle: const Text('Disconnect and reconnect'),
                    onTap: () {
                      ref.read(connectionProvider.notifier).disconnect();
                      ref.read(connectionProvider.notifier).connect();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  const AboutListTile(
                    applicationName: 'claw-chat',
                    applicationLegalese: 'MIT License',
                    aboutBoxChildren: [
                      SizedBox(height: 8),
                      Text(
                        'Lightweight Flutter mobile client for OpenClaw\n'
                        'Connect directly to your OpenClaw Gateway via LAN/Tailscale',
                      ),
                    ],
                  ),
                  if (_version.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Version'),
                          Text(
                            _version,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showModelSelection(BuildContext context, WidgetRef ref) async {
    final connection = ref.watch(connectionProvider);
    if (!connection.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected to OpenClaw')),
        );
      }
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (context) => const ModelSelectionDialog(),
    );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all sessions and messages.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final storage = HiveStorage();
    for (final session in storage.getAllSessions()) {
      await storage.deleteSession(session.id);
    }

    ref.read(sessionListProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }
}

class ModelSelectionDialog extends ConsumerStatefulWidget {
  const ModelSelectionDialog({super.key});

  @override
  ConsumerState<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends ConsumerState<ModelSelectionDialog> {
  bool _loading = false;
  List<String> _models = [];
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedModel = ref.read(modelProvider);
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loading = true;
    });

    try {
      final client = ref.read(connectionProvider.notifier).client;
      final result = await client.request('models.list');
      if (result is Map && result.containsKey('models')) {
        final models = (result['models'] as List).cast<String>();
        setState(() {
          _models = models;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load models: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = ref.watch(modelProvider);
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selectModel),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _models.isEmpty
                ? Center(child: Text(l10n.noData))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _models.length,
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      return RadioListTile<String>(
                        title: Text(model),
                        value: model,
                        groupValue: _selectedModel ?? currentModel,
                        onChanged: (value) {
                          setState(() {
                            _selectedModel = value;
                          });
                        },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            if (_selectedModel != null) {
              ref.read(modelProvider.notifier).setModel(_selectedModel!);
            } else if (_models.isNotEmpty) {
              ref.read(modelProvider.notifier).setModel(_models.first);
            }
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
