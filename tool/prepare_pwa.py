#!/usr/bin/env python3
"""Prepara el service worker de Misión Admisión después de flutter build web."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
from typing import Iterable

EXCLUDED_NAMES = {
    ".nojekyll",
    "app_service_worker.js",
    "flutter_service_worker.js",
}
EXCLUDED_SUFFIXES = {
    ".map",
}
REQUIRED_FILES = {
    "index.html",
    "offline.html",
    "manifest.json",
    "flutter_bootstrap.js",
    "main.dart.js",
    "pwa_bridge.js",
    "firebase_config.js",
    "notifications_bridge.js",
    "notification_state_store.js",
    "backup_bridge.js",
    "diagnostics_bridge.js",
}


def _relative_files(build_dir: Path) -> list[Path]:
    files: list[Path] = []
    for path in build_dir.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(build_dir)
        if relative.name in EXCLUDED_NAMES:
            continue
        if relative.suffix in EXCLUDED_SUFFIXES:
            continue
        files.append(relative)
    return sorted(files, key=lambda value: value.as_posix())


def _build_version(build_dir: Path, files: Iterable[Path]) -> str:
    digest = hashlib.sha256()
    for relative in files:
        digest.update(relative.as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update((build_dir / relative).read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()[:20]


def prepare(build_dir: Path, template_path: Path) -> dict[str, object]:
    if not build_dir.is_dir():
        raise ValueError(f"No existe el directorio de compilación: {build_dir}")
    if not template_path.is_file():
        raise ValueError(f"No existe la plantilla del service worker: {template_path}")

    missing = sorted(
        name for name in REQUIRED_FILES if not (build_dir / name).is_file()
    )
    if missing:
        raise ValueError(
            "Faltan archivos necesarios en build/web: " + ", ".join(missing)
        )

    initial_files = _relative_files(build_dir)
    version = _build_version(build_dir, initial_files)

    metadata = {
        "version": version,
        "app_shell_files": 0,
        "content_files": 0,
    }
    metadata_path = build_dir / "pwa_build.json"
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    files = _relative_files(build_dir)
    content_assets = [
        path.as_posix() for path in files if path.as_posix().startswith("content/")
    ]
    app_shell = [
        path.as_posix() for path in files if not path.as_posix().startswith("content/")
    ]

    metadata = {
        "version": version,
        "app_shell_files": len(app_shell),
        "content_files": len(content_assets),
    }
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    template = template_path.read_text(encoding="utf-8")
    replacements = {
        "__BUILD_VERSION__": version,
        "__APP_SHELL__": json.dumps(app_shell, ensure_ascii=False, indent=2),
        "__CONTENT_ASSETS__": json.dumps(
            content_assets,
            ensure_ascii=False,
            indent=2,
        ),
    }
    generated = template
    for marker, value in replacements.items():
        if marker not in generated:
            raise ValueError(f"La plantilla no contiene el marcador {marker}")
        generated = generated.replace(marker, value)

    unresolved = [marker for marker in replacements if marker in generated]
    if unresolved:
        raise ValueError("Quedaron marcadores sin reemplazar: " + ", ".join(unresolved))

    (build_dir / "app_service_worker.js").write_text(
        generated,
        encoding="utf-8",
    )
    (build_dir / ".nojekyll").touch()
    return metadata


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "build_dir",
        nargs="?",
        default="build/web",
        type=Path,
    )
    parser.add_argument(
        "--template",
        default=Path("web/app_service_worker.js"),
        type=Path,
    )
    args = parser.parse_args()

    try:
        metadata = prepare(args.build_dir, args.template)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Error preparando PWA: {error}", file=sys.stderr)
        return 1

    print(
        "PWA preparada: "
        f"versión {metadata['version']}, "
        f"{metadata['app_shell_files']} archivos de aplicación y "
        f"{metadata['content_files']} archivos de contenido."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
