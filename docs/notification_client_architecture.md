# Arquitectura de notificaciones y recordatorios — v0.9.8

## Flujo principal

```text
Firebase Console
        ↓
notificación motivacional visible
        ↓
Firebase despierta app_service_worker.js
        ↓
IndexedDB: fecha del último reto completado
        ↓
¿El reto local de hoy sigue pendiente?
├── sí → recordatorio local adicional
└── no → ningún aviso adicional
```

Cada mensaje de Firebase funciona como señal genérica. No se requieren datos personalizados en la campaña.

## Frecuencia

No existe un límite diario impuesto por la aplicación. Si se envían tres campañas Firebase durante el día y el reto sigue pendiente, pueden generarse tres recordatorios locales adicionales. Al completar el reto, los recordatorios locales visibles se cierran y los siguientes mensajes Firebase dejan de generar avisos adicionales durante esa fecha local.

## Estado compartido

La página Flutter conserva la fuente real del progreso. El navegador refleja únicamente este estado mínimo en IndexedDB:

```text
Base: mision_admision_notification_state_v1
Almacén: state
Registro: daily_progress
- initialized
- lastCompletedDateKey
- challengeAvailable
- updatedAt
```

No se duplican respuestas, calificaciones, escudos, correo ni identidad.

El registro `daily_diagnostics` contiene solamente fechas técnicas, conteos y la última decisión del motor de recordatorios.

## Decisiones del motor

```text
pending
completed_today
state_not_initialized
challenge_unavailable
app_visible
storage_error
unsupported
```

El comportamiento es conservador: cuando el estado no está disponible o está dañado, no se genera la segunda notificación.

## Primer plano y segundo plano

- PWA cerrada o minimizada: Firebase muestra la notificación original y el service worker puede generar el recordatorio del reto.
- PWA visible: el puente muestra la notificación Firebase y registra `app_visible`; no crea un segundo aviso local.
- Reto completado: Flutter actualiza IndexedDB y solicita cerrar todos los recordatorios locales del reto.

## Seguridad

- Un solo service worker administra caché offline y FCM.
- Los enlaces se restringen al origen y directorio de la PWA.
- El recordatorio local abre `#/daily`.
- El FID vive únicamente en almacenamiento local y no aparece en diagnósticos generales.
- No se requieren Firestore, Cloud Functions, Firebase Auth ni backend propio.
