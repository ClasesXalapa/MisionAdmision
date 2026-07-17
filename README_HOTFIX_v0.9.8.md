# Hotfix v0.9.8 — recordatorio local del reto pendiente

## Qué hace

Cada notificación recibida desde Firebase Console mantiene su mensaje motivacional y despierta el service worker. Si el reto del día sigue pendiente, Misión Admisión genera un recordatorio local adicional.

No existe límite diario en la aplicación. Tres campañas Firebase pueden producir tres recordatorios locales mientras el reto siga pendiente.

## Aplicación

1. Copia todo el contenido de este hotfix sobre la raíz del repositorio.
2. Acepta reemplazar los archivos.
3. Conserva `web/firebase_config.js`; el hotfix no lo incluye.
4. Ejecuta:

```powershell
git status
git add .
git commit -m "Agregar recordatorios del reto pendiente v0.9.8"
git push
```

## Prueba recomendada

1. Abre la versión 0.9.8+20 y espera a que el diagnóstico indique estado compartido inicializado.
2. Deja el reto sin completar.
3. Envía una notificación de prueba desde Firebase Console sin datos personalizados.
4. Con la PWA minimizada o cerrada deben aparecer la notificación Firebase y el recordatorio local del reto.
5. Envía otra prueba: debe aparecer otro recordatorio local.
6. Completa el reto.
7. Envía una tercera prueba: debe aparecer únicamente la notificación Firebase.

## Configuración Firebase

No agregues datos personalizados. Puedes programar varias campañas durante el día. Se recomienda vencimiento de 8 horas para cada campaña.
