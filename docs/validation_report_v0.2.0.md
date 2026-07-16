# Reporte de validación — v0.2.0

## Comprobaciones ejecutadas en este entorno

- Lectura de todos los JSON.
- Validación del banco global de 20 preguntas.
- Validación del banco de retos programados.
- IDs únicos y fechas locales estrictas `YYYY-MM-DD`.
- URLs HTTPS.
- Integridad referencial entre retos y preguntas.
- Sintaxis de los workflows YAML.
- Resolución de imports internos del paquete.
- Existencia de las rutas de assets declaradas.
- Análisis sintáctico estructural de 64 archivos Dart.
- Búsqueda de marcadores de implementación incompleta y rutas absolutas locales.

Resultado del validador de contenido:

```text
Contenido válido: 20 preguntas, 1 retos programados.
```

## Comprobaciones que ejecutará GitHub Actions

Este entorno no incluye el SDK de Flutter. Al subir el proyecto, los workflows ejecutarán con Flutter 3.44.0:

```text
dart format lib test
flutter analyze --no-fatal-infos
python3 tool/validate_content.py
flutter test
flutter build web --release
```

No se afirma que `flutter analyze`, `flutter test` o `flutter build web` hayan sido ejecutados localmente.

## Contenido de demostración

`content/retos/retos_actuales.json` incluye un reto de demostración para el 15 de julio de 2026. Su enlace de resolución apunta a la página principal de YouTube y debe sustituirse por el recurso real antes de publicar a alumnos.
