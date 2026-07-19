import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reglas visuales de Misión Admisión.
///
/// Algunos WebView/PWA Android entregan a Flutter el ancho físico del teléfono
/// (por ejemplo 720 px) como si fuera ancho lógico. En ese escenario una UI
/// diseñada para 390–430 px se comprime visualmente y todo parece demasiado
/// pequeño, aunque los `fontSize` sean correctos.
///
/// [HandsetViewport] normaliza únicamente esos viewports altos y anchos a una
/// superficie lógica de teléfono. De esta forma se escalan juntos texto,
/// iconos, espacios y áreas táctiles; no se intenta compensar solo la fuente.
const double _phoneDesignWidth = 430;
const double _widePhoneThreshold = 560;
const double _maximumNormalizedPhoneWidth = 1000;
const double _minimumPhoneAspectRatio = 1.65;

bool isHandsetLayout(BuildContext context) {
  final media = MediaQuery.of(context);
  final platform = defaultTargetPlatform;
  final mobilePlatform = platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;

  return mobilePlatform || media.size.shortestSide < 760;
}

bool shouldNormalizeHandsetViewport(BuildContext context) {
  final media = MediaQuery.of(context);
  if (!isHandsetLayout(context) || media.size.height <= 0) return false;

  final width = media.size.width;
  final aspectRatio = media.size.height / width;
  return width >= _widePhoneThreshold &&
      width <= _maximumNormalizedPhoneWidth &&
      aspectRatio >= _minimumPhoneAspectRatio;
}

double appHorizontalPadding(BuildContext context) {
  return isHandsetLayout(context) ? 16 : 28;
}

/// Conserva la preferencia de accesibilidad del usuario.
///
/// La compensación por viewports Android anchos ya la realiza
/// [HandsetViewport], por lo que no se vuelve a multiplicar la tipografía.
double resolvedTextScale(BuildContext context) {
  final media = MediaQuery.of(context);
  final current = media.textScaler.scale(16) / 16;
  if (!isHandsetLayout(context)) return current;
  return math.max(current, 1.04);
}

class HandsetViewport extends StatelessWidget {
  const HandsetViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = resolvedTextScale(context);

    if (!shouldNormalizeHandsetViewport(context)) {
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(textScale)),
        child: child,
      );
    }

    final scale = media.size.width / _phoneDesignWidth;
    final normalizedHeight = media.size.height / scale;
    final normalizedMedia = media.copyWith(
      size: Size(_phoneDesignWidth, normalizedHeight),
      padding: _scaledInsets(media.padding, scale),
      viewPadding: _scaledInsets(media.viewPadding, scale),
      viewInsets: _scaledInsets(media.viewInsets, scale),
      systemGestureInsets: _scaledInsets(media.systemGestureInsets, scale),
      textScaler: TextScaler.linear(textScale),
    );

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _phoneDesignWidth,
          height: normalizedHeight,
          child: MediaQuery(
            data: normalizedMedia,
            child: child,
          ),
        ),
      ),
    );
  }
}

EdgeInsets _scaledInsets(EdgeInsets value, double scale) {
  return EdgeInsets.fromLTRB(
    value.left / scale,
    value.top / scale,
    value.right / scale,
    value.bottom / scale,
  );
}

Widget fullWidthCentered({
  required Widget child,
  double maxWidth = 920,
}) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: child,
      ),
    ),
  );
}
