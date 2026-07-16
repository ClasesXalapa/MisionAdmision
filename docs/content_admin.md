# Administración de contenido con Excel o Google Sheets

Misión Admisión 0.8.0 permite administrar preguntas, retos, cards y rangos sin editar JSON manualmente.

## Archivos incluidos

```text
admin/
├── Plantilla_Contenido_Mision_Admision_v0.8.0.xlsx
├── csv_samples/
│   ├── preguntas.csv
│   ├── retos.csv
│   ├── cards.csv
│   ├── rangos.csv
│   └── config.csv
└── google_sheets/
    └── Code.gs

tool/generate_content_from_csv.py
```

Los CSV de ejemplo contienen el mismo contenido demostrativo que la aplicación: 20 preguntas, 1 reto, 6 cards y 6 rangos. Por eso se pueden validar inmediatamente.

## Flujo recomendado con Excel

1. Duplica `admin/Plantilla_Contenido_Mision_Admision_v0.8.0.xlsx`.
2. Edita las hojas `Preguntas`, `Retos`, `Cards`, `Rangos` y `Config`.
3. Exporta cada hoja como **CSV UTF-8** usando exactamente estos nombres:

```text
preguntas.csv
retos.csv
cards.csv
rangos.csv
config.csv
```

4. Coloca los cinco CSV dentro de una misma carpeta.
5. Desde la raíz del proyecto, valida sin modificar nada:

```bash
python3 tool/generate_content_from_csv.py ruta/a/la/carpeta --check-only
```

6. Si la validación termina correctamente, publica los JSON:

```bash
python3 tool/generate_content_from_csv.py ruta/a/la/carpeta
```

7. Revisa los cambios con Git y súbelos:

```bash
git status
git diff -- content
git add content
git commit -m "Actualizar contenido educativo"
git push
```

## Seguridad del generador

El generador realiza todo este proceso antes de reemplazar archivos:

```text
Leer los cinco CSV
→ comprobar encabezados y tipos
→ construir los cinco documentos
→ validar preguntas, retos, cards, rangos e index juntos
→ preparar archivos temporales
→ reemplazar los JSON
```

Si existe cualquier error, no reemplaza ningún archivo publicado. También intenta restaurar el contenido anterior si ocurre un fallo de escritura durante la publicación.

Detecta, entre otros casos:

- archivos o encabezados faltantes;
- CSV que no están en UTF-8;
- IDs duplicados;
- menos de 10 preguntas activas;
- opciones vacías;
- respuestas diferentes de A, B, C o D;
- dificultad inválida;
- URLs sin HTTPS;
- fechas inválidas;
- retos con preguntas inexistentes o repetidas;
- cards con prioridad inválida;
- rangos repetidos o sin rango inicial en 0;
- versiones inválidas o inconsistentes.

## Columnas y reglas

### Preguntas

| Columna | Regla |
|---|---|
| `id` | Único y permanente. No reutilizar. |
| `enunciado` | Texto obligatorio. |
| `imagen_url` | Vacío o URL HTTPS. |
| `opcion_a` a `opcion_d` | Exactamente cuatro opciones no vacías. |
| `respuesta_correcta` | A, B, C o D. |
| `categoria` | Texto no vacío. |
| `etiquetas` | Una o más, separadas con `;`. |
| `dificultad` | `basico`, `intermedio` o `avanzado`. |
| `activa` | `SI` publica; `NO` conserva sin publicar. |

### Retos

| Columna | Regla |
|---|---|
| `id` | Único. |
| `fecha` | `YYYY-MM-DD`; una fecha por reto. |
| `preguntas_ids` | IDs existentes separados con `;`. |
| `recurso_url` | URL HTTPS obligatoria. |
| `activo` | `SI` o `NO`. |

### Cards

| Columna | Regla |
|---|---|
| `tipo` | `video`, `pdf`, `formulario`, `simulacro`, `publicacion` o `anuncio`. |
| `url` | HTTPS obligatoria. |
| `imagen_url` | Vacío o HTTPS. |
| `prioridad` | Entero igual o mayor que 0. |
| `fecha_publicacion` | `YYYY-MM-DD`. |
| `activa` | `SI` o `NO`. |

### Rangos

- `racha_minima` debe ser un entero no negativo.
- No puede repetirse.
- Debe existir un rango con `racha_minima` igual a `0`.

### Config

Antes de cada publicación cambia las versiones de los archivos modificados y `content_version`.

Ejemplo:

```text
questions_001 → questions_002
2026_07_004 → 2026_07_005
```

`generated_at` puede dejarse vacío; el generador utilizará la hora de Ciudad de México.

## Google Sheets

1. Sube la plantilla a Google Drive y ábrela con Google Sheets.
2. Abre **Extensiones → Apps Script**.
3. Copia `admin/google_sheets/Code.gs`.
4. Guarda el proyecto y recarga la hoja.
5. Aparecerá el menú **Misión Admisión**.
6. Ejecuta primero **Validar contenido**.
7. Después ejecuta **Generar JSON en Drive**.

El script crea una carpeta con la estructura `content/`. Antes de publicar esos archivos, colócalos en el proyecto y ejecuta:

```bash
python3 tool/validate_content.py
```

El generador Python es la ruta recomendada porque ejecuta el mismo validador que GitHub Actions.
