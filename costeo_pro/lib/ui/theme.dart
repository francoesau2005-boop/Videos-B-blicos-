import 'package:flutter/material.dart';

/// Paleta de Costeo Pro.
class AppColors {
  static const emerald = Color(0xFF2FD3A0);
  static const emeraldDark = Color(0xFF0E9F74);
  static const gold = Color(0xFFF2B84B);
  static const danger = Color(0xFFFF6B6B);
  static const info = Color(0xFF5AA9FF);
  static const violet = Color(0xFFA78BFA);

  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF151B23);
  static const darkCard = Color(0xFF1B222C);
  static const darkLine = Color(0xFF2A3340);

  static const lightBg = Color(0xFFF4F6F8);
  static const lightCard = Colors.white;

  /// Colores para gráficos (series).
  static const chart = [
    Color(0xFF2FD3A0),
    Color(0xFF5AA9FF),
    Color(0xFFF2B84B),
    Color(0xFFA78BFA),
    Color(0xFFFF8A65),
    Color(0xFF4DD0E1),
    Color(0xFFF06292),
    Color(0xFF9CCC65),
  ];
}

/// Colores semánticos accesibles desde el contexto.
extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get positive => isDark ? AppColors.emerald : AppColors.emeraldDark;
  Color get negative => AppColors.danger;
  Color get warning => isDark ? AppColors.gold : const Color(0xFFB7791F);
  Color get muted => cs.onSurfaceVariant;
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: AppColors.emerald, brightness: b);
  final cs = base.copyWith(
    primary: dark ? AppColors.emerald : AppColors.emeraldDark,
    onPrimary: dark ? const Color(0xFF00281B) : Colors.white,
    secondary: AppColors.gold,
    surface: dark ? AppColors.darkSurface : AppColors.lightCard,
    surfaceContainerLowest: dark ? AppColors.darkBg : AppColors.lightBg,
    surfaceContainerLow: dark ? AppColors.darkCard : Colors.white,
    surfaceContainer: dark ? AppColors.darkCard : const Color(0xFFF0F2F5),
    surfaceContainerHigh: dark ? const Color(0xFF222B36) : const Color(0xFFE9ECF0),
    surfaceContainerHighest: dark ? const Color(0xFF29333F) : const Color(0xFFE2E6EB),
    outlineVariant: dark ? AppColors.darkLine : const Color(0xFFDDE2E8),
    error: AppColors.danger,
  );
  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: cs,
    brightness: b,
    scaffoldBackgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.darkBg : AppColors.lightBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: cs.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: dark ? 0.6 : 1)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? AppColors.darkSurface : Colors.white,
      indicatorColor: cs.primary.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant,
          )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF111820) : const Color(0xFFF6F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.outlineVariant),
        textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 15),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: cs.outlineVariant),
      labelStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 10,
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? AppColors.darkSurface : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
