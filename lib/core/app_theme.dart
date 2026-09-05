import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF030B18);
  static const surface = Color(0xFF08182C);
  static const surfaceRaised = Color(0xFF102744);
  static const border = Color(0xFF244A73);
  static const textMuted = Color(0xFF91A9C3);
  static const green = Color(0xFF16D9A0);
  static const cyan = Color(0xFF18C7E8);
  static const orange = Color(0xFFFF8B3D);
  static const red = Color(0xFFFF4D6D);

  static Color primary = const Color(0xFF2F8CFF);
  static Color primaryLight = const Color(0xFF5DBBFF);
  static Color primaryDark = const Color(0xFF1554D1);
  static Color appSecondary = const Color(0xFF16D9A0);
  static Color appBackground = background;
  static Color appSurface = surface;
  static Color appSurfaceRaised = surfaceRaised;
  static Color appBorder = border;
  static Color appSidebar = const Color(0xFF091326);

  static Color get blue => primary;
  static Color get appGlow =>
      Color.lerp(appBackground, primaryDark, .56) ?? primaryDark;

  static void applyAccent(AppAccentPalette palette) {
    primary = palette.primary;
    primaryLight = palette.light;
    primaryDark = palette.dark;
  }

  static void applyProfile(AppVisualProfile profile) {
    primary = profile.primary;
    primaryLight = profile.primaryLight;
    primaryDark = profile.primaryDark;
    appSecondary = profile.secondary;
    appBackground = profile.background;
    appSurface = profile.surface;
    appSurfaceRaised = profile.surfaceRaised;
    appBorder = profile.border;
    appSidebar = profile.sidebar;
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

class AppVisualProfile {
  const AppVisualProfile({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.sidebar,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color sidebar;

  factory AppVisualProfile.fromPreset(AppAccentPalette palette) {
    return switch (palette) {
      AppAccentPalette.blue => const AppVisualProfile(
          primary: Color(0xFF2F8CFF),
          primaryLight: Color(0xFF5DBBFF),
          primaryDark: Color(0xFF1554D1),
          secondary: Color(0xFF16D9A0),
          background: Color(0xFF030B18),
          surface: Color(0xFF08182C),
          surfaceRaised: Color(0xFF102744),
          border: Color(0xFF244A73),
          sidebar: Color(0xFF091326),
        ),
      AppAccentPalette.purple => const AppVisualProfile(
          primary: Color(0xFF8B5CF6),
          primaryLight: Color(0xFFC084FC),
          primaryDark: Color(0xFF5B21B6),
          secondary: Color(0xFF2DD4BF),
          background: Color(0xFF0A0615),
          surface: Color(0xFF171027),
          surfaceRaised: Color(0xFF281B42),
          border: Color(0xFF5A3E82),
          sidebar: Color(0xFF10091F),
        ),
      AppAccentPalette.gray => const AppVisualProfile(
          primary: Color(0xFF94A3B8),
          primaryLight: Color(0xFFCBD5E1),
          primaryDark: Color(0xFF475569),
          secondary: Color(0xFF38BDF8),
          background: Color(0xFF090B0F),
          surface: Color(0xFF151920),
          surfaceRaised: Color(0xFF252B34),
          border: Color(0xFF46505D),
          sidebar: Color(0xFF101318),
        ),
      AppAccentPalette.green => const AppVisualProfile(
          primary: Color(0xFF10B981),
          primaryLight: Color(0xFF5EEAD4),
          primaryDark: Color(0xFF047857),
          secondary: Color(0xFF38BDF8),
          background: Color(0xFF03100E),
          surface: Color(0xFF09211D),
          surfaceRaised: Color(0xFF123B34),
          border: Color(0xFF24675A),
          sidebar: Color(0xFF061A17),
        ),
      AppAccentPalette.yellow => const AppVisualProfile(
          primary: Color(0xFFF59E0B),
          primaryLight: Color(0xFFFCD34D),
          primaryDark: Color(0xFFB45309),
          secondary: Color(0xFF2DD4BF),
          background: Color(0xFF100C03),
          surface: Color(0xFF211807),
          surfaceRaised: Color(0xFF3A2A0D),
          border: Color(0xFF70511B),
          sidebar: Color(0xFF1A1205),
        ),
      AppAccentPalette.colorful => const AppVisualProfile(
          primary: Color(0xFFEC4899),
          primaryLight: Color(0xFF22D3EE),
          primaryDark: Color(0xFF7C3AED),
          secondary: Color(0xFFF59E0B),
          background: Color(0xFF090617),
          surface: Color(0xFF17112D),
          surfaceRaised: Color(0xFF2A1D4B),
          border: Color(0xFF563D87),
          sidebar: Color(0xFF100A25),
        ),
    };
  }

  AppVisualProfile copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? sidebar,
  }) {
    final nextPrimary = primary ?? this.primary;
    return AppVisualProfile(
      primary: nextPrimary,
      primaryLight: primaryLight ??
          (primary == null
              ? this.primaryLight
              : Color.lerp(nextPrimary, Colors.white, .28)!),
      primaryDark: primaryDark ??
          (primary == null
              ? this.primaryDark
              : Color.lerp(nextPrimary, Colors.black, .28)!),
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      sidebar: sidebar ?? this.sidebar,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        'primary': primary.toARGB32(),
        'primaryLight': primaryLight.toARGB32(),
        'primaryDark': primaryDark.toARGB32(),
        'secondary': secondary.toARGB32(),
        'background': background.toARGB32(),
        'surface': surface.toARGB32(),
        'surfaceRaised': surfaceRaised.toARGB32(),
        'border': border.toARGB32(),
        'sidebar': sidebar.toARGB32(),
      };

  factory AppVisualProfile.fromJson(Map<String, dynamic> json) {
    final fallback = AppVisualProfile.fromPreset(AppAccentPalette.blue);
    Color read(String key, Color value) {
      final raw = json[key];
      return raw is num ? Color(raw.toInt()) : value;
    }

    return AppVisualProfile(
      primary: read('primary', fallback.primary),
      primaryLight: read('primaryLight', fallback.primaryLight),
      primaryDark: read('primaryDark', fallback.primaryDark),
      secondary: read('secondary', fallback.secondary),
      background: read('background', fallback.background),
      surface: read('surface', fallback.surface),
      surfaceRaised: read('surfaceRaised', fallback.surfaceRaised),
      border: read('border', fallback.border),
      sidebar: read('sidebar', fallback.sidebar),
    );
  }
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.appSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.appSecondary,
        surface: AppColors.appSurface,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.appBackground,
      canvasColor: AppColors.appBackground,
      cardColor: AppColors.appSurface,
      dividerColor: AppColors.appBorder.withValues(alpha: .7),
      fontFamily: 'Segoe UI',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.appSidebar,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.appSurfaceRaised,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.appBorder),
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
          side: BorderSide(color: AppColors.appBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.appSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.appSurfaceRaised,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
