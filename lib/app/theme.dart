import 'package:flutter/material.dart';
import 'package:mision_admision/app/design_system.dart';

ThemeData buildLightTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppPalette.primary,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.primarySoft,
    onPrimaryContainer: AppPalette.primaryDark,
    secondary: AppPalette.teal,
    onSecondary: Colors.white,
    secondaryContainer: AppPalette.tealSoft,
    onSecondaryContainer: Color(0xFF075B54),
    tertiary: AppPalette.amber,
    onTertiary: AppPalette.ink,
    tertiaryContainer: AppPalette.amberSoft,
    onTertiaryContainer: Color(0xFF6A3D00),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppPalette.surface,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.inkMuted,
    outline: Color(0xFF85859A),
    outlineVariant: AppPalette.outline,
    shadow: Color(0xFF17162B),
    scrim: Color(0xFF17162B),
    inverseSurface: AppPalette.ink,
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFC8C1FF),
    surfaceTint: AppPalette.primary,
  );

  return _baseTheme(colorScheme);
}

ThemeData buildHighContrastLightTheme() {
  const colorScheme = ColorScheme.light(
    primary: Color(0xFF251B94),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE4E0FF),
    onPrimaryContainer: Color(0xFF120B54),
    secondary: Color(0xFF006B61),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFC8FFF5),
    onSecondaryContainer: Color(0xFF00201C),
    error: Color(0xFF93000A),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    onSurfaceVariant: Color(0xFF292839),
    outline: Color(0xFF3F3E4F),
    outlineVariant: Color(0xFF797888),
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
      height: 1.04,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.1,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 31,
      height: 1.08,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.75,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 27,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 23,
      height: 1.18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 21,
      height: 1.2,
      fontWeight: FontWeight.w800,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 16,
      height: 1.28,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 17,
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 15.5,
      height: 1.42,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 14,
      height: 1.38,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );

  const minimumButtonSize = Size(0, 56);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 15);
  const buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: AppPalette.background,
    canvasColor: AppPalette.background,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    dividerColor: AppPalette.outline,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 68,
      backgroundColor: AppPalette.background,
      foregroundColor: AppPalette.ink,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 18,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppPalette.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
        side: const BorderSide(color: AppPalette.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        side: const BorderSide(color: AppPalette.outline, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 25,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      side: const BorderSide(color: AppPalette.outline),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: AppPalette.primarySoft,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(999),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.16),
  );
}
