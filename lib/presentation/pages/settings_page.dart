import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/datasource/local/hive_storage.dart';
import '../providers/theme_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';
import '../../../core/providers/model_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final defaultModel = ref.watch(modelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
                    title: Text(l10n.themeMode),
                    subtitle: Text(_themeModeToString(themeMode, l10n)),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      onChanged: (newMode) {
                        if (newMode != null) {
                          ref.read(themeProvider.notifier).setTheme(newMode);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(l10n.themeSystem),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(l10n.themeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l10n.themeDark),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.themeColor),
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
                    title: Text(l10n.defaultModel),
                    subtitle: Text(defaultModel.isEmpty ? l10n.serverDefault : defaultModel),
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
                    title: Text(
                      l10n.clearAllSessions,
                      style: const TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(l10n.deleteAllSessionsAndMessages),
                    onTap: () => _clearAllData(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.reconnectToOpenClaw),
                    subtitle: Text(l10n.disconnectAndReconnect),
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
                   AboutListTile(
                    applicationName: l10n.appName,
                    applicationLegalese: 'MIT License',
                    aboutBoxChildren: [
                      const SizedBox(height: 8),
                      Text(
                        l10n.aboutText,
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
                           Text(l10n.version),
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

  String _themeModeToString(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  void _showModelSelection(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final connection = ref.watch(connectionProvider);
    if (!connection.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.notConnectedToOpenClaw)),
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(
          l10n.clearAllDataConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear, style: const TextStyle(color: Colors.red)),
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
         SnackBar(content: Text(l10n.allDataCleared)),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadModels}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentModel = ref.watch(modelProvider);
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
