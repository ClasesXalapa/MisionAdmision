# Misión Admisión — Contexto v7.0

**Versión funcional:** 0.4.0  
**Arquitectura:** Flutter Web + GitHub Pages + JSON + almacenamiento local.  
**Estado:** sincronización remota local-first implementada.

## Funciones acumuladas

- Examen libre.
- Reto diario programado y automático.
- Reanudación antes de medianoche.
- Racha, récord, escudos y rangos.
- Cards con filtros y seguimiento.
- Actualización desde `content/index.json`.
- Descarga selectiva por versión.
- Caché versionada de última versión válida.
- Activación coordinada mediante metadatos.
- Fallback a assets incluidos.
- Actualización automática no más de una vez cada 30 minutos.
- Actualización manual forzada.
- Estado visual de sincronización.

## Regla de seguridad implementada

```text
Una descarga remota nunca se usa antes de pasar DTO, metadatos,
validadores y comprobaciones de relaciones.
```

Preguntas y retos se validan como un conjunto. Un banco nuevo también debe conservar las preguntas utilizadas por el intento diario vigente. Los intentos vencidos no bloquean actualizaciones posteriores.

Las copias remotas válidas se escriben bajo claves que incluyen su versión. Solo después se actualiza el mapa de metadatos que determina qué versiones están activas, evitando exponer una mezcla parcial durante la sincronización.

## Persistencia

El almacenamiento permanece detrás de interfaces. En 0.4.0 los documentos se guardan como texto JSON mediante `shared_preferences`. Esto es suficiente para el banco demostrativo y permite sustituir la implementación por IndexedDB cuando el volumen lo requiera.

## Siguiente etapa recomendada

1. PWA offline con service worker controlado.
2. Pantalla o flujo de instalación.
3. Firebase Cloud Messaging para un recordatorio diario.
4. Pruebas en Chrome Android, Edge, Firefox y Safari instalado.
