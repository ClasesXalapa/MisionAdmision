# Reporte de validación — Misión Admisión v0.9.1

## Alcance

Firebase Console Edition sin backend propio.

## Cambios revisados

- Eliminación de referencias funcionales a Cloudflare/D1/backend futuro.
- Reemplazo de `getRegistrationSnapshotForBackend` por `getTestingInstallationId`.
- Nuevo acceso Dart al FID técnico.
- Copia mediante portapapeles iniciada por el usuario.
- `notificationclick` situado antes de los imports de Firebase.
- Clic de mensajes automáticos FCM y mensajes locales.
- Enlaces internos seguros.
- Textos de interfaz actualizados.
- Documentación de Firebase Console.

## Comprobaciones automatizadas incluidas

- Validador de contenido.
- Validador estructural del proyecto.
- Configuración Firebase desactivada.
- Prueba Node del registro FID.
- Prueba Node del service worker y orden del clic.
- Sintaxis JavaScript.
- Pruebas Dart del controlador y servicios.

## Resultado estructural

```text
Versión: 0.9.1+13
Código Dart de producción: 126 archivos
Archivos Dart de pruebas: 23
Declaraciones test/testWidgets: 70
Preguntas: 20
Retos programados: 1
Cards activas: 6
Rangos: 6
```

## Limitación del entorno

Este entorno no incluye Flutter SDK. GitHub Actions confirmará `dart format`, `flutter analyze`, `flutter test` y `flutter build web` antes del despliegue.
