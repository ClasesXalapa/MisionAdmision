# Misión Admisión — Punto de control v6.0

**Fecha:** 15 de julio de 2026  
**Versión técnica:** 0.3.0  
**Plataforma inicial:** Flutter Web / PWA en GitHub Pages

## Estado actual

La base web permite:

- cargar y validar el banco de preguntas;
- realizar exámenes libres;
- resolver retos programados o automáticos;
- guardar y reanudar el reto del mismo día;
- registrar racha y mejor racha;
- ganar un escudo cada 7 días, con máximo de 3;
- consumir escudos automáticamente al omitir días;
- conservar rangos basados en la mejor racha;
- mostrar cards de recursos con filtros;
- registrar recursos vistos y completados;
- publicar automáticamente en GitHub Pages.

## Persistencia

```text
mision_admision.daily_attempt.v1
mision_admision.learner_progress.v1
mision_admision.resource_tracking.v1
```

El progreso anterior se migra automáticamente. Los nuevos campos son:

```text
shields
last_streak_date_key
last_shield_used_date_key
last_shield_use_count
```

## Regla de escudos

```text
Cada múltiplo de 7 días completados consecutivos:
    entregar 1 escudo si hay menos de 3.

Por cada día omitido:
    consumir 1 escudo automáticamente.

Si alcanzan los escudos:
    conservar la racha.

Si no alcanzan:
    consumir los disponibles y reiniciar la racha.
```

## Rangos

Los rangos usan `bestStreak`, no la racha actual. Por ello no bajan cuando una racha se reinicia.

## Cards

Las cards admiten videos, PDF, formularios, simulacros, publicaciones y anuncios. Se filtran por tipo y etiqueta; la apertura y el estado completado se guardan localmente.

## Límites conscientes

- El contenido sigue incluido dentro del build.
- No hay sincronización remota desde `index.json`.
- No hay exportación ni importación del progreso.
- No se ha completado el caché PWA offline personalizado.
- No se ha incorporado FCM.

## Siguiente bloque recomendado

1. Sincronización remota segura con última versión válida.
2. Almacenamiento local de copias válidas del contenido.
3. Botón de actualización y estados offline.
4. Service worker PWA y caché controlado.
5. Notificación diaria mediante FCM.
