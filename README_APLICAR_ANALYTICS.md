# Hotfix Analytics v0.9.3

Este paquete es incremental y **no contiene `web/firebase_config.js`**, para no sobrescribir la configuración pública real de Firebase.

## Aplicación

1. Copia el contenido de este paquete sobre la raíz del repositorio.
2. Conserva tu archivo `web/firebase_config.js` actual.
3. En ese archivo agrega:

```js
analyticsEnabled: true,
```

junto a `debugLogging`, y dentro de `config` agrega:

```js
measurementId: 'G-TE68CKZ4LL',
```

4. Ejecuta:

```powershell
git add .
git commit -m "Agregar Google Analytics para Firebase Console v0.9.3"
git push
```

## Resultado esperado

GitHub Actions debe validar FCM con Analytics activo. En **Ayuda y diagnóstico**, Google Analytics debe aparecer como **Activo**. Si un bloqueador lo impide, aparecerá **Bloqueado o no disponible**, pero las notificaciones deben continuar funcionando.
