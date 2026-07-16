# Arquitectura funcional — v0.6.0

## Lectura local-first

```text
Pantallas
    ↓
Repositorios de dominio
    ↓
LocalFirstContentLoader
    ├── caché local validada
    └── asset incluido como fallback
    ↓
ContentDocumentParser
    ↓
Modelos de dominio
```

La UI nunca interpreta JSON ni decide qué copia utilizar.

## Sincronización remota

```text
ContentSyncCard
    ↓
ContentSyncService
    ├── RemoteTextClient
    ├── ContentIndexParser
    ├── ContentDocumentParser
    ├── ContentCacheRepository
    └── DailyAttemptRepository
```

Los documentos se descargan y validan antes de escribirse bajo claves versionadas. Un único cambio de metadatos activa el conjunto nuevo.

## Plataforma PWA

```text
PwaStatusCard
    ↓
PwaController
    ↓
PwaService
    ├── WebPwaService → dart:js_interop → pwa_bridge.js
    └── UnsupportedPwaService → otras plataformas
```

`pwa_bridge.js` es la única superficie JavaScript visible para Dart. Registra el service worker, captura el evento de instalación y administra la activación de una actualización en espera.

## Service worker

```text
flutter build web
→ copiar content/
→ tool/prepare_pwa.py
→ hash de build
→ app_service_worker.js generado
```

Estrategias:

- navegación: network-first con fallback a `index.html`;
- JSON: network-first con fallback de caché;
- app shell: cache-first;
- recursos locales no previstos: runtime cache;
- otros orígenes y solicitudes no GET: sin intervención.

## Recuperación

- JSON remoto inválido: conserva la copia anterior.
- Caché de contenido local corrupta: usa el asset incluido.
- Sin conexión: usa aplicación y contenido públicos guardados.
- Service worker no soportado: la aplicación sigue funcionando en línea.
- Actualización disponible: permanece en espera hasta la acción del usuario.
- Lecturas concurrentes de contenido: observan una versión activa completa.

## Capas

```text
features        presentación y acciones del usuario
domain          modelos, motores, contratos y servicios
data            DTO, parsers, validadores y repositorios
core            HTTP, almacenamiento, assets, tiempo y constantes
platform        adaptadores específicos de web o dispositivo
content         JSON publicado de forma independiente
web             manifest, bridge y service worker
```


## Notificaciones Web Push

La capacidad se mantiene detrás de `NotificationService`. La implementación web usa un puente JavaScript y la implementación alternativa permanece desacoplada para una futura aplicación Android. El mismo service worker administra caché y FCM para evitar alcances en conflicto. Las credenciales administrativas nunca forman parte del cliente.
