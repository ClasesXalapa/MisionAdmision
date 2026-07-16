# Reporte de validación — Misión Admisión v0.9.0

## Alcance

Auditoría y cierre del cliente Firebase Web Push basado en Firebase Installation ID.

## Resultado estructural

```text
Versión: 0.9.0+12
Código Dart de producción: 126 archivos
Archivos Dart de pruebas: 23
Declaraciones test/testWidgets: 69
Preguntas: 20
Retos programados: 1
Cards activas: 6
Rangos: 6
```

## Comprobaciones aprobadas

- Coherencia entre `pubspec.yaml` y `AppConstants`.
- Resolución de imports internos.
- Validez de todos los JSON.
- Validez de workflows YAML.
- Validación del contenido educativo.
- Pruebas Python del generador de contenido.
- Pruebas Python del generador PWA.
- Generación CSV en modo `--check-only`.
- Sintaxis JavaScript de configuración, puentes y service worker.
- Configuración Firebase desactivada válida.
- Configuración Firebase ficticia activada válida.
- Ciclo FID simulado: alta, renovación, prueba y baja.
- Detección de instalación PWA obligatoria en iPhone.
- Manejo de mensajes de datos en segundo plano.
- Rechazo de enlaces de notificación externos.
- Clic de notificación limitado a la ruta de la PWA.
- Ausencia de cuentas de servicio, claves privadas y correos IAM.
- Integridad del archivo ZIP.

## Seguridad

El cliente solo incluye configuración pública de Firebase. El FID:

- permanece local en esta entrega;
- no se incluye en respaldos;
- no se incluye en diagnósticos;
- no se muestra en la interfaz;
- solo podrá enviarse al backend explícito de la entrega 0.9.1.

## Limitaciones de esta validación

Este entorno no contiene el SDK de Flutter. Por ello no se ejecutaron localmente:

```text
dart format
flutter analyze
flutter test
flutter build web
```

Los workflows incluidos ejecutarán esas comprobaciones reales antes de publicar GitHub Pages. No se realizó una recepción FCM real porque todavía no existe la configuración Firebase definitiva del usuario.
