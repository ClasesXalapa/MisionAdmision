# Configuración de notificaciones web con Firebase Cloud Messaging

La versión 0.6.0 incluye el cliente para solicitar permiso, registrar el navegador con Firebase Installation IDs, recibir mensajes en primer y segundo plano y desactivar el registro. La integración permanece desactivada hasta completar:

```text
web/firebase_config.js
```

## 1. Crear el proyecto

1. Abre Firebase Console.
2. Crea un proyecto o utiliza uno existente.
3. No es necesario activar Firestore, Storage, Authentication ni Firebase Hosting.
4. Agrega una aplicación **Web** dentro del proyecto.

## 2. Copiar la configuración web

Firebase mostrará un objeto parecido a este:

```js
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...firebaseapp.com",
  projectId: "...",
  storageBucket: "...firebasestorage.app",
  messagingSenderId: "...",
  appId: "...",
};
```

Copia sus valores dentro de `web/firebase_config.js`.

La configuración web y la clave VAPID pública identifican el proyecto, pero no conceden permisos administrativos. No agregues al repositorio una cuenta de servicio, una clave privada ni credenciales de la API HTTP v1.

## 3. Crear la clave Web Push

En Firebase Console:

```text
Configuración del proyecto
→ Cloud Messaging
→ Configuración web
→ Certificados Web Push
→ Generar par de claves
```

Copia la clave pública en `vapidKey` y cambia:

```js
enabled: true,
```

Los proyectos nuevos normalmente tienen habilitada la API de registro FCM. Si Firebase muestra un error de registro, revisa que **FCM Registration API** esté habilitada para el proyecto.

## 4. Publicar

Sube el cambio a GitHub. El workflow reconstruirá la PWA y el mismo `app_service_worker.js` manejará tanto el modo offline como Firebase Cloud Messaging.

## 5. Activar y probar la presentación

1. Abre el sitio publicado mediante HTTPS.
2. Espera a que aparezca **Modo offline preparado**.
3. Pulsa **Activar recordatorio diario**.
4. Acepta el permiso del navegador.
5. Pulsa **Probar** para verificar que el sistema puede mostrar una notificación.

El registro moderno utiliza un Firebase Installation ID. Para inspeccionarlo durante desarrollo:

```js
await missionAdmissionNotifications.getInstallationIdForTesting()
```

No pegues este identificador en el campo antiguo **FCM registration token** de la consola: ese campo corresponde a la API de tokens que Firebase está retirando.

## 6. Probar la recepción FCM

Después de registrar al menos un navegador, crea una campaña de notificación en Firebase Console dirigida a la aplicación Web o a una audiencia de prueba. Mantén la PWA en segundo plano para comprobar la recepción remota.

Ejemplo:

```text
Título: Protege tu racha 🔥
Mensaje: Completa el reto de hoy antes de que termine el día.
Enlace web: URL pública de Misión Admisión
```

## 7. Recordatorio diario

Durante el MVP, crea o programa los mensajes desde el compositor de Firebase Console. La aplicación cliente no contiene credenciales privadas ni envía campañas por sí misma.

La automatización mediante API debe ejecutarse en un entorno confiable. No coloques una cuenta de servicio o un token OAuth dentro de GitHub Pages.

## iPhone y iPad

El usuario debe:

1. Abrir el sitio en Safari.
2. Agregarlo a la pantalla de inicio.
3. Abrir Misión Admisión desde su icono.
4. Pulsar **Activar recordatorio diario**.

## Desactivación

El botón **Desactivar** anula el registro FCM de esa instalación y elimina el identificador local. Bloquear el permiso desde el navegador también impide nuevas notificaciones.
