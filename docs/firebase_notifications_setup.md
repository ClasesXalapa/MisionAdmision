# Configuración de Firebase Console — cliente v0.9.1

La versión 0.9.1 prepara Misión Admisión para recibir Web Push y operar los envíos exclusivamente desde **Firebase Console**. No utiliza Cloudflare, Firestore, Cloud Functions, servidor propio ni base remota de alumnos.

## Arquitectura elegida

```text
GitHub Pages
+ PWA Flutter Web
+ Firebase Cloud Messaging
+ campañas creadas en Firebase Console
```

## Qué hace el cliente

- Solicita permiso únicamente después de pulsar **Activar notificaciones**.
- Registra la instalación mediante Firebase Installation ID (FID).
- Usa el mismo service worker para PWA offline y mensajes FCM.
- Recibe mensajes con la PWA abierta, minimizada o cerrada.
- Limita los enlaces a rutas internas de Misión Admisión.
- Permite probar, reparar y desactivar notificaciones.
- Permite copiar temporalmente el FID para una prueba dirigida.

## 1. Crear el proyecto Firebase

1. Abre Firebase Console.
2. Crea un proyecto llamado **Misión Admisión**.
3. Analytics es opcional y puede permanecer desactivado.
4. No actives Firestore, Authentication, Storage ni Firebase Hosting.
5. Agrega una aplicación **Web**.
6. Conserva GitHub Pages como alojamiento.

## 2. Copiar la configuración pública

Firebase mostrará un objeto similar a:

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

Estos valores identifican el proyecto desde el cliente. No son una cuenta de servicio ni una clave administrativa.

Nunca publiques:

- cuentas de servicio;
- claves privadas;
- tokens OAuth;
- credenciales de la API HTTP v1.

## 3. Generar la clave Web Push

En Firebase Console:

```text
Configuración del proyecto
→ Cloud Messaging
→ Certificados Web Push
→ Generar par de claves
```

Copia la clave pública en `vapidKey`.

## 4. Completar `web/firebase_config.js`

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

No cambies `registrationMode`.

## 5. Publicar

```bash
git add .
git commit -m "Conectar Firebase Cloud Messaging"
git push
```

Espera a que GitHub Actions termine y abre el sitio publicado mediante HTTPS.

## 6. Registrar un navegador

1. Espera a que aparezca **Modo offline preparado**.
2. Pulsa **Activar notificaciones**.
3. Acepta el permiso del navegador.
4. Pulsa **Probar** para una notificación local.
5. Usa **Reparar notificaciones** si necesitas confirmar nuevamente el registro.

En iPhone o iPad primero instala la PWA desde Safari mediante **Compartir → Agregar a pantalla de inicio**.

## 7. Copiar el FID para una prueba dirigida

Cuando el registro esté activo, pulsa **Copiar ID de prueba**. Ese valor identifica únicamente esa instalación del navegador.

- Úsalo solo durante la prueba técnica.
- No lo publiques.
- No lo agregues a reportes generales.
- Desactivar notificaciones elimina la copia local.

El código ya no expone snapshots para un backend, porque esta arquitectura no utiliza servidor propio.

## 8. Enviar desde Firebase Console

En Firebase Console:

```text
DevOps y participación
→ Messaging
→ Nueva campaña
→ Notificaciones
```

Primero utiliza **Enviar mensaje de prueba** con el identificador de la instalación, cuando la consola lo admita para el proyecto migrado a FID. Si la interfaz solicita un registro distinto, crea una campaña para el segmento de la aplicación Web y prueba con un grupo reducido.

Para campañas normales puedes seleccionar segmentos predefinidos y enviar inmediatamente o programar cada mensaje para una fecha y hora específicas.

Firebase Console no sustituye una tarea recurrente de servidor: para el MVP se enviará manualmente cada día o se crearán mensajes individuales programados.

## 9. Datos personalizados recomendados

Al crear una campaña, agrega opcionalmente:

```text
link = #/reto
tag  = recordatorio-diario
```

Los enlaces externos o fuera del directorio de la PWA serán reemplazados por `#/reto`.

## 10. Clic en las notificaciones

El controlador `notificationclick` se registra antes de importar Firebase, como exige la guía oficial para evitar que FCM reemplace el comportamiento personalizado.

Al tocar una notificación:

1. se busca una ventana abierta de Misión Admisión;
2. se enfoca y navega a la ruta interna;
3. si no existe una ventana, se abre la PWA;
4. una URL externa se sustituye por `#/reto`.

## 11. Lo que no utiliza esta solución

- Cloudflare;
- Firestore;
- Cloud Functions;
- Firebase Authentication;
- backend propio;
- almacenamiento remoto del progreso;
- credenciales privadas en GitHub Pages.

## Referencias oficiales

- https://firebase.google.com/docs/cloud-messaging/web/get-started
- https://firebase.google.com/docs/cloud-messaging/web/receive-messages
- https://firebase.google.com/docs/cloud-messaging/send/firebase-console
- https://firebase.google.com/docs/projects/api-keys
