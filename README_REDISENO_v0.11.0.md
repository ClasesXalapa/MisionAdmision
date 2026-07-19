# Entrega de rediseño móvil — v0.11.0+41

> **Documento histórico:** la escala móvil de esta entrega fue sustituida por `v0.11.1+42`. Consulta `README_ESCALA_MOVIL_v0.11.1.md`.

Esta versión cambia de forma integral la presentación móvil de Misión Admisión sin alterar su arquitectura funcional.

## Pantallas rediseñadas

- Inicio.
- Navegación inferior.
- Configuración.
- Recursos y filtros.
- Reto diario.
- Examen libre.
- Resultados.
- Colores PWA, manifest y página offline.

## Validaciones ejecutadas en esta entrega

Pasaron correctamente:

```text
python3 tool/validate_content.py
python3 tool/validate_project.py
python3 -m unittest discover -s tool/tests -v
python3 tool/generate_content_from_csv.py admin/csv_samples --check-only
node tool/validate_firebase_config.js
node tool/test_notification_state_store.js
node tool/test_notifications_bridge.js
node tool/test_fcm_service_worker.js
node tool/test_pwa_bridge.js
node tool/test_backup_bridge.js
node tool/test_diagnostics_bridge.js
```

El entorno de preparación no incluye Flutter ni Dart, por lo que todavía deben confirmarse en GitHub Actions:

```text
dart format lib test
flutter analyze --no-fatal-infos
flutter test
flutter build web --release --pwa-strategy=none
```

## Primera revisión visual recomendada

1. Publicar el build `0.11.0+41`.
2. Confirmar GitHub Actions verde.
3. Abrir la PWA instalada y permitir la actualización automática.
4. Verificar Inicio, Recursos, Reto, Examen y Configuración en el mismo teléfono de las capturas anteriores.
5. Confirmar que la barra del sistema adopta el nuevo índigo y que no permanece activo el build `+40`.
