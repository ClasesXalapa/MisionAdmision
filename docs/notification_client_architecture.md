# Arquitectura del cliente de notificaciones v0.9.0

```text
NotificationReminderCard
        ↓
NotificationController
        ↓
NotificationService
        ↓
notifications_bridge.js
        ↓
Firebase JS SDK 12.16.0
        ↓
Firebase Installation ID
```

El service worker es único:

```text
app_service_worker.js
├── caché offline
├── actualización de la PWA
├── mensajes FCM en segundo plano
├── clic en notificación
└── solicitud de renovación de registro
```

## Persistencia local

```text
mision_admision.notifications_enabled.v1
mision_admision.fcm_installation_id.v1
mision_admision.fcm_registered_at.v1
```

El identificador FID no se incluye en respaldos ni diagnósticos.

## Reglas de seguridad

1. Solo HTTPS o localhost.
2. Solicitud de permiso iniciada por el usuario.
3. Clave VAPID pública en cliente.
4. Ninguna credencial administrativa en GitHub Pages.
5. Enlaces limitados al mismo origen y directorio de la PWA.
6. Registro concurrente deduplicado.
7. Baja explícita mediante `unregister()`.
8. Configuración desactivada por defecto.

## Compatibilidad

La API FID requiere en el módulo `firebase/messaging`:

```text
register
unregister
onRegistered
onUnregistered
onMessage
isSupported
```

El puente rechaza versiones del SDK que no expongan ese conjunto.
