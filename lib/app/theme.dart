import 'package:flutter/material.dart';
import 'package:mision_admision/app/design_system.dart';
import 'package:mision_admision/app/responsive.dart';

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
      fontSize: 42,
      height: 1.04,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.1,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 36,
      height: 1.08,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.75,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 32,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: 27,
      height: 1.18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w800,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: 18,
      height: 1.28,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 19,
      height: 1.43,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 17.5,
      height: 1.42,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 15.5,
      height: 1.38,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );

  const minimumButtonSize = Size(0, 66);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 19);
  const buttonTextStyle = TextStyle(
    fontSize: 18,
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
      toolbarHeight: 78,
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
        minimumSize: const Size(56, 56),
        iconSize: 29,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
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
      linearMinHeight: 10,
      borderRadius: BorderRadius.circular(999),
    ),
    focusColor: colorScheme.primary.withValues(alpha: 0.16),
  );
}


/// Aplica el sistema fluido después de que MaterialApp conoce el tamaño real
/// del viewport. Las proporciones se calculan en cada reconstrucción, por lo
/// que rotación, pantalla dividida y distintos celulares reciben geometría
/// adecuada sin simular un ancho de dispositivo concreto.
ThemeData buildResponsiveTheme(BuildContext context, ThemeData baseTheme) {
  final responsive = context.responsive;
  final baseTextTheme = baseTheme.textTheme;
  final textTheme = baseTextTheme.copyWith(
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontSize: responsive.font(0.075, minimum: 34),
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: responsive.font(0.065, minimum: 30),
      height: 1.08,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.6,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: responsive.font(0.057, minimum: 27),
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.35,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: responsive.font(0.050, minimum: 24),
      height: 1.18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: responsive.font(0.043, minimum: 21),
      height: 1.22,
      fontWeight: FontWeight.w800,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: responsive.font(0.037, minimum: 18),
      height: 1.27,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: responsive.font(0.033, minimum: 16.5),
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: responsive.font(0.034, minimum: 17),
      height: 1.46,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: responsive.font(0.031, minimum: 16),
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: responsive.font(0.027, minimum: 14),
      height: 1.42,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: responsive.font(0.032, minimum: 16.5),
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: responsive.font(0.028, minimum: 14.5),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: responsive.font(0.024, minimum: 12.5),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
    ),
  );

  final buttonPadding = responsive.symmetricInsets(
    horizontalFraction: 0.045,
    verticalFraction: 0.03,
    minimumHorizontal: 18,
    minimumVertical: 13,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(responsive.mediumRadius),
  );
  final buttonTextStyle = textTheme.labelLarge;
  final minimumButtonSize = Size(0, responsive.controlHeight);

  return baseTheme.copyWith(
    textTheme: textTheme,
    appBarTheme: baseTheme.appBarTheme.copyWith(
      toolbarHeight: responsive.appBarHeight,
      titleSpacing: responsive.pagePadding,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: baseTheme.colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.largeRadius),
        side: const BorderSide(color: AppPalette.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        elevation: 0,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        side: const BorderSide(color: AppPalette.outline, width: 1.2),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minimumButtonSize,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: Size.square(responsive.controlHeight * 0.82),
        iconSize: responsive.iconSize,
      ),
    ),
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      contentPadding: responsive.symmetricInsets(
        horizontalFraction: 0.04,
        verticalFraction: 0.033,
        minimumHorizontal: 16,
        minimumVertical: 14,
      ),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: baseTheme.colorScheme.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.mediumRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.mediumRadius),
        borderSide: const BorderSide(color: AppPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.mediumRadius),
        borderSide: BorderSide(color: baseTheme.colorScheme.primary, width: 2),
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      labelStyle: textTheme.labelMedium,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(0.024, minimum: 9),
        vertical: responsive.value(0.016, minimum: 6),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.largeRadius),
      ),
    ),
    progressIndicatorTheme: baseTheme.progressIndicatorTheme.copyWith(
      linearMinHeight: responsive.progressThickness,
      borderRadius: BorderRadius.circular(responsive.largeRadius),
    ),
    bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(responsive.heroRadius),
        ),
      ),
    ),
  );
}
