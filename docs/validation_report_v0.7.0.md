# Reporte de validación — Misión Admisión v0.7.0

## Resultado

La versión 0.7.0 quedó preparada estructuralmente para compilación y despliegue mediante GitHub Actions.

## Comprobaciones ejecutadas en este entorno

- `python3 tool/validate_content.py`:
  - 20 preguntas válidas;
  - 1 reto programado válido;
  - 6 cards activas válidas;
  - 6 rangos válidos;
  - relaciones entre retos y preguntas correctas.
- `python3 tool/validate_project.py`:
  - versión coherente `0.7.0+7`;
  - imports internos existentes;
  - archivos Web y documentos requeridos presentes;
  - 118 archivos Dart de producción;
  - 20 archivos Dart de pruebas.
- Dos pruebas Python del generador PWA aprobadas.
- Sintaxis JavaScript válida para Firebase, PWA, service worker y respaldo.
- Configuración Firebase desactivada validada correctamente.
- Puente de notificaciones validado en modo desactivado.
- Puente de descarga de respaldo validado con Node.
- 12 archivos JSON decodificados correctamente, incluido el nuevo JSON Schema.
- Workflows YAML decodificados correctamente en la revisión estructural.
- Delimitadores e imports de los archivos Dart revisados estructuralmente.

## Pruebas agregadas

El proyecto contiene 66 declaraciones de prueba. La versión agrega seis casos para:

- ida y vuelta de exportación y decodificación;
- rechazo de formatos desconocidos;
- restauración del reto pendiente del día actual;
- descarte de un intento vencido;
- rechazo de un intento futuro;
- reinicio de progreso, seguimiento e intento.

## Límites de la validación

Este entorno no contiene el SDK de Flutter ni Dart. Por ello no se ejecutaron localmente:

```text
flutter pub get
flutter analyze
flutter test
flutter build web
```

Los workflows incluidos ejecutan esos comandos al subir el proyecto a GitHub. También queda pendiente probar manualmente el selector de archivos en navegadores móviles, la compilación real de `dart:js_interop` y un envío remoto de Firebase Cloud Messaging con la configuración definitiva.

## Conclusión

No se encontraron errores en las validaciones disponibles. La compilación Flutter y las pruebas automatizadas reales deben confirmarse en GitHub Actions antes de publicar la beta.
