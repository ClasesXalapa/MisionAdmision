# Misión Admisión — Contexto v8.0

**Versión funcional:** 0.5.0  
**Arquitectura:** Flutter Web + GitHub Pages + JSON + almacenamiento local + service worker propio.  
**Estado:** PWA instalable y modo offline controlado implementados.

## Funciones acumuladas

- Examen libre.
- Reto diario programado y automático.
- Reanudación antes de medianoche.
- Racha, récord, escudos y rangos.
- Cards con filtros y seguimiento.
- Sincronización desde `content/index.json`.
- Descarga selectiva y última copia válida.
- Instalación como PWA.
- Instrucciones manuales para iOS.
- Caché offline versionada.
- Detección de conexión.
- Actualización explícita de la aplicación.
- Atajos instalables para funciones principales.

## Arquitectura PWA

```text
web/pwa_bridge.js
    ├── registra app_service_worker.js
    ├── captura beforeinstallprompt
    ├── detecta modo standalone
    ├── detecta actualizaciones en espera
    └── expone una API mínima a Dart

Flutter
    ↓ dart:js_interop con import condicional
PwaService
    ↓
PwaController
    ↓
PwaStatusCard
```

La lógica de dominio no importa APIs web. Una futura compilación Android usa la implementación `UnsupportedPwaService` hasta que se agregue una implementación nativa específica.

## Cachés

```text
mision-admision-app-<build hash>
mision-admision-content-<build hash>
mision-admision-runtime-<build hash>
```

- `app`: archivos generados por Flutter, assets, manifest, iconos y fallback offline.
- `content`: JSON públicos bajo `content/`.
- `runtime`: otros archivos locales solicitados durante la ejecución.

Las cachés antiguas se eliminan únicamente cuando la versión nueva se activa.

## Privacidad y separación

Cache Storage contiene archivos públicos. El progreso continúa en almacenamiento local mediante las claves de la aplicación. El service worker no lee racha, respuestas, escudos ni seguimiento de cards.

## Condición offline

La primera carga necesita conexión. El service worker se registra después de cargar la página y guarda la compilación. Una vez activo, las navegaciones pueden recuperar `index.html` y el contenido público desde la caché.

## Actualizaciones

Una nueva compilación se identifica por un hash calculado sobre los archivos generados. El worker nuevo queda en espera y la interfaz solicita confirmación antes de activarlo. La activación recarga la página, pero no borra el almacenamiento local.

## Siguiente etapa recomendada

1. Configurar Firebase Cloud Messaging Web.
2. Implementar consentimiento y registro para una notificación diaria.
3. Definir el mecanismo seguro de envío programado.
4. Probar instalación y offline en dispositivos físicos.
