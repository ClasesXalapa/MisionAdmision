# Hotfix v0.9.6 — recuperación de inscripción PWA vacía

Corrige el error:

```text
El modo PWA continúa preparándose (sin estado)
```

La v0.9.5 podía desregistrar una inscripción anterior y volver a registrar el worker antes de que Chrome terminara la eliminación. El navegador conservaba entonces un registro sin `active`, `waiting` ni `installing`.

## Aplicación

Copia el contenido de este directorio sobre la raíz del repositorio y acepta reemplazar los archivos.

Este paquete no contiene `web/firebase_config.js`; conserva la configuración real de Firebase, Analytics y VAPID.

Después:

```bash
git add .
git commit -m "Reparar inscripción PWA vacía v0.9.6"
git push
```

## Recuperación

- `register()` actualiza directamente el worker del mismo alcance.
- No se desregistra un worker activo solo porque tenga un nombre de script anterior.
- Solo se elimina una inscripción vacía sin workers asociados.
- La espera consulta periódicamente el registro vigente del navegador.
- `index.html` usa una URL versionada del puente PWA para no reutilizar el script v0.9.5 desde la caché HTTP.
- No se borra el almacenamiento local ni el progreso educativo.
