#!/usr/bin/env python3
"""Genera y valida los JSON públicos de Misión Admisión desde archivos CSV."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
import json
import os
from pathlib import Path
import sys
import tempfile
from typing import Final
from zoneinfo import ZoneInfo

ROOT: Final = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tool.validate_content import (  # noqa: E402
    validate_bank,
    validate_cards,
    validate_challenges,
    validate_index,
    validate_ranks,
)

MEXICO_CITY: Final = ZoneInfo("America/Mexico_City")

CSV_COLUMNS: Final[dict[str, tuple[str, ...]]] = {
    "preguntas.csv": (
        "id",
        "enunciado",
        "imagen_url",
        "opcion_a",
        "opcion_b",
        "opcion_c",
        "opcion_d",
        "respuesta_correcta",
        "categoria",
        "etiquetas",
        "dificultad",
        "activa",
    ),
    "retos.csv": (
        "id",
        "fecha",
        "titulo",
        "preguntas_ids",
        "recurso_tipo",
        "recurso_titulo",
        "recurso_url",
        "activo",
    ),
    "cards.csv": (
        "id",
        "titulo",
        "descripcion",
        "tipo",
        "url",
        "imagen_url",
        "etiquetas",
        "prioridad",
        "fecha_publicacion",
        "activa",
    ),
    "rangos.csv": (
        "id",
        "nombre",
        "descripcion",
        "racha_minima",
        "activo",
    ),
    "config.csv": ("clave", "valor"),
}

REQUIRED_CONFIG: Final = (
    "content_version",
    "questions_version",
    "challenges_version",
    "cards_version",
    "ranks_version",
    "min_app_version",
)

DOCUMENT_PATHS: Final[dict[str, Path]] = {
    "questions": Path("preguntas/banco_global.json"),
    "challenges": Path("retos/retos_actuales.json"),
    "resources": Path("cards/cards_actuales.json"),
    "ranks": Path("config/rangos.json"),
    "index": Path("index.json"),
}

_TRUE_VALUES: Final = {"1", "true", "si", "sí", "yes", "x", "activo", "activa"}
_FALSE_VALUES: Final = {"0", "false", "no", "n", "inactivo", "inactiva"}


class ContentGenerationError(ValueError):
    """Error entendible para el administrador de contenido."""


def _clean_row(row: dict[str | None, str | None]) -> dict[str, str]:
    if None in row:
        extra = row[None]
        raise ContentGenerationError(
            "Una fila contiene más columnas que el encabezado: "
            f"{extra!r}. Revisa comas y comillas del CSV."
        )
    return {
        str(key).strip(): str(value or "").strip()
        for key, value in row.items()
        if key is not None
    }


def read_rows(input_dir: Path, filename: str) -> list[dict[str, str]]:
    path = input_dir / filename
    if not path.is_file():
        raise ContentGenerationError(f"Falta el archivo {filename} en {input_dir}.")

    try:
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            if reader.fieldnames is None:
                raise ContentGenerationError(f"{filename} no tiene encabezados.")

            headers = tuple(str(value or "").strip() for value in reader.fieldnames)
            expected = CSV_COLUMNS[filename]
            if len(headers) != len(set(headers)):
                raise ContentGenerationError(
                    f"{filename} contiene encabezados duplicados."
                )
            missing = [column for column in expected if column not in headers]
            unexpected = [column for column in headers if column not in expected]
            if missing or unexpected:
                details: list[str] = []
                if missing:
                    details.append(f"faltan: {', '.join(missing)}")
                if unexpected:
                    details.append(f"sobran o están mal escritos: {', '.join(unexpected)}")
                raise ContentGenerationError(
                    f"Encabezados inválidos en {filename} ({'; '.join(details)})."
                )

            result: list[dict[str, str]] = []
            for line_number, raw_row in enumerate(reader, start=2):
                try:
                    row = _clean_row(raw_row)
                except ContentGenerationError as error:
                    raise ContentGenerationError(
                        f"{filename}, fila {line_number}: {error}"
                    ) from error
                if any(row.values()):
                    result.append(row)
            return result
    except UnicodeDecodeError as error:
        raise ContentGenerationError(
            f"{filename} debe exportarse como CSV UTF-8."
        ) from error
    except csv.Error as error:
        raise ContentGenerationError(f"CSV inválido en {filename}: {error}.") from error


def parse_active(value: str, *, filename: str, line_number: int) -> bool:
    normalized = value.strip().lower()
    if not normalized:
        return True
    if normalized in _TRUE_VALUES:
        return True
    if normalized in _FALSE_VALUES:
        return False
    raise ContentGenerationError(
        f"{filename}, fila {line_number}: activo/activa debe ser SI o NO; "
        f"se recibió {value!r}."
    )


def split_values(value: str, *, lowercase: bool) -> list[str]:
    normalized = value.replace("\n", ";").replace(",", ";")
    result: list[str] = []
    seen: set[str] = set()
    for item in normalized.split(";"):
        cleaned = item.strip()
        if lowercase:
            cleaned = cleaned.lower()
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            result.append(cleaned)
    return result


def nullable(value: str) -> str | None:
    cleaned = value.strip()
    return cleaned or None


def parse_integer(
    value: str,
    *,
    field: str,
    filename: str,
    line_number: int,
) -> int:
    if not value.strip():
        raise ContentGenerationError(
            f"{filename}, fila {line_number}: {field} no puede estar vacío."
        )
    try:
        return int(value)
    except ValueError as error:
        raise ContentGenerationError(
            f"{filename}, fila {line_number}: {field} debe ser entero; "
            f"se recibió {value!r}."
        ) from error


def read_config(input_dir: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line_number, row in enumerate(read_rows(input_dir, "config.csv"), start=2):
        key = row["clave"].strip()
        value = row["valor"].strip()
        if not key:
            raise ContentGenerationError(
                f"config.csv, fila {line_number}: clave no puede estar vacía."
            )
        if key in values:
            raise ContentGenerationError(
                f"config.csv, fila {line_number}: clave duplicada {key!r}."
            )
        values[key] = value

    missing = [key for key in REQUIRED_CONFIG if not values.get(key)]
    if missing:
        raise ContentGenerationError(
            "config.csv no contiene valores para: " + ", ".join(missing) + "."
        )
    return values


def build_documents(input_dir: Path) -> dict[str, object]:
    config = read_config(input_dir)
    timestamp = config.get("generated_at") or datetime.now(MEXICO_CITY).isoformat(
        timespec="seconds"
    )

    questions: list[dict[str, object]] = []
    for line_number, row in enumerate(read_rows(input_dir, "preguntas.csv"), start=2):
        if not parse_active(
            row["activa"], filename="preguntas.csv", line_number=line_number
        ):
            continue
        questions.append(
            {
                "id": row["id"],
                "enunciado": row["enunciado"],
                "imagen_url": nullable(row["imagen_url"]),
                "opciones": [
                    row["opcion_a"],
                    row["opcion_b"],
                    row["opcion_c"],
                    row["opcion_d"],
                ],
                "respuesta_correcta": row["respuesta_correcta"].upper(),
                "categoria": row["categoria"].lower(),
                "etiquetas": split_values(row["etiquetas"], lowercase=True),
                "dificultad": row["dificultad"].lower(),
            }
        )

    challenges: list[dict[str, object]] = []
    for line_number, row in enumerate(read_rows(input_dir, "retos.csv"), start=2):
        if not parse_active(
            row["activo"], filename="retos.csv", line_number=line_number
        ):
            continue
        challenges.append(
            {
                "id": row["id"],
                "fecha": row["fecha"],
                "titulo": row["titulo"],
                "preguntas_ids": split_values(
                    row["preguntas_ids"], lowercase=False
                ),
                "recurso_resolucion": {
                    "tipo": row["recurso_tipo"].lower(),
                    "titulo": row["recurso_titulo"],
                    "url": row["recurso_url"],
                },
            }
        )

    cards: list[dict[str, object]] = []
    for line_number, row in enumerate(read_rows(input_dir, "cards.csv"), start=2):
        if not parse_active(
            row["activa"], filename="cards.csv", line_number=line_number
        ):
            continue
        cards.append(
            {
                "id": row["id"],
                "titulo": row["titulo"],
                "descripcion": row["descripcion"],
                "tipo": row["tipo"].lower(),
                "url": row["url"],
                "imagen_url": nullable(row["imagen_url"]),
                "etiquetas": split_values(row["etiquetas"], lowercase=True),
                "prioridad": parse_integer(
                    row["prioridad"],
                    field="prioridad",
                    filename="cards.csv",
                    line_number=line_number,
                ),
                "fecha_publicacion": row["fecha_publicacion"],
                "activa": True,
            }
        )

    ranks: list[dict[str, object]] = []
    for line_number, row in enumerate(read_rows(input_dir, "rangos.csv"), start=2):
        if not parse_active(
            row["activo"], filename="rangos.csv", line_number=line_number
        ):
            continue
        ranks.append(
            {
                "id": row["id"],
                "nombre": row["nombre"],
                "descripcion": row["descripcion"],
                "racha_minima": parse_integer(
                    row["racha_minima"],
                    field="racha_minima",
                    filename="rangos.csv",
                    line_number=line_number,
                ),
            }
        )

    question_bank = {
        "schema_version": 1,
        "version": config["questions_version"],
        "generated_at": timestamp,
        "preguntas": questions,
    }
    challenge_bank = {
        "schema_version": 1,
        "version": config["challenges_version"],
        "generated_at": timestamp,
        "retos": challenges,
    }
    card_bank = {
        "schema_version": 1,
        "version": config["cards_version"],
        "generated_at": timestamp,
        "cards": cards,
    }
    rank_bank = {
        "schema_version": 1,
        "version": config["ranks_version"],
        "generated_at": timestamp,
        "rangos": ranks,
    }
    content_index = {
        "schema_version": 1,
        "content_version": config["content_version"],
        "generated_at": timestamp,
        "min_app_version": parse_integer(
            config["min_app_version"],
            field="min_app_version",
            filename="config.csv",
            line_number=1,
        ),
        "files": {
            "questions": {
                "url": "content/preguntas/banco_global.json",
                "version": config["questions_version"],
                "required": True,
            },
            "challenges": {
                "url": "content/retos/retos_actuales.json",
                "version": config["challenges_version"],
                "required": False,
            },
            "resources": {
                "url": "content/cards/cards_actuales.json",
                "version": config["cards_version"],
                "required": False,
            },
            "ranks": {
                "url": "content/config/rangos.json",
                "version": config["ranks_version"],
                "required": False,
            },
        },
    }
    return {
        "questions": question_bank,
        "challenges": challenge_bank,
        "resources": card_bank,
        "ranks": rank_bank,
        "index": content_index,
    }


def validate_documents(documents: dict[str, object]) -> None:
    bank = documents["questions"]
    challenges = documents["challenges"]
    resources = documents["resources"]
    ranks = documents["ranks"]
    index = documents["index"]

    bank_errors, question_ids = validate_bank(bank)
    errors = (
        bank_errors
        + validate_challenges(challenges, question_ids)
        + validate_cards(resources)
        + validate_ranks(ranks)
        + validate_index(
            index,
            {
                "questions": bank,
                "challenges": challenges,
                "resources": resources,
                "ranks": ranks,
            },
        )
    )
    if errors:
        raise ContentGenerationError(
            "Los CSV no se publicaron porque contienen errores:\n- "
            + "\n- ".join(errors)
        )


def _json_bytes(payload: object) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def publish_documents(documents: dict[str, object], output_dir: Path) -> None:
    output_dir = output_dir.resolve()
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    backups: dict[Path, bytes | None] = {}
    replaced: list[Path] = []

    with tempfile.TemporaryDirectory(
        prefix="mision-admision-content-", dir=output_dir.parent
    ) as temporary:
        staging = Path(temporary)
        for key, relative_path in DOCUMENT_PATHS.items():
            staged_path = staging / relative_path
            staged_path.parent.mkdir(parents=True, exist_ok=True)
            staged_path.write_bytes(_json_bytes(documents[key]))

        try:
            for relative_path in DOCUMENT_PATHS.values():
                destination = output_dir / relative_path
                destination.parent.mkdir(parents=True, exist_ok=True)
                backups[destination] = (
                    destination.read_bytes() if destination.exists() else None
                )
                os.replace(staging / relative_path, destination)
                replaced.append(destination)
        except OSError as error:
            for destination in reversed(replaced):
                original = backups[destination]
                if original is None:
                    destination.unlink(missing_ok=True)
                else:
                    destination.write_bytes(original)
            raise ContentGenerationError(
                "No fue posible publicar todos los JSON. Se restauró el contenido "
                f"anterior. Detalle: {error}."
            ) from error


def generate(input_dir: Path, output_dir: Path, *, check_only: bool = False) -> dict[str, object]:
    documents = build_documents(input_dir.resolve())
    validate_documents(documents)
    if not check_only:
        publish_documents(documents, output_dir)
    return documents


def summary(documents: dict[str, object]) -> str:
    questions = documents["questions"]
    challenges = documents["challenges"]
    resources = documents["resources"]
    ranks = documents["ranks"]
    assert isinstance(questions, dict)
    assert isinstance(challenges, dict)
    assert isinstance(resources, dict)
    assert isinstance(ranks, dict)
    question_count = len(questions["preguntas"])
    challenge_count = len(challenges["retos"])
    card_count = len(resources["cards"])
    rank_count = len(ranks["rangos"])
    return (
        f"{question_count} preguntas, "
        f"{challenge_count} reto{'' if challenge_count == 1 else 's'}, "
        f"{card_count} cards y "
        f"{rank_count} rangos"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Genera los JSON públicos de Misión Admisión desde cinco CSV."
    )
    parser.add_argument(
        "input_dir",
        nargs="?",
        default=ROOT / "admin/csv_samples",
        type=Path,
        help="Carpeta que contiene preguntas.csv, retos.csv, cards.csv, "
        "rangos.csv y config.csv.",
    )
    parser.add_argument(
        "--output",
        default=ROOT / "content",
        type=Path,
        help="Carpeta content de destino.",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Valida los CSV sin reemplazar archivos.",
    )
    args = parser.parse_args()

    try:
        documents = generate(args.input_dir, args.output, check_only=args.check_only)
    except (ContentGenerationError, OSError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if args.check_only:
        print(f"CSV válidos: {summary(documents)}.")
    else:
        print(f"Contenido publicado en {args.output}: {summary(documents)}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
