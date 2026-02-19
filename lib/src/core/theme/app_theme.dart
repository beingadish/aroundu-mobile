import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color primary = Color(0xFF0476FF);
  static const Color background = Color(0xFFF6F9FF);
  static const Color backgroundDark = Color(0xFF0E1218);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF171D26);
  static const Color textPrimary = Color(0xFF1B1E2B);
  static const Color textPrimaryDark = Color(0xFFF3F6FC);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFFA7B0BF);
  static const Color border = Color(0xFFDEE3EE);
  static const Color borderDark = Color(0xFF2A3341);
  static const Color success = Color(0xFF2EAE63);
  static const Color warning = Color(0xFFE49B12);
  static const Color danger = Color(0xFFD64545);
}

ThemeData buildAroundUTheme() {
  return _buildTheme(brightness: Brightness.light);
}

ThemeData buildAroundUDarkTheme() {
  return _buildTheme(brightness: Brightness.dark);
}

ThemeData _buildTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final background = isDark ? AppPalette.backgroundDark : AppPalette.background;
  final surface = isDark ? AppPalette.surfaceDark : AppPalette.surface;
  final textPrimary = isDark
      ? AppPalette.textPrimaryDark
      : AppPalette.textPrimary;
  final textSecondary = isDark
      ? AppPalette.textSecondaryDark
      : AppPalette.textSecondary;
  final border = isDark ? AppPalette.borderDark : AppPalette.border;
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      primary: AppPalette.primary,
      surface: surface,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: background,
    textTheme: textTheme.copyWith(
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  );
}
