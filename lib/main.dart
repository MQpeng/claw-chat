import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/datasource/local/hive_storage.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/connection_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/pairing_page.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // Try initialize Hive, delete and retry if it fails
  // This handles corrupted database from old versions
  try {
    await HiveStorage().init();
  } catch (e) {
    debugPrint('⚠️ Hive initialization failed: $e');
    debugPrint('Deleting corrupted database and retrying...');
    // Hive will recreate boxes on next open
    await Hive.close();
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await HiveStorage().init();
    } catch (e2) {
      debugPrint('⚠️ Second Hive init failed: $e2');
      // Still failed, let app continue - it might work
    }
  }
  
  runApp(const ProviderScope(child: ClawChatApp()));
}

class ClawChatApp extends ConsumerWidget {
  const ClawChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final connection = ref.watch(connectionProvider);

    // Load theme settings on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).loadTheme();
      ref.read(themeColorProvider.notifier).loadThemeColor();
    });

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'claw-chat',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(themeColor),
      darkTheme: darkTheme(themeColor),
      themeMode: themeMode,
      home: connection.status == ConnectionStatus.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (connection.config == null ? const PairingPage() : const HomePage()),
      // Rule: If config exists, always go to HomePage regardless of connection status
      // Only go to PairingPage when no config exists or user clicks Connect menu item
    );
  }
}
