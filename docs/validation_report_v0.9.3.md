# Reporte de validación — Misión Admisión v0.9.3

## Alcance

Hotfix de Google Analytics para operar campañas desde Firebase Console sin agregar Firestore, backend propio ni Cloudflare.

## Comprobaciones ejecutadas

- Contenido JSON válido: 20 preguntas, 1 reto, 6 cards activas y 6 rangos.
- Generador CSV: 5 pruebas aprobadas.
- Preparación PWA: 2 pruebas aprobadas.
- Sintaxis de `notifications_bridge.js`, `firebase_config.js` y validador Firebase.
- Ciclo simulado de Firebase: Analytics activo, Analytics bloqueado sin romper FCM, registro FID, renovación, baja e iPhone.
- Service worker FCM: mensajes de datos, enlaces internos, orden de `notificationclick` y clic seguro.
- Puentes de respaldo y diagnóstico.
- Configuración Firebase desactivada válida.
- Configuración Firebase ficticia activada con `measurementId` válida.
- Búsqueda de cuentas de servicio, claves privadas y API keys reales: sin coincidencias en el paquete.

## Proyecto

- Versión: `0.9.3+15`.
- 126 archivos Dart de producción.
- 23 archivos Dart de pruebas.
- 70 declaraciones `test`/`testWidgets`.

## Limitación del entorno

Este entorno no incluye el SDK de Flutter, por lo que `dart format`, `flutter analyze`, `flutter test` y `flutter build web` deben confirmarse en GitHub Actions. El hotfix conserva las reglas de análisis y no las desactiva.

## Configuración real

El paquete completo contiene una plantilla desactivada de `web/firebase_config.js`. El hotfix incremental excluye ese archivo para no sobrescribir la configuración pública real del proyecto. Después de aplicarlo, el administrador debe agregar manualmente:

```js
analyticsEnabled: true,
```

y dentro de `config`:

```js
measurementId: 'G-TE68CKZ4LL',
```
