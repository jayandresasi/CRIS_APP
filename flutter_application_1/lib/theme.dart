import 'package:flutter/material.dart';

class AppColors {
  // Sunset Palette
  static const Color primary = Color(0xFFEA6113); // deep orange-red
  static const Color primaryVariant = Color(0xFFC85010); // darker orange
  static const Color secondary = Color(0xFFF88F22); // orange
  static const Color accent = Color(0xFFFBB931); // golden yellow
  static const Color cream = Color(0xFFFFE3B3); // lightest cream

  // Semantic
  static const Color success = Color(0xFF00C48C);
  static const Color danger = Color(0xFFEA6113);
  static const Color warning = Color(0xFFF88F22);
  static const Color background = Color(0xFFFFF8F0); // warm cream background
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
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        // These two fix invisible text inside text fields
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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