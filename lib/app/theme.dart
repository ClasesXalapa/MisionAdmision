import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF315AC7),
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
      letterSpacing: -0.8,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 30,
      height: 1.16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 27,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.35,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 23,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 21,
      height: 1.28,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 18,
      height: 1.32,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 16,
      height: 1.34,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 16.5,
      height: 1.48,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 15.5,
      height: 1.46,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 14,
      height: 1.42,
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

  const minimumButtonSize = Size(0, 56);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 15);
  const buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    dividerColor: const Color(0xFFD8DDEA),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 62,
      backgroundColor: const Color(0xFFF4F6FB),
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFDDE2EE)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 10,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          size: states.contains(WidgetState.selected) ? 28 : 26,
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return textTheme.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        elevation: 0,
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
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.8)),
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
        minimumSize: const Size(48, 48),
        iconSize: 26,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6DCE9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      side: const BorderSide(color: Color(0xFFD2D8E5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.18),
  );
}
