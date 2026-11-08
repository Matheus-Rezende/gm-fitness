import 'package:flutter/material.dart';

/// Cores da marca, tiradas das anilhas olímpicas.
class GmColors {
  static const blue = Color(0xFF1F4FD8); // anilha de 20 kg
  static const blueLight = Color(0xFF7FA2FF);
  static const yellow = Color(0xFFF5B700); // anilha de 15 kg
  static const red = Color(0xFFE2382F); // anilha de 25 kg
  static const green = Color(0xFF1E9E5A); // anilha de 10 kg
  static const ink = Color(0xFF23272E);
  static const chalk = Color(0xFFEEF0F2);
  static const night = Color(0xFF14171C);

  /// Cor da anilha que representa a carga (padrão olímpico).
  static Color forLoad(double kg) {
    if (kg >= 25) return red;
    if (kg >= 20) return blue;
    if (kg >= 15) return yellow;
    if (kg >= 10) return green;
    return const Color(0xFF9AA3B2);
  }

  /// Cores que se alternam entre os dias e planos.
  static const cycle = [blue, red, yellow, green];
}

const display = 'BarlowCondensed';
const body = 'Barlow';

TextTheme _text(TextTheme base, Color ink, Color soft) {
  TextStyle? cond(TextStyle? s, double size, FontWeight w, {double ls = 0}) =>
      s?.copyWith(fontFamily: display, fontSize: size, fontWeight: w, letterSpacing: ls, height: 1.05, color: ink);
  TextStyle? reg(TextStyle? s, double size, FontWeight w, {Color? color, double height = 1.35}) =>
      s?.copyWith(fontFamily: body, fontSize: size, fontWeight: w, height: height, color: color ?? ink);
  return base.copyWith(
    displayLarge: cond(base.displayLarge, 56, FontWeight.w800, ls: -0.5),
    displayMedium: cond(base.displayMedium, 44, FontWeight.w800, ls: -0.4),
    displaySmall: cond(base.displaySmall, 36, FontWeight.w800, ls: -0.3),
    headlineLarge: cond(base.headlineLarge, 32, FontWeight.w800),
    headlineMedium: cond(base.headlineMedium, 28, FontWeight.w700),
    headlineSmall: cond(base.headlineSmall, 24, FontWeight.w700),
    titleLarge: cond(base.titleLarge, 22, FontWeight.w700),
    titleMedium: reg(base.titleMedium, 16, FontWeight.w600, height: 1.25),
    titleSmall: reg(base.titleSmall, 14.5, FontWeight.w600, height: 1.25),
    bodyLarge: reg(base.bodyLarge, 16, FontWeight.w400, height: 1.45),
    bodyMedium: reg(base.bodyMedium, 14.5, FontWeight.w400, height: 1.45),
    bodySmall: reg(base.bodySmall, 12.5, FontWeight.w400, color: soft),
    labelLarge: reg(base.labelLarge, 14, FontWeight.w600, height: 1.2),
    labelMedium: reg(base.labelMedium, 12.5, FontWeight.w600, height: 1.2),
    labelSmall: reg(base.labelSmall, 11.5, FontWeight.w600, height: 1.2),
  );
}

ThemeData buildGmTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFE9ECF1) : GmColors.ink;
  final soft = dark ? const Color(0xFFA2AAB8) : const Color(0xFF5E6675);
  final scheme = ColorScheme.fromSeed(seedColor: GmColors.blue, brightness: brightness).copyWith(
    primary: dark ? GmColors.blueLight : GmColors.blue,
    onPrimary: dark ? GmColors.night : Colors.white,
    secondary: GmColors.yellow,
    onSecondary: GmColors.ink,
    tertiary: GmColors.green,
    error: GmColors.red,
    surface: dark ? const Color(0xFF1C2027) : Colors.white,
    onSurface: ink,
    onSurfaceVariant: soft,
    surfaceContainerHighest: dark ? const Color(0xFF2A2F38) : const Color(0xFFE3E7EC),
    outlineVariant: dark ? const Color(0xFF353B46) : const Color(0xFFD6DBE2),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final text = _text(base.textTheme, ink, soft);
  final radius12 = BorderRadius.circular(12);

  return base.copyWith(
    scaffoldBackgroundColor: dark ? GmColors.night : GmColors.chalk,
    textTheme: text,
    appBarTheme: AppBarThemeData(
      backgroundColor: dark ? GmColors.night : GmColors.chalk,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: GmColors.yellow,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? ink : soft,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? GmColors.ink : soft,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: text.labelLarge?.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: text.labelMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: GmColors.yellow,
      foregroundColor: GmColors.ink,
      extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: radius12, borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: GmColors.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
