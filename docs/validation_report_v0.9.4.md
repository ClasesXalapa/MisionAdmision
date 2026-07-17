# Reporte de validación v0.9.4

## Objetivo

Corregir el error `El modo PWA no terminó de prepararse a tiempo` al activar Web Push por primera vez.

## Cambios

- Registro temprano y reutilizable del service worker.
- Método `missionAdmissionPwa.ensureServiceWorker()`.
- Espera de activación de hasta 60 segundos.
- Cliente FCM desacoplado de `window.load`.
- Mensajes de error con estado del worker.
- Prueba automatizada del puente PWA.

## Compatibilidad

No cambia `web/firebase_config.js`, los datos locales, los JSON de contenido ni el contrato de respaldo.

## Comprobaciones disponibles

- Sintaxis JavaScript.
- Puente Firebase y Analytics.
- Puente PWA.
- Service worker FCM.
- Validación de contenido y proyecto.
- Generador CSV y herramientas PWA.

GitHub Actions debe confirmar `flutter analyze`, `flutter test` y `flutter build web`.
