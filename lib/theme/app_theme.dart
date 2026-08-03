import 'package:flutter/material.dart';

class AppTheme {
  static TextStyle? _beaufortBold(TextStyle? style) {
    if (style == null) {
      return null;
    }

    return style.copyWith(
      fontFamily: 'BeaufortforLOL',
      fontWeight: FontWeight.w900,
    );
  }

  static TextTheme _buildTextTheme(TextTheme baseTextTheme) {
    return baseTextTheme.copyWith(
      displayLarge: _beaufortBold(baseTextTheme.displayLarge),
      displayMedium: _beaufortBold(baseTextTheme.displayMedium),
      displaySmall: _beaufortBold(baseTextTheme.displaySmall),
      headlineLarge: _beaufortBold(baseTextTheme.headlineLarge),
      headlineMedium: _beaufortBold(baseTextTheme.headlineMedium),
      headlineSmall: _beaufortBold(baseTextTheme.headlineSmall),
      titleLarge: _beaufortBold(baseTextTheme.titleLarge),
      titleMedium: _beaufortBold(baseTextTheme.titleMedium),
      titleSmall: _beaufortBold(baseTextTheme.titleSmall),
      bodyLarge: _beaufortBold(baseTextTheme.bodyLarge),
      bodyMedium: _beaufortBold(baseTextTheme.bodyMedium),
      bodySmall: _beaufortBold(baseTextTheme.bodySmall),
      labelLarge: _beaufortBold(baseTextTheme.labelLarge),
      labelMedium: _beaufortBold(baseTextTheme.labelMedium),
      labelSmall: _beaufortBold(baseTextTheme.labelSmall),
    );
  }

  static ThemeData buildTheme() {
    const baseBlue = Color(0xFF0A1D34);
    const surfaceBlue = Color(0xFF102744);
    const accentGold = Color(0xFFC89B3C);

    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: baseBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accentGold,
          secondary: accentGold,
          tertiary: const Color(0xFFE7C870),
          surface: surfaceBlue,
          surfaceContainerHighest: const Color(0xFF17365C),
          onPrimary: const Color(0xFF2A1700),
          onSurface: const Color(0xFFF0F5FF),
          onSurfaceVariant: const Color(0xFFAFC3DD),
        );

    final textTheme = _buildTextTheme(
      base.textTheme.apply(
        bodyColor: const Color(0xFFF0F5FF),
        displayColor: const Color(0xFFF0F5FF),
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'BeaufortforLOL',
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF071326),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF102744),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: const Color(0xFF17365C),
      ),
    );
  }
}
