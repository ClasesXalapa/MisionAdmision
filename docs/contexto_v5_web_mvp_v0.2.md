# Misión Admisión — Punto de control v5.0

**Fecha:** 15 de julio de 2026  
**Versión técnica:** 0.2.0  
**Plataforma inicial:** Flutter Web / PWA en GitHub Pages

## Estado actual

La base web ya permite:

- cargar y validar un banco local de preguntas;
- realizar exámenes libres de 10 reactivos;
- resolver un reto diario programado por fecha;
- generar un reto automático estable cuando no hay uno programado;
- guardar respuestas e índice actual en el navegador;
- reanudar el intento durante la misma fecha local;
- invalidar el intento cuando cambia el día;
- registrar racha actual, mejor racha y total de retos completados;
- abrir el recurso de resolución de un reto programado;
- publicar automáticamente en GitHub Pages.

## Arquitectura vigente

```text
Flutter Web
  ├── domain: modelos y motores puros
  ├── data: DTO, validadores y repositorios
  ├── features: controladores y pantallas
  ├── content: bancos JSON publicables
  └── shared_preferences: estado local pequeño
```

## Persistencia implementada

Se guardan localmente:

```text
mision_admision.daily_attempt.v1
mision_admision.learner_progress.v1
```

El intento diario contiene el reto, orden de preguntas, respuestas, índice y hora de inicio. El progreso contiene racha actual, mejor racha, última fecha completada y total de retos terminados.

## Regla diaria implementada

```text
Si existe reto programado para la fecha local:
    usarlo.

Si no existe:
    seleccionar 10 preguntas con una semilla estable basada en YYYY-MM-DD.

Si existe intento guardado del mismo día:
    restaurarlo.

Si el intento corresponde a otro día:
    eliminarlo.

Si el reto se termina después de medianoche:
    no contar la racha y eliminar el intento vencido.
```

## Límites conscientes de esta versión

- La racha todavía no aplica escudos.
- No hay cards ni filtros de recursos.
- El contenido todavía se carga desde assets incluidos en el build.
- No existe sincronización remota con `index.json`.
- No se ha incorporado Firebase Cloud Messaging.
- No existe exportación o importación del progreso.

## Siguiente bloque recomendado

1. Agregar escudos y rangos.
2. Incorporar cards de recursos y filtros.
3. Implementar sincronización remota segura con última versión válida.
4. Completar caché PWA y funcionamiento offline.
5. Integrar una notificación diaria mediante FCM.
