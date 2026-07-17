# Hotfix PWA v0.9.7

Este paquete corrige la competencia entre el service worker generado por Flutter y el service worker propio de Misión Admisión.

## Aplicación

1. Copia todo el contenido del ZIP en la raíz del repositorio.
2. Asegúrate de copiar también la carpeta oculta `.github`.
3. Acepta reemplazar los archivos existentes.
4. Conserva `web/firebase_config.js`; el hotfix no lo incluye.
5. Ejecuta:

```powershell
git status
git add .
git commit -m "Eliminar conflicto de service workers v0.9.7"
git push
```

## Comprobación

GitHub Actions debe mostrar, durante la compilación:

```text
flutter build web ... --pwa-strategy=none
PWA preparada: ...
```

Después del despliegue abre:

```text
https://clasesxalapa.github.io/MisionAdmision/?v=097
```

Cierra antes todas las ventanas de la PWA. Espera unos segundos y revisa Ayuda y diagnóstico. El resultado esperado es:

```text
Aplicación: 0.9.7+19
Service worker: active
Modo offline: preparado
```

Después pulsa Activar notificaciones, Probar y Copiar ID de prueba.
