# Reporte de validación — Misión Admisión v0.5.0

**Fecha:** 15 de julio de 2026  
**Bloque:** PWA instalable y modo offline controlado.

## Resultado

Las comprobaciones disponibles en el entorno terminaron correctamente.

```text
Contenido válido: 20 preguntas, 1 reto, 6 cards activas y 6 rangos.
Structural checks passed: 104 lib Dart files, 18 test Dart files.
Test declarations: 57.
Python tool tests: 2 passed.
JavaScript syntax: 2 source files and generated service worker passed.
```

## Comprobaciones ejecutadas

- Decodificación de los 11 archivos JSON.
- Validación cruzada del contenido y sus versiones.
- Sintaxis de los workflows YAML.
- Sintaxis JavaScript de `pwa_bridge.js` y la plantilla del service worker.
- Generación de un service worker completo desde una compilación simulada.
- Verificación de eliminación de todos los marcadores de plantilla.
- Verificación de `.nojekyll` y `pwa_build.json`.
- Pruebas Python del generador PWA.
- Existencia de imports internos de Dart.
- Balance léxico de delimitadores en producción y pruebas.
- Ausencia de `TODO`, `FIXME`, bytecode Python y rutas temporales.
- Consistencia de la versión `0.5.0+5` y el build interno 5.

## Casos cubiertos por las pruebas nuevas

- Lectura del estado PWA.
- Estado offline con service worker activo.
- Solicitud de instalación solo cuando existe prompt.
- Activación de una actualización en espera.
- Creación de listas separadas para app shell y contenido.
- Generación determinista de una versión de caché.
- Rechazo de una carpeta de build incompleta.

## Estrategia comprobada

```text
Build Flutter
→ copia de content/
→ cálculo de hash
→ generación de app_service_worker.js
→ validación con Node
→ artefacto GitHub Pages
```

La plantilla sin preparar no se registra durante desarrollo. En producción, el puente comprueba que el service worker ya tenga listas de caché inyectadas antes del primer registro.

## Limitación del entorno

Este entorno no incluye el SDK completo de Flutter. Por esa razón no fue posible ejecutar localmente:

```text
flutter analyze
flutter test
flutter build web
```

El workflow incluido ejecuta formato, análisis, pruebas, build web, preparación del service worker y validación JavaScript antes de publicar. Esa compilación real en GitHub Actions sigue siendo la comprobación definitiva.
