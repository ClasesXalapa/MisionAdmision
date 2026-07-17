# Misión Admisión — contexto técnico v16

## Versión

- Aplicación: 0.9.8+20
- Plataforma: Flutter Web PWA en GitHub Pages
- Notificaciones: Firebase Cloud Messaging desde Firebase Console
- Analytics: Google Analytics opcional para campañas

## Cambio principal

Cada notificación recibida desde Firebase funciona también como señal para comprobar el reto diario local. La PWA refleja en IndexedDB únicamente la fecha del último reto completado. Si el reto sigue pendiente, el service worker genera un recordatorio local adicional.

No existe límite diario en la aplicación. Varias campañas Firebase pueden producir varios recordatorios mientras el reto siga pendiente. Al completar el reto, los avisos locales visibles se cierran y no vuelven a generarse hasta el siguiente día local.

## Arquitectura conservada

- Sin cuentas.
- Sin Firestore.
- Sin Cloud Functions.
- Sin backend propio.
- Progreso educativo local.
- Contenido público mediante JSON.
- Un solo service worker para PWA y FCM.
