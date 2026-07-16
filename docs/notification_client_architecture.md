# Arquitectura del cliente de notificaciones — v0.9.1

## Componentes

```text
Firebase Console
        ↓
Firebase Cloud Messaging
        ↓
app_service_worker.js
├── recepción en segundo plano
├── clic seguro
└── caché offline de la PWA

notifications_bridge.js
├── consentimiento
├── registro FID
├── recepción en primer plano
├── reparación del registro
├── prueba local
└── copia controlada del FID para pruebas

Flutter
└── NotificationReminderCard
```

## Decisiones

- Sin backend propio.
- Sin Cloudflare, Firestore ni Cloud Functions.
- Los mensajes se crean desde Firebase Console.
- El FID vive únicamente en el almacenamiento local del navegador.
- El FID completo no aparece en diagnósticos generales.
- La copia del FID requiere una acción explícita del usuario y se usa solo para pruebas dirigidas.
- `notificationclick` se registra antes de cargar las bibliotecas FCM.
- Todos los destinos se restringen al origen y directorio de la PWA.

## Estados locales

```text
mision_admision.notifications_enabled.v1
mision_admision.fcm_installation_id.v1
mision_admision.fcm_registered_at.v1
```

Desactivar elimina estas claves y ejecuta `unregister()`.
