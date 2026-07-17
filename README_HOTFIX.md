# Hotfix v0.9.4 — preparación de PWA para notificaciones

Corrige el mensaje `El modo PWA no terminó de prepararse a tiempo` que podía aparecer al activar notificaciones durante la primera visita.

## Aplicación

Copia todo el contenido de este paquete sobre la raíz del repositorio y acepta reemplazar archivos.

Este paquete **no contiene `web/firebase_config.js`**, por lo que no reemplaza la configuración Firebase real.

Después ejecuta:

```powershell
git add .
git commit -m "Corregir preparación PWA para notificaciones v0.9.4"
git push
```

Después del despliegue, abre la PWA, aplica la actualización disponible, recarga una vez y vuelve a pulsar **Activar notificaciones**.
