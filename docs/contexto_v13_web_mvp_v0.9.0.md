# Misión Admisión — Contexto técnico v13

> Documento histórico. La decisión de backend con Cloudflare fue cancelada en v0.9.1. Consulta `contexto_v14_web_mvp_v0.9.1.md`.

## Versión

```text
0.9.0+12
```

## Entrega cerrada

Cliente Firebase Web Push auditado y preparado para conexión real.

## Decisiones

- Firebase JavaScript SDK 12.16.0.
- Registro basado en Firebase Installation ID.
- Un solo service worker para offline y notificaciones.
- Configuración pública separada en `web/firebase_config.js`.
- Integración desactivada por defecto.
- Sin backend, base remota ni credenciales privadas en esta versión.
- Enlaces de notificación restringidos a la PWA.
- iPhone exige instalación en pantalla de inicio.

## Decisión posterior

La v0.9.1 eliminó el backend previsto. Los envíos se administran desde Firebase Console.
