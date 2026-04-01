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
