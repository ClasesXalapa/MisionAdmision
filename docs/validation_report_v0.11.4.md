# Reporte de validación — Misión Admisión v0.11.4+47

## Alcance

Esta entrega modifica únicamente el cliente de notificaciones y el versionado coordinado. No cambia preguntas, recursos, progreso, racha, escudos, rutas, diseño visual ni sincronización de contenido.

## Comportamiento validado

- Cada mensaje Firebase en primer plano comprueba el reto y muestra un aviso inmediato cuando está pendiente.
- Cada mensaje Firebase en segundo plano comprueba el reto y muestra un aviso inmediato cuando está pendiente.
- Cada mensaje pendiente incrementa una cola de seguimientos en IndexedDB.
- Una señal Firebase posterior puede procesar un seguimiento anterior.
- Background Sync puede procesar el seguimiento sin un intervalo exacto.
- Recuperar conexión puede procesar el seguimiento desde la página.
- Abrir la PWA después de las 20:00 ejecuta el plan B local.
- Reanudar la PWA después de las 20:00 vuelve a ejecutar el plan B sin límite diario.
- Completar el reto vacía la cola y cierra los avisos locales visibles.
- Desactivar notificaciones elimina los seguimientos pendientes.
- Los enlaces externos continúan restringidos a la ruta interna segura.

## Validaciones ejecutadas

```text
python3 tool/validate_content.py
python3 tool/validate_project.py
python3 -m unittest discover -s tool/tests -v
python3 tool/generate_content_from_csv.py admin/csv_samples --check-only
node tool/validate_firebase_config.js
node tool/test_notification_state_store.js
node tool/test_notifications_bridge.js
node tool/test_fcm_service_worker.js
node tool/test_backup_bridge.js
node tool/test_diagnostics_bridge.js
node tool/test_pwa_bridge.js
node --check de todos los puentes y service worker
```

Resultado: todas las validaciones disponibles terminaron correctamente.

## Validación pendiente en CI

El entorno de preparación no incluye Flutter ni Dart. GitHub Actions debe confirmar:

```text
dart format lib test
flutter analyze --no-fatal-infos
flutter test
flutter build web --release --pwa-strategy=none
```

## Prueba real recomendada

1. Publicar `0.11.4+47`.
2. Confirmar GitHub Actions en verde.
3. Abrir la PWA instalada y activar notificaciones.
4. Mantener pendiente el reto.
5. Enviar una campaña Firebase de prueba.
6. Confirmar el aviso local inmediato.
7. Esperar Background Sync o reabrir/reanudar la PWA para confirmar el seguimiento.
8. Completar el reto y enviar otra campaña.
9. Confirmar que ya no aparece el refuerzo local.
10. Con un reto pendiente, abrir la PWA después de las 20:00 y confirmar el plan B nocturno.
