# Misión Admisión — Contexto técnico v15

**Versión:** 0.9.3+15  
**Arquitectura:** Flutter Web + GitHub Pages + JSON + almacenamiento local + Firebase Cloud Messaging + Google Analytics.

## Cambio principal

Google Analytics se inicializa en la página principal para permitir campañas y segmentación desde Firebase Console. La inicialización es opcional y tolerante a fallos: si Analytics está bloqueado, FCM y el resto de la PWA siguen funcionando.

## Configuración

`web/firebase_config.js` incorpora `analyticsEnabled` y `config.measurementId`. La configuración administrativa privada continúa fuera de GitHub Pages.

## Privacidad

No se envían respuestas, racha, escudos ni progreso educativo a Analytics. El diagnóstico solo expone el estado técnico de Analytics.
