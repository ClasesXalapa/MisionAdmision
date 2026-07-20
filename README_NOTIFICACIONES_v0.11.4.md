# Misión Admisión v0.11.4+47 — recordatorios con seguimiento

## Qué cambia

1. Cada mensaje Firebase comprueba el reto diario en primer y segundo plano.
2. Si el reto está pendiente, muestra un aviso local inmediato.
3. Cada mensaje pendiente encola un segundo seguimiento.
4. El seguimiento se intenta en una oportunidad posterior, sin temporizador exacto.
5. Abrir o reanudar la PWA después de las 20:00 ejecuta un plan B local, incluso sin conexión.
6. No existe bloqueo por recordatorio mostrado durante el mismo día.
7. Completar el reto vacía la cola y cierra los avisos locales visibles.

## Archivos principales

```text
web/notification_state_store.js
web/notifications_bridge.js
web/app_service_worker.js
tool/test_notification_state_store.js
tool/test_notifications_bridge.js
tool/test_fcm_service_worker.js
```

## Pruebas locales

```bash
node --check web/notification_state_store.js
node --check web/notifications_bridge.js
node --check web/app_service_worker.js
node tool/test_notification_state_store.js
node tool/test_notifications_bridge.js
node tool/test_fcm_service_worker.js
node tool/test_pwa_bridge.js
```

## Prueba manual recomendada

1. Publica `0.11.4+47` y confirma GitHub Actions en verde.
2. Abre la PWA instalada y activa notificaciones.
3. Deja pendiente el reto diario.
4. Envía una campaña de prueba desde Firebase Console.
5. Comprueba la campaña original y el aviso inmediato del reto.
6. Espera una oportunidad posterior del navegador o vuelve a abrir/reanudar la PWA para comprobar el seguimiento.
7. Completa el reto.
8. Envía otra campaña: la campaña original puede aparecer, pero no debe generarse el refuerzo local de racha.
9. Con un reto pendiente, abre la PWA después de las 20:00 y comprueba el aviso nocturno local.

## Límites esperados

- El segundo aviso no tiene una hora exacta.
- Si el navegador no admite Background Sync, se procesa en otra señal Firebase, reapertura, reanudación o recuperación de conexión.
- La PWA no puede despertar por sí sola a una hora exacta cuando está totalmente cerrada.
- No se añadió backend, Firestore ni Cloud Functions.
