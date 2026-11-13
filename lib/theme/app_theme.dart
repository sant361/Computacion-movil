import 'package:flutter/material.dart';

/// Paleta compartida por la interfaz, las portadas y el reproductor.
abstract final class AppColors {
  static const background = Color(0xFF07111F);
  static const surface = Color(0xFF142338);
  static const navigation = Color(0xFF0B1929);
  static const selectedNavigation = Color(0xFF17354A);
  static const accent = Color(0xFF35D0C4);
  static const brand = Color(0xFFFC093F);
  static const text = Color(0xFFF2F5FA);
  static const mutedText = Color(0xFFBAC5D5);
}

abstract final class AppTheme {
  static final ThemeData dark = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.brand,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.mutedText,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: WidgetStatePropertyAll(shape),
      textStyle:
          const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF465970)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: buttonStyle.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? null : AppColors.accent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? null
                : AppColors.background),
      )),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.selectedNavigation,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : AppColors.mutedText,
              fontWeight: FontWeight.w600,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : AppColors.mutedText,
            )),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.text),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF465970)),
    );
  }
}
