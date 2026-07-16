# Reporte de validación — Misión Admisión v0.6.0

**Fecha:** 15 de julio de 2026

## Resultado

La versión 0.6.0 integra el cliente Web Push mediante Firebase Cloud Messaging de forma opcional y conserva el service worker de caché offline como único worker del alcance de la PWA.

## Comprobaciones ejecutadas

### Contenido

```text
20 preguntas válidas
1 reto programado válido
6 cards activas válidas
6 rangos válidos
```

Se verificaron IDs, opciones, respuestas, fechas, URLs HTTPS, referencias entre retos y preguntas, versiones e índice de contenido.

### JavaScript y PWA

- Sintaxis válida de `firebase_config.js`.
- Configuración Firebase desactivada aceptada como estado válido.
- Sintaxis válida de `notifications_bridge.js`.
- Prueba automatizada del puente en modo desactivado.
- Sintaxis válida de `pwa_bridge.js`.
- Sintaxis válida de la plantilla `app_service_worker.js`.
- Dos pruebas Python aprobadas para `prepare_pwa.py`.
- Generación de service worker versionado comprobada con archivos de notificaciones incluidos.

### Estructura

- Workflows YAML válidos.
- Archivos JSON decodificables.
- Imports internos de `package:mision_admision` resueltos.
- Versión consistente `0.6.0+6` y build interno 6.
- 110 archivos Dart de producción.
- 19 archivos Dart de pruebas.
- 60 declaraciones de prueba Flutter/Dart.

## Funciones verificadas por inspección y pruebas auxiliares

- Configuración desactivada sin cargar Firebase.
- Consentimiento iniciado solo desde el botón.
- Registro con clave VAPID y service worker existente.
- Renovación del registro basado en Firebase Installation ID al reabrir.
- Recepción foreground mediante el puente.
- Recepción background integrada al service worker.
- Presentación personalizada para mensajes exclusivamente de datos.
- Desactivación y limpieza del registro local.
- Apertura segura de la PWA desde notificaciones personalizadas.
- Persistencia separada del progreso educativo.

## Comprobaciones no ejecutadas en este entorno

No se ejecutaron:

```text
flutter analyze
flutter test
flutter build web
```

porque el SDK de Flutter no está instalado en el entorno actual. Los workflows incluidos ejecutarán estas comprobaciones al subir el proyecto a GitHub.

Tampoco se realizó un envío FCM real porque el proyecto se entrega con `enabled: false` y no se proporcionaron la configuración Firebase ni la clave VAPID del proyecto definitivo. La guía incluye una prueba local y los pasos para crear una campaña de prueba después de configurar Firebase.
