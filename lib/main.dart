import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/pages/pairing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: ClawChatApp()));
}

class ClawChatApp extends ConsumerWidget {
  const ClawChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Load theme on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).loadTheme();
    });

    return MaterialApp(
      title: 'claw-chat',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      home: const PairingPage(),
    );
  }
}
