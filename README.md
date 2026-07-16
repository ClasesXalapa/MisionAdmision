# Misión Admisión — Séptimo bloque funcional

PWA en Flutter Web para aspirantes al EXANI-II. La versión 0.7.0 agrega respaldo, restauración y reinicio del progreso, además de una primera revisión de accesibilidad y preparación para beta.

## Funciones incluidas

- Examen libre aleatorio de 10 preguntas.
- Reto diario programado y reto automático estable.
- Guardado y reanudación del intento durante el mismo día.
- Racha, récord, escudos y rangos.
- Biblioteca de recursos con filtros y seguimiento local.
- Sincronización remota validada desde `content/index.json`.
- Última copia válida de contenido como respaldo.
- Instalación como PWA y caché offline versionada.
- Actualización controlada de la aplicación.
- Integración opcional con Firebase Cloud Messaging.
- Exportación e importación del progreso mediante JSON.
- Reinicio selectivo de los datos del alumno.
- Tema de alto contraste y mejoras semánticas.
- Publicación automática en GitHub Pages.

## Requisitos

- Flutter 3.44 o compatible.
- Dart 3.10 o posterior.
- Chrome o Edge para desarrollo web.
- HTTPS o `localhost` para service workers y notificaciones.
- Proyecto Firebase únicamente cuando se quiera activar FCM.

## Ejecutar localmente

```bash
flutter pub get
python3 tool/validate_content.py
node tool/validate_firebase_config.js
node tool/test_notifications_bridge.js
node tool/test_backup_bridge.js
python3 -m unittest discover -s tool/tests -v
flutter test
flutter run -d chrome
```

La configuración de Firebase está desactivada por defecto. El proyecto puede compilarse y publicarse antes de crear el proyecto FCM.

## Construir la PWA de producción

```bash
flutter build web --release
mkdir -p build/web/content
cp -R content/. build/web/content/
python3 tool/prepare_pwa.py build/web
python3 -m http.server 8000 --directory build/web
```

Después abre `http://localhost:8000`. No uses `file://` porque los service workers y Web Push requieren un origen seguro.

## Publicar en GitHub Pages

1. Sube el proyecto a la rama `main`.
2. En **Settings → Pages**, selecciona **GitHub Actions**.
3. El workflow valida, prueba, construye y publica.
4. La ruta base se calcula automáticamente.
5. `tool/prepare_pwa.py` genera el service worker final después del build.

## Respaldo del progreso

La sección **Datos y respaldo** permite:

- descargar un archivo `mision-admision-progreso-AAAA-MM-DD.json`;
- revisar un respaldo antes de restaurarlo;
- recuperar racha, escudos, reto pendiente y cards marcadas;
- borrar únicamente el progreso local.

El respaldo no incluye Firebase, permisos, caché ni información personal. Consulta [docs/progress_backup.md](docs/progress_backup.md).

## Notificaciones

La integración usa:

```text
web/firebase_config.js
web/notifications_bridge.js
web/app_service_worker.js
```

No se agrega una cuenta de servicio ni credenciales privadas a GitHub Pages. Consulta [docs/firebase_notifications_setup.md](docs/firebase_notifications_setup.md).

## Contenido

```text
content/
├── index.json
├── preguntas/banco_global.json
├── retos/retos_actuales.json
├── cards/cards_actuales.json
└── config/rangos.json
```

Para publicar contenido nuevo:

1. Modifica el JSON correspondiente.
2. Cambia su versión interna.
3. Actualiza la versión en `content/index.json`.
4. Incrementa `content_version`.
5. Ejecuta `python3 tool/validate_content.py`.
6. Sube los cambios a GitHub.

> Las URLs de demostración deben sustituirse antes del lanzamiento.

## Persistencia local

```text
mision_admision.daily_attempt.v1
mision_admision.learner_progress.v1
mision_admision.resource_tracking.v1
mision_admision.content_cache.metadata.v1
mision_admision.content_cache.<tipo>.v1.<version>
mision_admision.notifications_enabled.v1
mision_admision.fcm_installation_id.v1
```

## Documentos de preparación

- [Respaldo del progreso](docs/progress_backup.md)
- [Accesibilidad](docs/accessibility.md)
- [Lista para beta](docs/beta_checklist.md)
- [Contexto técnico v10](docs/contexto_v10_web_mvp_v0.7.md)
