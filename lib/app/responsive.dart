import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Métricas fluidas para la interfaz de Misión Admisión.
///
/// La interfaz no se adapta simulando un teléfono de ancho fijo ni mediante
/// breakpoints asociados a modelos concretos. Cada valor visual parte de una
/// proporción del área disponible y solo se limita con cotas de accesibilidad
/// para evitar controles ilegibles en ventanas muy pequeñas o exagerados en
/// escritorio.
@immutable
class AppResponsive {
  const AppResponsive._({required this.size});

  factory AppResponsive.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return AppResponsive._(size: media.size);
  }

  final Size size;

  double get width => size.width;
  double get height => size.height;

  /// Base visual proporcional. En retrato coincide con el ancho disponible;
  /// en ventanas apaisadas se limita por la altura para que la UI no crezca
  /// como si fuera una pantalla móvil extremadamente ancha.
  double get visualBasis {
    if (height >= width) return width;
    return math.min(width, height * 0.78);
  }

  double value(
    double fraction, {
    double minimum = 0,
    double maximum = double.infinity,
  }) {
    return (visualBasis * fraction).clamp(minimum, maximum).toDouble();
  }

  double widthValue(
    double fraction, {
    double minimum = 0,
    double maximum = double.infinity,
  }) {
    return (width * fraction).clamp(minimum, maximum).toDouble();
  }

  double heightValue(
    double fraction, {
    double minimum = 0,
    double maximum = double.infinity,
  }) {
    return (height * fraction).clamp(minimum, maximum).toDouble();
  }

  double font(
    double fraction, {
    required double minimum,
    double maximum = double.infinity,
  }) {
    return value(fraction, minimum: minimum, maximum: maximum);
  }

  double get pagePadding => value(0.042, minimum: 16);
  double get compactGap => value(0.022, minimum: 8);
  double get itemGap => value(0.032, minimum: 12);
  double get sectionGap => value(0.052, minimum: 20);
  double get cardPadding => value(0.046, minimum: 18);
  double get controlHeight => value(0.132, minimum: 56);
  double get optionHeight => value(0.155, minimum: 68);
  double get iconSize => value(0.058, minimum: 24);
  double get iconBadgeSize => value(0.112, minimum: 48);
  double get appBarHeight => value(0.145, minimum: 68);
  double get bottomNavigationHeight =>
      value(0.18, minimum: 84);
  double get smallRadius => value(0.027, minimum: 11);
  double get mediumRadius => value(0.042, minimum: 16);
  double get largeRadius => value(0.055, minimum: 21);
  double get heroRadius => value(0.067, minimum: 25);
  double get progressThickness => value(0.018, minimum: 7);

  EdgeInsets get pageInsets => EdgeInsets.symmetric(horizontal: pagePadding);

  EdgeInsets symmetricInsets({
    double horizontalFraction = 0.042,
    double verticalFraction = 0.028,
    double minimumHorizontal = 12,
    double maximumHorizontal = double.infinity,
    double minimumVertical = 8,
    double maximumVertical = double.infinity,
  }) {
    return EdgeInsets.symmetric(
      horizontal: value(
        horizontalFraction,
        minimum: minimumHorizontal,
        maximum: maximumHorizontal,
      ),
      vertical: value(
        verticalFraction,
        minimum: minimumVertical,
        maximum: maximumVertical,
      ),
    );
  }
}

extension AppResponsiveBuildContext on BuildContext {
  AppResponsive get responsive => AppResponsive.of(this);
}

Widget fullWidthCentered({required Widget child}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final portrait = constraints.maxHeight >= constraints.maxWidth;
      final resolvedWidth = portrait
          ? constraints.maxWidth
          : math.min(
              constraints.maxWidth * 0.88,
              constraints.maxHeight * 1.25,
            );
      return Center(
        child: SizedBox(
          width: resolvedWidth,
          height: constraints.maxHeight,
          child: child,
        ),
      );
    },
  );
}
