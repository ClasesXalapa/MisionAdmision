# Reporte de validación v0.9.6

## Corrección

- Se eliminó la desinscripción preventiva de workers con otro nombre de script.
- `register()` se usa para crear o actualizar el worker del mismo alcance.
- Se detecta y repara únicamente una inscripción fantasma sin workers asociados.
- La espera de activación vuelve a consultar `getRegistration()` para adoptar el objeto vigente.
- `index.html` usa `pwa_bridge.js?v=18` para invalidar la copia HTTP anterior.
- El hotfix no contiene `web/firebase_config.js` y no reemplaza la configuración real.

## Pruebas estructurales

- Migración desde un worker activo anterior sin `unregister()`.
- Recuperación simulada de una inscripción vacía heredada de v0.9.5.
- Activación observada mediante consulta periódica del registro actual.
- Sintaxis JavaScript, contenido, proyecto y herramientas PWA.

GitHub Actions debe confirmar `flutter analyze`, `flutter test` y `flutter build web`.
