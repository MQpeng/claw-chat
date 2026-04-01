import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
final themeColorProvider = NotifierProvider<ThemeColorNotifier, AppThemeColor>(ThemeColorNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) {
      state = ThemeMode.system;
      return;
    }
    state = ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}

class ThemeColorNotifier extends Notifier<AppThemeColor> {
  static const _key = 'theme_color';

  @override
  AppThemeColor build() {
    return AppThemeColor.openclawRed;
  }

  Future<void> loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    state = AppThemeColor.fromName(value);
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, color.name);
    state = color;
  }
}
