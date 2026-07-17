# Hotfix v0.9.5 — registro del service worker

Corrige el error de Chrome:

`Failed to update a ServiceWorker ... with script ('Unknown'): Not found`

## Aplicación

1. Copia el contenido de este paquete sobre la raíz del repositorio.
2. Conserva `web/firebase_config.js`; este hotfix no lo incluye.
3. Ejecuta:

```powershell
git add .
git commit -m "Corregir registro del service worker v0.9.5"
git push
```

## Después del despliegue

1. Cierra todas las pestañas y ventanas de Misión Admisión.
2. Abre el sitio desde Chrome.
3. Recarga una vez con internet.
4. Espera a que Diagnóstico muestre `Service worker: active`.
5. Pulsa `Activar notificaciones`.

La migración elimina únicamente una inscripción de service worker antigua o incompleta. No borra localStorage, racha, escudos, intentos ni contenido descargado.
