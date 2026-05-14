import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF008080);
  static const Color primaryVariant = Color(0xFF006969);
  static const Color secondary = Color(0xFF5BC0EB);
  static const Color accent = Color(0xFF00A3D9);
  static const Color success = Color(0xFF00E68A);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color warning = Color(0xFFFF9800);
  static const Color background = Color(0xFFF7F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black87;
}

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        // These two fix invisible text inside text fields
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      // Global input field text styling — fixes invisible typed text everywhere
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCDD5DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
        bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
