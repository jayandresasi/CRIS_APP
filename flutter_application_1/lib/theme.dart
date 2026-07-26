import 'package:flutter/material.dart';

class AppColors {
  // Sunset Palette
  static const Color primary = Color(0xFFEA6113);
  static const Color primaryVariant = Color(0xFFC85010);
  static const Color secondary = Color(0xFFF88F22);
  static const Color accent = Color(0xFFFBB931);
  static const Color cream = Color(0xFFFFE3B3);

  // Semantic and contrast-safe surface tokens.
  static const Color success = Color(0xFF00C48C);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF88F22);
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F7FA);
  static const Color selectionSurface = Color(0xFFFFE3B3);
  static const Color inputBorder = Color(0xFF9AA6B2);
  static const Color inputDisabled = Color(0xFFE6EBF0);
  static const Color textPrimary = Color(0xFF1B2530);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textDisabled = Color(0xFF5F6B76);
  static const Color placeholder = Color(0xFF66727F);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black87;
}

/// Shared styles for every legacy [DropdownButtonFormField].
///
/// This SDK does not expose DropdownButtonThemeData, so controls use these
/// tokens directly rather than relying on platform defaults.
class AppFormStyles {
  static const TextStyle dropdownText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
  );
  static const Color dropdownMenu = AppColors.surface;
  static const Color dropdownFocus = AppColors.selectionSurface;
  static const Color dropdownIcon = AppColors.textSecondary;
  static const Color disabledDropdownIcon = AppColors.textDisabled;
}

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      disabledColor: AppColors.textDisabled,
      // Legacy dropdown menus use Theme.focusColor for their selected row.
      focusColor: AppFormStyles.dropdownFocus,
      hoverColor: const Color(0x1FEA6113),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
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
          disabledBackgroundColor: const Color(0xFFFFD3B7),
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: const Color(0xFFFFD3B7),
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryVariant,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryVariant,
          disabledForegroundColor: AppColors.textDisabled,
        ),
      ),
      // Applies to text fields, text areas, and date/time picker fields.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        hintStyle: const TextStyle(color: AppColors.placeholder),
        helperStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        textStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled))
            return AppColors.inputBorder;
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled))
            return AppColors.textDisabled;
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary;
        }),
      ),
      // IMPORTANT: use base.textTheme.copyWith(...) here, NOT `const TextTheme(...)`.
      // Passing a brand-new TextTheme to ThemeData.copyWith() *replaces* the
      // whole text theme instead of merging with it, which silently nulls out
      // every style we don't mention here (bodyLarge, titleMedium, etc.).
      // TextField/TextFormField use exactly those null styles to color the
      // text you type, so the input text ends up with no color at all
      // (invisible) instead of falling back to something visible.
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        bodySmall:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
