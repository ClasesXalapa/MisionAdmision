# Misión Admisión — MVP web v0.10.11

PWA educativa en Flutter Web para aspirantes al EXANI-II. Vive en GitHub Pages, funciona sin cuentas, conserva el progreso local y distribuye contenido mediante JSON validados.

## Funciones incluidas

- Examen libre aleatorio de 10 preguntas.
- Preguntas e incisos con imágenes opcionales, ampliación y zoom.
- Reto diario programado y reto automático estable.
- Guardado y reanudación del intento durante el mismo día.
- Racha, récord, escudos y rangos.
- Biblioteca de recursos con filtros y seguimiento local.
- Interfaz mobile-first con navegación inferior y controles táctiles ampliados.
- Búsqueda y filtros móviles en la biblioteca de recursos.
- Sincronización remota segura desde `content/index.json`.
- Última copia válida de contenido como respaldo.
- Instalación como PWA y caché offline versionada.
- Actualización controlada de la aplicación.
- Firebase Cloud Messaging desde Firebase Console con recordatorios locales condicionados al reto pendiente.
- Código de exportación e importación del progreso conservado, temporalmente fuera de la navegación.
- Administrador de contenido mediante Excel, Google Sheets o CSV.
- Código de ayuda y diagnóstico conservado, temporalmente fuera de la navegación.
- Generación y validación segura de los JSON públicos.
- Publicación automática en GitHub Pages.
- Sin límite local de recordatorios: cada campaña Firebase puede reforzar la racha mientras el reto siga pendiente.

## Requisitos

- Flutter 3.44 o compatible.
- Dart 3.10 o posterior.
- Python 3.11 o posterior para validadores y generadores.
- Node.js para comprobar los puentes Web.
- HTTPS o `localhost` para PWA y Web Push.

## Ejecutar localmente

```bash
flutter pub get
python3 tool/validate_content.py
python3 tool/validate_project.py
python3 tool/generate_content_from_csv.py admin/csv_samples --check-only
python3 -m unittest discover -s tool/tests -v
node tool/validate_firebase_config.js
node tool/test_notification_state_store.js
node tool/test_notifications_bridge.js
node tool/test_fcm_service_worker.js
node tool/test_pwa_bridge.js
node tool/test_backup_bridge.js
node tool/test_diagnostics_bridge.js
flutter test
flutter run -d chrome
```

Firebase Web Push está configurado para el proyecto actual, pero la aplicación conserva una degradación segura: el contenido, la práctica y el progreso local siguen funcionando si Firebase no está disponible.

## Administrar contenido

La plantilla editable está en:

```text
admin/Plantilla_Contenido_Mision_Admision_v0.8.0.xlsx
```

Para validar una carpeta de CSV sin reemplazar contenido:

```bash
python3 tool/generate_content_from_csv.py ruta/a/csv --check-only
```

Para generar y publicar los JSON en `content/`:

```bash
python3 tool/generate_content_from_csv.py ruta/a/csv
```

Consulta [docs/content_admin.md](docs/content_admin.md).

## Construir la PWA

```bash
flutter build web --release --pwa-strategy=none
mkdir -p build/web/content
cp -R content/. build/web/content/
python3 tool/prepare_pwa.py build/web
python3 -m http.server 8000 --directory build/web
```

## Publicar en GitHub Pages

1. Sube el proyecto a `main`.
2. En **Settings → Pages**, selecciona **GitHub Actions**.
3. El workflow valida código, contenido, generador y pruebas.
4. La ruta base se calcula automáticamente.
5. La PWA y los JSON se publican en GitHub Pages.

## Documentación

- [Administración de contenido](docs/content_admin.md)
- [Contratos JSON](docs/json_contracts.md)
- [Configuración opcional de Firebase](docs/firebase_notifications_setup.md)
- [Respaldo del progreso](docs/progress_backup.md)
- [Accesibilidad](docs/accessibility.md)
- [Ayuda y diagnóstico](docs/support_diagnostics.md)
- [Contexto técnico v16](docs/contexto_v16_web_mvp_v0.9.8.md)
- [Privacidad y Analytics](docs/privacy.md)
- [Arquitectura del cliente de notificaciones](docs/notification_client_architecture.md)
