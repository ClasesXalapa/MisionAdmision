# Contratos JSON — v0.10.8

El índice, retos, recursos y rangos utilizan `schema_version: 1`. El banco de preguntas utiliza `schema_version: 2`; la aplicación conserva compatibilidad de lectura con bancos de preguntas de esquema 1.

## `content/index.json`

Campos obligatorios:

```json
{
  "schema_version": 1,
  "content_version": "2026_07_005",
  "generated_at": "2026-07-15T18:00:00-06:00",
  "min_app_version": 31,
  "files": {
    "questions": {
      "url": "content/preguntas/banco_global.json",
      "version": "questions_002",
      "required": true
    },
    "challenges": {
      "url": "content/retos/retos_actuales.json",
      "version": "challenges_001",
      "required": false
    },
    "resources": {
      "url": "content/cards/cards_actuales.json",
      "version": "cards_001",
      "required": false
    },
    "ranks": {
      "url": "content/config/rangos.json",
      "version": "ranks_001",
      "required": false
    }
  }
}
```

Reglas:

- Debe declarar los cuatro archivos conocidos.
- `questions.required` debe ser `true`.
- Las rutas relativas se resuelven desde la raíz de la PWA.
- Las rutas absolutas deben usar HTTPS.
- No se aceptan segmentos `..`.
- `min_app_version` se compara con el build de la aplicación.
- Cambiar un documento exige cambiar también su versión en el índice.

## Banco global de preguntas

Ruta: `content/preguntas/banco_global.json`.

Cada pregunta requiere ID único, enunciado, cuatro posiciones de opción, cuatro posiciones de imagen, respuesta A/B/C/D, categoría, etiquetas y dificultad. `imagen_url` permite una imagen principal HTTPS. `imagenes_opciones` permite una imagen HTTPS independiente para A, B, C y D. Cada inciso debe contener texto, imagen o ambos.

## Retos programados

Ruta: `content/retos/retos_actuales.json`.

Cada reto requiere ID, fecha `YYYY-MM-DD`, título, preguntas no repetidas y recurso HTTPS de resolución. Durante la sincronización, todos sus IDs se comparan contra el banco efectivo de preguntas.

## Cards de recursos

Ruta: `content/cards/cards_actuales.json`.

Tipos admitidos:

```text
video
pdf
formulario
simulacro
publicacion
anuncio
```

Las cards inactivas se validan, pero no aparecen en la aplicación.

## Rangos

Ruta: `content/config/rangos.json`.

Los IDs y umbrales deben ser únicos, los umbrales no pueden ser negativos y debe existir un rango inicial con `racha_minima: 0`.

## Validación local

```bash
python3 tool/validate_content.py
```

## Respaldo local del progreso

La versión 0.7.0 incorpora `schemas/progress_backup.schema.json`. Este contrato es independiente del contenido remoto: describe únicamente archivos que el alumno descarga e importa desde la sección **Datos y respaldo**.

Reglas adicionales aplicadas por la aplicación, además del JSON Schema:

- máximo 512 KB;
- ninguna fecha de progreso puede estar en el futuro;
- los recursos completados deben formar parte de los recursos vistos;
- el total de retos no puede ser menor que la racha actual o la mejor racha;
- un intento futuro se rechaza y un intento vencido se descarta;
- la importación intenta restaurar el estado anterior si una escritura falla.
