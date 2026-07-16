# Reporte de validación — Misión Admisión v0.4.0

**Fecha:** 15 de julio de 2026  
**Bloque:** sincronización remota local-first.

## Resultado

Las comprobaciones disponibles en el entorno terminaron correctamente.

```text
Contenido válido: 20 preguntas, 1 retos, 6 cards activas y 6 rangos.
Structural checks passed: 98 lib Dart files, 17 test Dart files.
Test declarations: 54.
```

## Comprobaciones ejecutadas

- Decodificación de todos los archivos JSON.
- Validación cruzada de `content/index.json` y las versiones internas.
- IDs únicos y referencias válidas entre retos y preguntas.
- Validación de preguntas, cards, rangos, fechas y URLs.
- Sintaxis de workflows YAML.
- Compilación sintáctica del validador Python.
- Existencia de imports internos y assets declarados.
- Balance léxico de delimitadores en 115 archivos Dart.
- Ausencia de `TODO`, `FIXME` y rutas locales dentro del código.
- Pruebas añadidas para índice, caché, fallback y sincronización.

## Casos cubiertos por las pruebas nuevas

- Índice remoto completo y válido.
- Rechazo de rutas inseguras, archivos desconocidos y versiones inválidas.
- Descarga y activación de los cuatro documentos.
- Omisión de documentos sin cambios.
- Conservación de la copia anterior ante JSON remoto inválido.
- Fallback a assets ante caché corrupta.
- Protección de preguntas usadas por el intento vigente del día.
- Permiso para actualizar cuando el intento almacenado ya venció.
- Rechazo de bancos que rompen retos existentes.
- Persistencia de metadatos y versiones activas.

## Seguridad de activación

Los documentos se escriben primero bajo claves versionadas. Después, una sola escritura de metadatos cambia el mapa de versiones activas. Las versiones anteriores se conservan, por lo que una lectura concurrente puede seguir resolviendo la copia anterior mientras se completa la activación.

## Limitación del entorno

Este entorno no incluye el SDK completo de Flutter. Por esa razón no fue posible ejecutar localmente:

```text
flutter analyze
flutter test
flutter build web
```

El workflow de GitHub Pages incluido ejecuta `dart format`, análisis, validación de contenido, pruebas y compilación web antes de publicar. Una compilación real en GitHub Actions seguirá siendo la comprobación definitiva.
