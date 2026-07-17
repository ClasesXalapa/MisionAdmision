#!/usr/bin/env python3
"""Comprueba coherencia estructural sin depender del SDK de Flutter."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    errors: list[str] = []

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    constants = (ROOT / "lib/core/constants/app_constants.dart").read_text(
        encoding="utf-8"
    )
    pubspec_match = re.search(r"^version:\s*([0-9.]+)\+([0-9]+)\s*$", pubspec, re.M)
    app_version_match = re.search(r"appVersion\s*=\s*'([^']+)'", constants)
    build_match = re.search(r"appBuildNumber\s*=\s*(\d+)", constants)
    if not pubspec_match or not app_version_match or not build_match:
        errors.append("No fue posible leer la versión de la aplicación.")
    else:
        if pubspec_match.group(1) != app_version_match.group(1):
            errors.append("pubspec.yaml y AppConstants.appVersion no coinciden.")
        if pubspec_match.group(2) != build_match.group(1):
            errors.append("pubspec.yaml y AppConstants.appBuildNumber no coinciden.")

    for path in ROOT.rglob("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"JSON inválido en {path.relative_to(ROOT)}: {error}")

    import_pattern = re.compile(r"import 'package:mision_admision/([^']+)';")
    for path in [*ROOT.joinpath("lib").rglob("*.dart"), *ROOT.joinpath("test").rglob("*.dart")]:
        text = path.read_text(encoding="utf-8")
        for match in import_pattern.finditer(text):
            target = ROOT / "lib" / match.group(1)
            if not target.is_file():
                errors.append(
                    f"Import inexistente en {path.relative_to(ROOT)}: "
                    f"{target.relative_to(ROOT)}"
                )

    index_html = (ROOT / "web/index.html").read_text(encoding="utf-8")
    required_web_files = {
        "firebase_config.js",
        "notifications_bridge.js",
        "notification_state_store.js",
        "backup_bridge.js",
        "diagnostics_bridge.js",
        "pwa_bridge.js",
        "flutter_bootstrap.js",
    }
    loaded_web_files = {
        "firebase_config.js",
        "notifications_bridge.js",
        "notification_state_store.js",
        "pwa_bridge.js",
        "flutter_bootstrap.js",
    }
    for name in sorted(required_web_files):
        if not (ROOT / "web" / name).is_file():
            errors.append(f"Falta web/{name}.")
    for name in sorted(loaded_web_files):
        script_pattern = re.compile(
            rf'src="{re.escape(name)}(?:\?[^"]*)?"'
        )
        if not script_pattern.search(index_html):
            errors.append(f"web/index.html no carga {name}.")


    flutter_bootstrap = (ROOT / "web/flutter_bootstrap.js").read_text(encoding="utf-8")
    for token in ("{{flutter_js}}", "{{flutter_build_config}}", "_flutter.loader.load()"):
        if token not in flutter_bootstrap:
            errors.append(f"web/flutter_bootstrap.js no contiene {token}.")
    if "serviceWorkerSettings" in flutter_bootstrap:
        errors.append(
            "web/flutter_bootstrap.js no debe registrar el service worker de Flutter."
        )

    deploy_workflow = (ROOT / ".github/workflows/deploy-pages.yml").read_text(
        encoding="utf-8"
    )
    if "--pwa-strategy=none" not in deploy_workflow:
        errors.append(
            "El workflow de Pages debe desactivar el service worker generado por Flutter."
        )
    if "rm -f build/web/flutter_service_worker.js" not in deploy_workflow:
        errors.append(
            "El workflow de Pages debe retirar flutter_service_worker.js del artefacto."
        )

    required_docs = {
        "docs/progress_backup.md",
        "docs/accessibility.md",
        "docs/beta_checklist.md",
        "docs/content_admin.md",
        "docs/contexto_v11_web_mvp_v0.8.md",
        "docs/support_diagnostics.md",
        "docs/contexto_v12_web_mvp_v0.8.1.md",
        "docs/contexto_v13_web_mvp_v0.9.0.md",
        "docs/contexto_v14_web_mvp_v0.9.1.md",
        "docs/contexto_v15_web_mvp_v0.9.3.md",
        "docs/privacy.md",
        "docs/notification_client_architecture.md",
        "docs/validation_report_v0.9.1.md",
        "docs/validation_report_v0.9.3.md",
        "schemas/progress_backup.schema.json",
        "admin/Plantilla_Contenido_Mision_Admision_v0.8.0.xlsx",
        "admin/csv_samples/preguntas.csv",
        "admin/csv_samples/retos.csv",
        "admin/csv_samples/cards.csv",
        "admin/csv_samples/rangos.csv",
        "admin/csv_samples/config.csv",
        "admin/google_sheets/Code.gs",
        "tool/generate_content_from_csv.py",
        "tool/test_diagnostics_bridge.js",
        "tool/test_fcm_service_worker.js",
    }
    for relative in sorted(required_docs):
        if not (ROOT / relative).is_file():
            errors.append(f"Falta {relative}.")

    if errors:
        print("Proyecto inválido:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    dart_files = len(list((ROOT / "lib").rglob("*.dart")))
    test_files = len(list((ROOT / "test").rglob("*.dart")))
    print(
        "Proyecto coherente: "
        f"versión {pubspec_match.group(1)}+{pubspec_match.group(2)}, "
        f"{dart_files} archivos Dart y {test_files} archivos de prueba."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
