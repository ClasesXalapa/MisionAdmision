# Arquitectura de notificaciones y recordatorios — v0.11.4

## Objetivo

Misión Admisión utiliza Firebase Cloud Messaging como señal externa, pero la decisión de reforzar la racha se toma siempre con el progreso local del dispositivo.

No se envían respuestas, calificaciones, racha ni identidad a Firebase.

## Flujo de cada mensaje Firebase

```text
Firebase Console
        ↓
notificación original de la campaña
        ↓
app_service_worker.js o notifications_bridge.js
        ↓
IndexedDB: estado mínimo del reto diario
        ↓
¿El reto de hoy sigue pendiente?
├── no → no genera recordatorio de racha
└── sí → recordatorio local inmediato
              ↓
       encola un seguimiento
              ↓
       próxima oportunidad útil del navegador
              ↓
       nueva comprobación local
              ↓
       ¿sigue pendiente?
       ├── sí → segundo recordatorio local
       └── no → descarta el seguimiento
```

Cada mensaje Firebase pendiente crea su propio seguimiento. No existe un bloqueo por “ya mostrado hoy”.

## Cuándo puede aparecer el segundo recordatorio

La aplicación no fija un temporizador exacto. El seguimiento se entrega cuando exista un evento posterior adecuado:

- Background Sync administrado por el navegador;
- llegada de otro mensaje Firebase;
- recuperación de conexión;
- reapertura de la PWA;
- regreso de la PWA al primer plano.

El seguimiento nunca depende de que el service worker permanezca vivo durante varios minutos.

## Plan B nocturno sin Firebase

Al abrir o reanudar Misión Admisión después de las 20:00, la página consulta el estado local aunque no exista conexión.

```text
Abrir o reanudar la PWA después de las 20:00
        ↓
¿Notificaciones activadas?
        ↓
¿El reto de hoy sigue pendiente?
├── sí → recordatorio local nocturno
└── no → no muestra nada
```

No se guarda una marca de “mostrado hoy”. Una reapertura posterior puede volver a ejecutar la comprobación.

Si en la misma apertura ya se entregó un seguimiento pendiente, no se añade además el recordatorio nocturno en ese mismo evento.

## Estado compartido

La página Flutter conserva la fuente real del progreso. IndexedDB refleja solamente el estado mínimo necesario.

```text
Base: mision_admision_notification_state_v1
Almacén: state
```

### Registro `daily_progress`

```text
initialized
lastCompletedDateKey
challengeAvailable
updatedAt
```

### Registro `daily_follow_up`

```text
dateKey
pendingCount
lastCreatedAt
lastClaimedAt
lastSource
```

`pendingCount` permite que varias campañas con el reto pendiente conserven un segundo seguimiento cada una. Los seguimientos expiran al cambiar la fecha local.

### Registro `daily_diagnostics`

Contiene fechas técnicas, conteos y la última decisión del motor. No contiene respuestas, calificaciones ni identificadores personales.

## Decisiones principales del motor

```text
pending
follow_up_pending
evening_pending
completed_today
challenge_unavailable
state_not_initialized
follow_up_completed_today
follow_up_challenge_unavailable
storage_error
follow_up_error
evening_error
unsupported
```

El comportamiento sigue siendo conservador: si el estado no está inicializado o no puede leerse, no se inventa que el reto está pendiente.

## Primer plano y segundo plano

- **PWA cerrada o minimizada:** Firebase muestra la campaña y el service worker puede crear el aviso inmediato y encolar el seguimiento.
- **PWA visible:** el puente muestra la campaña, consulta el reto, crea el aviso inmediato si corresponde y encola el seguimiento.
- **Evento posterior:** se reclama un seguimiento y se vuelve a comprobar el progreso antes de mostrarlo.
- **Reto completado:** Flutter actualiza IndexedDB, vacía los seguimientos y solicita cerrar todos los avisos locales del reto.

## Frecuencia

No hay límite diario artificial dentro de la aplicación:

- cada campaña Firebase puede producir un recordatorio inmediato;
- cada campaña pendiente puede producir un segundo recordatorio posterior;
- el navegador decide cuándo dispone de una oportunidad para el seguimiento;
- completar el reto cancela la cola restante.

El equipo editorial debe considerar esta conducta al decidir cuántas campañas enviar.

## Compatibilidad y degradación

Background Sync no está disponible en todos los navegadores. La cola no depende exclusivamente de esa API: también se procesa al abrir, reanudar, recuperar conexión o recibir otro Firebase.

Una PWA completamente cerrada no puede garantizar una hora exacta sin un evento del navegador o una nueva señal remota.

## Seguridad

- Un solo service worker administra caché offline y FCM.
- Los enlaces se restringen al origen y directorio de la PWA.
- Los recordatorios locales abren `#/daily`.
- El FID vive únicamente en almacenamiento local y no aparece en diagnósticos generales.
- No se requieren Firestore, Cloud Functions, Firebase Auth ni backend propio.
