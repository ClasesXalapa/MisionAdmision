# Configuración de Firebase Web Push — cliente v0.9.0

La versión 0.9.0 deja terminado el cliente Web Push de Misión Admisión. La integración permanece desactivada hasta completar `web/firebase_config.js` con un proyecto Firebase real.

## Qué hace esta versión

- Solicita permiso únicamente después de pulsar **Activar recordatorio diario**.
- Registra la instalación mediante Firebase Installation ID (FID).
- Usa el mismo service worker para PWA offline y mensajes en segundo plano.
- Renueva el registro sin volver a pedir permiso.
- Recibe mensajes en primer plano.
- Recibe mensajes de datos en segundo plano y muestra una notificación local.
- Permite desactivar y anular el registro.
- Restringe los enlaces de notificación al mismo origen y ruta de la PWA.
- Detecta que iPhone/iPad requieren instalar la PWA antes de pedir permiso.

## 1. Crear el proyecto Firebase

1. Abre Firebase Console.
2. Crea un proyecto o utiliza uno existente.
3. No es necesario activar Firestore, Storage, Authentication ni Firebase Hosting.
4. Agrega una aplicación **Web** dentro del proyecto.
5. Conserva GitHub Pages como alojamiento de la PWA.

## 2. Copiar la configuración web

Firebase mostrará un objeto semejante a:

```js
const firebaseConfig = {
  apiKey: '...',
  authDomain: '...firebaseapp.com',
  projectId: '...',
  storageBucket: '...firebasestorage.app',
  messagingSenderId: '...',
  appId: '...',
};
```

Copia esos valores dentro de `web/firebase_config.js`.

La configuración web y la clave VAPID pública identifican el proyecto. No son credenciales administrativas. Aun así, la API key debe permanecer restringida a las APIs de Firebase correspondientes.

Nunca agregues al repositorio:

- una cuenta de servicio;
- una clave privada;
- un token OAuth;
- credenciales de la API HTTP v1;
- secretos del futuro Worker.

## 3. Crear el certificado Web Push

En Firebase Console:

```text
Configuración del proyecto
→ Cloud Messaging
→ Configuración web
→ Certificados Web Push
→ Generar par de claves
```

Copia la clave pública en `vapidKey`.

Los proyectos nuevos suelen tener habilitada la FCM Registration API. Si el registro falla, confirma que esa API esté habilitada en el proyecto correcto de Google Cloud.

## 4. Completar `firebase_config.js`

Ejemplo:

```js
globalThis.MISSION_ADMISSION_FIREBASE = Object.freeze({
  enabled: true,
  sdkVersion: '12.16.0',
  registrationMode: 'fid',
  registrationTimeoutMs: 15000,
  defaultNotificationLink: '#/reto',
  debugLogging: false,
  vapidKey: 'CLAVE_VAPID_PUBLICA',
  config: Object.freeze({
    apiKey: '...',
    authDomain: '...',
    projectId: '...',
    storageBucket: '...',
    messagingSenderId: '...',
    appId: '...',
  }),
});
```

No cambies `registrationMode`. La versión 0.9.0 utiliza exclusivamente `fid`.

## 5. Publicar y activar

1. Sube el cambio a GitHub.
2. Espera a que GitHub Actions publique la nueva compilación.
3. Abre el sitio mediante HTTPS.
4. Espera a que aparezca **Modo offline preparado**.
5. Pulsa **Activar recordatorio diario**.
6. Acepta el permiso del navegador.
7. Pulsa **Probar** para mostrar una notificación local.
8. Pulsa **Renovar registro** para confirmar que el FID sigue disponible.

## 6. Estados esperados

### Android y computadora

El botón de activación puede aparecer directamente cuando el navegador admite Push API, service workers y notificaciones.

### iPhone y iPad

El usuario debe:

1. abrir el sitio en Safari;
2. pulsar Compartir;
3. seleccionar **Agregar a pantalla de inicio**;
4. abrir Misión Admisión desde el icono;
5. pulsar **Activar recordatorio diario**.

La aplicación no solicita permiso desde una pestaña normal de Safari en iOS.

## 7. Identificador para el backend

El cliente guarda localmente el FID y expone, solo para la siguiente integración, este método JavaScript:

```js
await missionAdmissionNotifications.getRegistrationSnapshotForBackend()
```

Devuelve:

```json
{
  "registrationKind": "fid",
  "registrationId": "...",
  "registrationUpdatedAt": "2026-07-16T...Z",
  "enabled": true
}
```

La interfaz y los reportes de diagnóstico nunca muestran `registrationId`.

En la entrega 0.9.1 este snapshot se enviará al backend mínimo de suscripciones.

## 8. Mensajes en primer y segundo plano

- En primer plano, Flutter recibe el mensaje mediante el puente y muestra una notificación usando el service worker.
- En segundo plano, FCM muestra automáticamente los mensajes con payload `notification`.
- Para mensajes únicamente de datos, `app_service_worker.js` crea la notificación.
- Los enlaces externos o fuera de la ruta de la PWA son sustituidos por `#/reto`.

## 9. Desactivación

El botón **Desactivar**:

- ejecuta `unregister()`;
- elimina el FID local;
- elimina la preferencia de recordatorio;
- detiene el listener de primer plano.

Bloquear el permiso desde el navegador también desactiva el estado local en la siguiente apertura.

## 10. Lo que todavía no hace esta entrega

La versión 0.9.0 no:

- almacena el FID en un servidor;
- envía campañas automáticamente;
- contiene credenciales privadas;
- conoce la racha del alumno desde Firebase;
- programa la notificación diaria.

Esas funciones pertenecen a las entregas 0.9.1 y 0.9.2.

## Referencias oficiales

- Firebase Cloud Messaging para Web: https://firebase.google.com/docs/cloud-messaging/web/get-started
- Recepción de mensajes Web: https://firebase.google.com/docs/cloud-messaging/web/receive-messages
- Referencia JavaScript de Messaging: https://firebase.google.com/docs/reference/js/messaging_
- API keys de Firebase: https://firebase.google.com/docs/projects/api-keys
