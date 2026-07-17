import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF155EEF),
    brightness: Brightness.light,
  );

  return _baseTheme(colorScheme);
}

ThemeData buildHighContrastLightTheme() {
  const colorScheme = ColorScheme.light(
    primary: Color(0xFF003C9E),
    onPrimary: Colors.white,
    secondary: Color(0xFF004A77),
    onSecondary: Colors.white,
    error: Color(0xFF9B0000),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF101010),
  );
  return _baseTheme(colorScheme).copyWith(
    scaffoldBackgroundColor: Colors.white,
    dividerColor: const Color(0xFF3D3D3D),
  );
}

ThemeData _baseTheme(ColorScheme colorScheme) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
  final baseTextTheme = baseTheme.textTheme;
  final textTheme = baseTextTheme.copyWith(
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontSize: 36,
      height: 1.12,
      fontWeight: FontWeight.w800,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 32,
      height: 1.16,
      fontWeight: FontWeight.w800,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w800,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 24,
      height: 1.24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 19,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 17,
      height: 1.5,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 16,
      height: 1.48,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 14.5,
      height: 1.45,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  const minimumButtonSize = Size(0, 54);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  const buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      backgroundColor: const Color(0xFFF5F7FB),
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        iconSize: 26,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: textTheme.bodyMedium,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.18),
  );
}
