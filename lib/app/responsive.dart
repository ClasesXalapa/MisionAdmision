import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reglas visuales de la aplicación.
///
/// Algunos navegadores Android reportan un ancho lógico cercano al ancho
/// físico de la pantalla. Por eso no basta con usar un breakpoint de 600 px:
/// un teléfono puede terminar recibiendo una composición de tableta o
/// escritorio. La plataforma y el lado corto se usan como señales adicionales.
bool isHandsetLayout(BuildContext context) {
  final media = MediaQuery.of(context);
  final platform = defaultTargetPlatform;
  final mobilePlatform = platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;

  return mobilePlatform || media.size.shortestSide < 760;
}

double appHorizontalPadding(BuildContext context) {
  return isHandsetLayout(context) ? 22 : 30;
}

/// Asegura una escala legible en teléfonos sin reducir la preferencia de
/// accesibilidad elegida por el usuario.
double resolvedTextScale(BuildContext context) {
  final media = MediaQuery.of(context);
  final current = media.textScaler.scale(16) / 16;

  if (!isHandsetLayout(context)) return current;

  // En algunos WebView/PWA Android el ancho lógico reportado es 600–800 px,
  // aunque la pantalla sea un teléfono. En ese caso el texto necesita una
  // compensación mayor para conservar una escala visual nativa.
  final target = media.size.width >= 600 ? 1.24 : 1.08;
  return math.max(current, target);
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
