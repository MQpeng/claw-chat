import 'package:flutter/material.dart';

enum AppThemeColor {
  openclawRed('OpenClaw Red', Color(0xFFdd2d2d), Color(0xFFe55555)),
  blue('Blue', Color(0xFF2196F3), Color(0xFF64B5F6)),
  green('Green', Color(0xFF4CAF50), Color(0xFF81C784)),
  purple('Purple', Color(0xFF9C27B0), Color(0xFFBA68C8)),
  orange('Orange', Color(0xFFFF9800), Color(0xFFFFB74D));

  const AppThemeColor(this.name, this.primary, this.primaryLight);
  final String name;
  final Color primary;
  final Color primaryLight;

  static AppThemeColor fromName(String? name) {
    if (name == null) return AppThemeColor.openclawRed;
    return AppThemeColor.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeColor.openclawRed,
    );
  }
}

ThemeData lightTheme(AppThemeColor themeColor) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: themeColor.primary,
      brightness: Brightness.light,
      primary: themeColor.primary,
      secondary: themeColor.primaryLight,
      background: const Color(0xFFF5F7FA),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: themeColor.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

ThemeData darkTheme(AppThemeColor themeColor) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: themeColor.primary,
      brightness: Brightness.dark,
      primary: themeColor.primaryLight,
      secondary: themeColor.primary,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.transparent,
      surfaceTintColor: Color(0xFF1A1A1A),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 1,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: themeColor.primaryLight,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor.primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
