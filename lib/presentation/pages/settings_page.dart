import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasource/local/hive_storage.dart';
import '../providers/theme_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
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
              items: [
                const DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                const DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                const DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear All Sessions'),
            subtitle: const Text('Delete all sessions and messages'),
            onTap: () => _clearAllData(context, ref),
            textColor: Colors.red,
          ),
          const Divider(),
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
          const Divider(),
          const AboutListTile(
            applicationName: 'claw-chat',
            aboutBoxChildren: [
              Text('Lightweight Flutter mobile client for OpenClaw'),
            ],
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
        content: const Text('This will delete all sessions and messages. This action cannot be undone.'),
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
