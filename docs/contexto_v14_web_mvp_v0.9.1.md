# Misión Admisión — Contexto v14

**Versión:** 0.9.1+13  
**Fecha:** 2026-07-16

## Decisión cerrada de notificaciones

```text
GitHub Pages
+ Firebase Cloud Messaging
+ Firebase Console para envíos
```

Cloudflare, D1, Firestore, Cloud Functions y backend propio quedan fuera del MVP.

## Cambios de esta versión

- Eliminado el snapshot destinado a backend.
- Agregada copia controlada del FID para pruebas técnicas.
- Clic de notificaciones registrado antes de importar Firebase.
- Compatibilidad con notificaciones automáticas de FCM y mensajes de datos.
- Enlaces restringidos al sitio.
- Textos orientados a campañas de Firebase Console, no a automatización diaria.
- Documentación actualizada para configuración y operación manual/programada.

## Siguiente paso

Crear el proyecto Firebase real, completar `web/firebase_config.js`, publicar y enviar la primera notificación desde Firebase Console.
