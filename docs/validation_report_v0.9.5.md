# Reporte de validación v0.9.5

## Corrección

- Se eliminó `registration.update()` inmediatamente después de `register()`.
- Se agregó detección y eliminación de inscripciones antiguas o incompletas.
- Se añadió un reintento controlado para errores de script `Unknown` / `Not found`.
- El hotfix no contiene `web/firebase_config.js` y no reemplaza la configuración real del proyecto.

## Pruebas estructurales

- Sintaxis JavaScript.
- Migración simulada desde `flutter_service_worker.js`.
- Registro del worker `app_service_worker.js` con alcance de GitHub Pages.
- Validadores de contenido y proyecto.
- Pruebas Python de generación de contenido y PWA.

GitHub Actions debe confirmar `flutter analyze`, `flutter test` y `flutter build web`.
