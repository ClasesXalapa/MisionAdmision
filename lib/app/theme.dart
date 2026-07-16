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
  const minimumButtonSize = Size(0, 48);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minimumButtonSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minimumButtonSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: minimumButtonSize),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.18),
  );
}
