# Privacidad — Misión Admisión v0.9.8

Misión Admisión no solicita nombre, correo ni una cuenta de alumno. El progreso educativo permanece en el navegador del usuario.

## Datos locales

Se almacenan localmente la racha, escudos, reto pendiente, respuestas del intento pendiente, recursos vistos y recursos completados. Estos datos no se envían a Google Analytics.

## Firebase Cloud Messaging

Cuando el usuario activa notificaciones, Firebase crea un identificador técnico para esa instalación. Se utiliza para entregar notificaciones y puede copiarse manualmente solo durante pruebas técnicas. No se incluye en diagnósticos ni respaldos.

Cada mensaje Firebase puede activar una comprobación local del reto diario. Para ello se refleja en IndexedDB únicamente la fecha del último reto completado y datos técnicos de diagnóstico, como la hora de recepción y el número de recordatorios locales. No se copian respuestas, puntuaciones ni la racha completa.

## Google Analytics

Google Analytics se utiliza para métricas generales de uso y para habilitar las funciones de campañas y segmentación de Firebase Console. La integración no registra eventos personalizados con respuestas, calificaciones, racha, escudos o progreso educativo.

Los navegadores, extensiones o bloqueadores pueden impedir la carga de Analytics. En ese caso, Misión Admisión debe continuar funcionando y las notificaciones FCM pueden seguir activándose.

## Contenido público

Preguntas, retos, cards y rangos son archivos JSON públicos alojados con la aplicación.
