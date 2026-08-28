import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF030B18);
  static const surface = Color(0xFF08182C);
  static const surfaceRaised = Color(0xFF102744);
  static const border = Color(0xFF244A73);
  static const textMuted = Color(0xFF91A9C3);
  static const green = Color(0xFF16D9A0);
  static Color primary = const Color(0xFF2F8CFF);
  static Color primaryLight = const Color(0xFF5DBBFF);
  static Color primaryDark = const Color(0xFF1554D1);
  static const cyan = Color(0xFF18C7E8);
  static const orange = Color(0xFFFF8B3D);
  static const red = Color(0xFFFF4D6D);
  static Color get blue => primary;

  static void applyAccent(AppAccentPalette palette) {
    primary = palette.primary;
    primaryLight = palette.light;
    primaryDark = palette.dark;
  }
}

enum AppAccentPalette {
  blue(
    label: 'Azul',
    primary: Color(0xFF2F8CFF),
    light: Color(0xFF5DBBFF),
    dark: Color(0xFF1554D1),
  ),
  purple(
    label: 'Roxo',
    primary: Color(0xFF8B5CF6),
    light: Color(0xFFC084FC),
    dark: Color(0xFF5B21B6),
  ),
  gray(
    label: 'Cinza',
    primary: Color(0xFF94A3B8),
    light: Color(0xFFCBD5E1),
    dark: Color(0xFF475569),
  ),
  green(
    label: 'Verde',
    primary: Color(0xFF10B981),
    light: Color(0xFF5EEAD4),
    dark: Color(0xFF047857),
  ),
  yellow(
    label: 'Amarelo',
    primary: Color(0xFFF59E0B),
    light: Color(0xFFFCD34D),
    dark: Color(0xFFB45309),
  ),
  colorful(
    label: 'Colorido',
    primary: Color(0xFFEC4899),
    light: Color(0xFF22D3EE),
    dark: Color(0xFF7C3AED),
  );

  const AppAccentPalette({
    required this.label,
    required this.primary,
    required this.light,
    required this.dark,
  });

  final String label;
  final Color primary;
  final Color light;
  final Color dark;
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border.withValues(alpha: .7),
      fontFamily: 'Segoe UI',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
