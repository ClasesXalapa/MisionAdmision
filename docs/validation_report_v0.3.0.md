# Reporte de validación — v0.3.0

## Comprobaciones ejecutadas en este entorno

- Lectura de todos los JSON del proyecto.
- Validación de 20 preguntas.
- Validación de 1 reto programado.
- Validación de 6 cards activas.
- Validación de 6 rangos.
- IDs únicos, fechas estrictas y URLs HTTPS.
- Integridad entre retos y preguntas.
- Tipos y prioridades de recursos.
- Umbrales únicos de rangos y rango inicial en cero.
- Sintaxis de los workflows YAML.
- Resolución de imports internos del paquete.
- Existencia de los assets declarados.
- Balance estructural de delimitadores en 76 archivos Dart de `lib` y 13 archivos Dart de pruebas.
- Compilación sintáctica del validador Python.
- Ausencia de marcadores `TODO` y `FIXME` en el código de producción.

Resultado del validador:

```text
Contenido válido: 20 preguntas, 1 retos, 6 cards activas y 6 rangos.
```

Resultado de la revisión estructural:

```text
Structural checks passed: 76 lib Dart files, 13 test Dart files.
```

## Compatibilidad local

La lectura de `learner_progress.v1` admite datos creados por v0.2.0. Si faltan los campos nuevos, se inicializan con valores seguros y la última fecha completada se utiliza como ancla de continuidad.

## Comprobaciones delegadas a GitHub Actions

Este entorno no incluye Flutter ni Dart. Por ello no se afirma haber ejecutado localmente:

```text
flutter analyze
flutter test
flutter build web
```

Al subir el proyecto, los workflows ejecutan el formateador, analizador, validador de contenido, pruebas y build web antes del despliegue.

## Contenido demostrativo

Las URLs de `cards_actuales.json` y del reto de demostración deben sustituirse por recursos reales antes de publicar a alumnos.
