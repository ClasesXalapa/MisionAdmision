# Reporte de validación v0.9.7

Fecha: 2026-07-16

## Causa corregida

El workflow de GitHub Pages compilaba Flutter Web con la estrategia PWA predeterminada, mientras `pwa_bridge.js` registraba `app_service_worker.js` para caché y Firebase Cloud Messaging. Los dos mecanismos podían intentar administrar el mismo alcance `/MisionAdmision/`, dejando una inscripción sin `installing`, `waiting` ni `active`.

## Cambios

- Build Web con `--pwa-strategy=none`.
- Eliminación defensiva de `build/web/flutter_service_worker.js` antes de publicar.
- Bootstrap propio de Flutter sin configuración de service worker.
- URL versionada `app_service_worker.js?v=19`.
- Recuperación de inscripciones vacías con espera explícita antes del segundo registro.
- Exclusión de `flutter_service_worker.js` del manifiesto de precarga.
- Precarga tolerante a fallos opcionales, manteniendo archivos esenciales obligatorios.
- Validaciones del workflow para confirmar que solo se publica el worker propio.

## Validaciones ejecutadas

- Contenido JSON: aprobado.
- Coherencia estructural y versión 0.9.7+19: aprobado.
- 7 pruebas Python: aprobadas.
- Generador CSV en modo comprobación: aprobado.
- Configuración Firebase opcional: aprobada.
- Puente Firebase/FID/Analytics: aprobado.
- Service worker FCM: aprobado.
- Puentes de respaldo y diagnóstico: aprobados.
- Puente PWA y recuperación de inscripción vacía: aprobado.
- Sintaxis JavaScript de archivos fuente: aprobada.
- Sintaxis YAML de los workflows: aprobada.

## Validación pendiente en GitHub Actions

El entorno local no incluye el SDK Flutter 3.44. GitHub Actions debe confirmar la sustitución de tokens del bootstrap, `flutter analyze`, `flutter test`, la compilación Web con `--pwa-strategy=none` y la sintaxis de los archivos finales en `build/web`.

## Seguridad de aplicación

El hotfix incremental no incluye `web/firebase_config.js`; por tanto, no reemplaza la clave VAPID, el `measurementId` ni la configuración Firebase del repositorio del usuario. Tampoco borra almacenamiento local, progreso, racha o contenido.
