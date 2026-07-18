import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3559B7),
    brightness: Brightness.light,
    surface: const Color(0xFFFFFFFF),
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
      fontSize: 39,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 32,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.65,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 29,
      height: 1.16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.45,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 25,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 23,
      height: 1.24,
      fontWeight: FontWeight.w800,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 20,
      height: 1.28,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 18,
      height: 1.46,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 16.5,
      height: 1.44,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 15,
      height: 1.4,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 15.5,
      fontWeight: FontWeight.w700,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );

  const minimumButtonSize = Size(0, 62);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 17);
  const buttonTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    dividerColor: const Color(0xFFE3E6EF),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      backgroundColor: const Color(0xFFF7F8FC),
      foregroundColor: const Color(0xFF171A22),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: const Color(0xFF171A22),
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: const Color(0x1A1F2A44),
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE3E6EF)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 84,
      elevation: 12,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          size: states.contains(WidgetState.selected) ? 31 : 29,
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
              : FontWeight.w700,
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
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.75)),
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
        minimumSize: const Size(54, 54),
        iconSize: 29,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFDCE1EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      side: const BorderSide(color: Color(0xFFD8DDE8)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.18),
  );
}
