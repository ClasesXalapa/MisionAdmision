# Misión Admisión — Contexto v9.0

**Versión funcional:** 0.6.0  
**Arquitectura:** Flutter Web + GitHub Pages + JSON + almacenamiento local + service worker propio + Firebase Cloud Messaging opcional.  
**Estado:** cliente de recordatorio diario implementado; configuración Firebase pendiente de los datos reales del proyecto.

## Funciones acumuladas

- Examen libre.
- Reto diario programado y automático.
- Reanudación antes de medianoche.
- Racha, récord, escudos y rangos.
- Cards con filtros y seguimiento.
- Sincronización remota y última copia válida.
- PWA instalable y modo offline.
- Actualizaciones explícitas.
- Consentimiento para notificaciones.
- Registro FCM Web Push.
- Recepción en primer y segundo plano.
- Prueba local y desactivación.

## Arquitectura de notificaciones

```text
firebase_config.js
    ↓ configuración pública
notifications_bridge.js
    ├── comprueba compatibilidad
    ├── solicita permiso por acción del usuario
    ├── obtiene y renueva el registro FCM
    ├── escucha mensajes en primer plano
    └── elimina el registro al desactivar

Flutter
    ↓ dart:js_interop
NotificationService
    ↓
NotificationController
    ↓
NotificationReminderCard

app_service_worker.js
    ├── caché offline
    ├── FCM en segundo plano
    └── apertura segura de la PWA al pulsar
```

## Decisiones de seguridad

- La configuración web de Firebase y la clave VAPID pública pueden estar en el cliente.
- No se incluye una cuenta de servicio.
- No se incluye una clave privada de la API HTTP v1.
- El navegador solicita permiso únicamente después de pulsar el botón.
- El Firebase Installation ID queda almacenado localmente y no se copia a un backend propio.
- El envío se realiza desde Firebase Console durante el MVP.

## Estado desactivado

`web/firebase_config.js` tiene `enabled: false`. En este estado:

- la aplicación compila normalmente;
- no descarga el SDK de Firebase;
- no solicita permiso;
- el service worker conserva todas sus funciones offline;
- la tarjeta informa que el administrador aún no configuró recordatorios.

## Activación

1. Crear proyecto y aplicación Web en Firebase.
2. Copiar la configuración pública.
3. Generar certificado Web Push.
4. Pegar la clave VAPID pública.
5. Cambiar `enabled` a `true`.
6. Publicar nuevamente GitHub Pages.
7. Probar la presentación local y una campaña de prueba desde Firebase Console.

## Siguiente etapa recomendada

1. Crear el proyecto Firebase real y completar la configuración.
2. Probar FCM en Android, escritorio e iPhone instalado.
3. Ejecutar una beta con usuarios reales.
4. Agregar exportación e importación del progreso.
5. Revisar accesibilidad, rendimiento y contenido definitivo antes del lanzamiento.
