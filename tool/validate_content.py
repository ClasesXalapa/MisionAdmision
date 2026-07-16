#!/usr/bin/env python3
"""Validador sin dependencias externas para el contenido del MVP."""

from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
BANK_PATH = ROOT / "content" / "preguntas" / "banco_global.json"
CHALLENGES_PATH = ROOT / "content" / "retos" / "retos_actuales.json"
CARDS_PATH = ROOT / "content" / "cards" / "cards_actuales.json"
RANKS_PATH = ROOT / "content" / "config" / "rangos.json"
INDEX_PATH = ROOT / "content" / "index.json"
VALID_ANSWERS = {"A", "B", "C", "D"}
VALID_DIFFICULTIES = {"basico", "intermedio", "avanzado"}
VERSION_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,100}$")
VALID_RESOURCE_TYPES = {
    "video",
    "pdf",
    "formulario",
    "simulacro",
    "publicacion",
    "anuncio",
}


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise ValueError(f"No existe: {path.relative_to(ROOT)}") from None
    except json.JSONDecodeError as error:
        raise ValueError(
            f"JSON inválido en {path.relative_to(ROOT)}: línea {error.lineno}, "
            f"columna {error.colno}."
        ) from error


def is_https_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def is_iso_datetime(value: object) -> bool:
    if not isinstance(value, str) or not value.strip():
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def is_iso_date(value: object) -> bool:
    if not isinstance(value, str):
        return False
    try:
        date.fromisoformat(value)
    except ValueError:
        return False
    return True


def validate_metadata(data, label: str) -> list[str]:
    errors: list[str] = []
    if data.get("schema_version") != 1:
        errors.append(f"{label}: schema_version debe ser 1.")
    if not isinstance(data.get("version"), str) or not data["version"].strip():
        errors.append(f"{label}: version debe ser texto no vacío.")
    elif not VERSION_PATTERN.fullmatch(data["version"]):
        errors.append(f"{label}: version contiene caracteres inválidos.")
    if not is_iso_datetime(data.get("generated_at")):
        errors.append(f"{label}: generated_at debe utilizar formato ISO 8601.")
    return errors


def validate_index(data, documents: dict[str, object]) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["content/index.json debe contener un objeto."]
    if data.get("schema_version") != 1:
        errors.append("content/index.json: schema_version debe ser 1.")
    if not isinstance(data.get("content_version"), str) or not data["content_version"].strip():
        errors.append("content/index.json: content_version debe ser texto no vacío.")
    if not is_iso_datetime(data.get("generated_at")):
        errors.append("content/index.json: generated_at debe ser ISO 8601.")
    min_app_version = data.get("min_app_version")
    if not isinstance(min_app_version, int) or min_app_version < 1:
        errors.append("content/index.json: min_app_version debe ser entero positivo.")

    files = data.get("files")
    if not isinstance(files, dict):
        return errors + ["content/index.json: files debe ser un objeto."]

    expected = {
        "questions": "content/preguntas/banco_global.json",
        "challenges": "content/retos/retos_actuales.json",
        "resources": "content/cards/cards_actuales.json",
        "ranks": "content/config/rangos.json",
    }
    for key, expected_url in expected.items():
        item = files.get(key)
        if not isinstance(item, dict):
            errors.append(f"content/index.json: falta files.{key}.")
            continue
        if item.get("url") != expected_url:
            errors.append(f"content/index.json: URL de {key} inesperada.")
        version = item.get("version")
        if not isinstance(version, str) or not version.strip():
            errors.append(f"content/index.json: version de {key} debe ser texto no vacío.")
        elif not VERSION_PATTERN.fullmatch(version):
            errors.append(f"content/index.json: version de {key} contiene caracteres inválidos.")
        else:
            document = documents.get(key)
            document_version = document.get("version") if isinstance(document, dict) else None
            if version != document_version:
                errors.append(
                    f"content/index.json: version de {key} no coincide con el documento."
                )
        if not isinstance(item.get("required"), bool):
            errors.append(f"content/index.json: required de {key} debe ser booleano.")
    questions = files.get("questions")
    if isinstance(questions, dict) and questions.get("required") is not True:
        errors.append("content/index.json: questions debe ser obligatorio.")
    return errors


def validate_bank(data) -> tuple[list[str], set[str]]:
    errors: list[str] = []
    question_ids: set[str] = set()
    if not isinstance(data, dict):
        return ["El banco debe contener un objeto JSON."], question_ids
    errors.extend(validate_metadata(data, "preguntas"))

    questions = data.get("preguntas")
    if not isinstance(questions, list):
        return errors + ["preguntas debe ser una lista."], question_ids
    if len(questions) < 10:
        errors.append("El banco debe contener al menos 10 preguntas.")

    for index, question in enumerate(questions):
        path = f"preguntas[{index}]"
        if not isinstance(question, dict):
            errors.append(f"{path} debe ser un objeto.")
            continue

        question_id = question.get("id")
        if not isinstance(question_id, str) or not question_id.strip():
            errors.append(f"{path}.id debe ser texto no vacío.")
        elif question_id in question_ids:
            errors.append(f"{path}.id está duplicado: {question_id}.")
        else:
            question_ids.add(question_id)

        statement = question.get("enunciado")
        if not isinstance(statement, str) or not statement.strip():
            errors.append(f"{path}.enunciado debe ser texto no vacío.")

        options = question.get("opciones")
        if not isinstance(options, list) or len(options) != 4:
            errors.append(f"{path}.opciones debe contener exactamente 4 elementos.")
        elif any(not isinstance(option, str) or not option.strip() for option in options):
            errors.append(f"{path}.opciones contiene opciones vacías o no textuales.")

        if question.get("respuesta_correcta") not in VALID_ANSWERS:
            errors.append(f"{path}.respuesta_correcta debe ser A, B, C o D.")

        category = question.get("categoria")
        if not isinstance(category, str) or not category.strip():
            errors.append(f"{path}.categoria debe ser texto no vacío.")

        tags = question.get("etiquetas")
        if not isinstance(tags, list) or not tags or any(
            not isinstance(tag, str) or not tag.strip() for tag in tags
        ):
            errors.append(f"{path}.etiquetas debe contener texto no vacío.")

        if question.get("dificultad") not in VALID_DIFFICULTIES:
            errors.append(
                f"{path}.dificultad debe ser basico, intermedio o avanzado."
            )

        image_url = question.get("imagen_url")
        if image_url is not None and (
            not isinstance(image_url, str) or not is_https_url(image_url)
        ):
            errors.append(f"{path}.imagen_url debe ser null o una URL HTTPS.")

    return errors, question_ids


def validate_challenges(data, question_ids: set[str]) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["El banco de retos debe contener un objeto JSON."]
    errors.extend(validate_metadata(data, "retos"))

    challenges = data.get("retos")
    if not isinstance(challenges, list):
        return errors + ["retos debe ser una lista."]

    seen_ids: set[str] = set()
    seen_dates: set[str] = set()
    for index, challenge in enumerate(challenges):
        path = f"retos[{index}]"
        if not isinstance(challenge, dict):
            errors.append(f"{path} debe ser un objeto.")
            continue

        challenge_id = challenge.get("id")
        if not isinstance(challenge_id, str) or not challenge_id.strip():
            errors.append(f"{path}.id debe ser texto no vacío.")
        elif challenge_id in seen_ids:
            errors.append(f"{path}.id está duplicado: {challenge_id}.")
        else:
            seen_ids.add(challenge_id)

        challenge_date = challenge.get("fecha")
        if not is_iso_date(challenge_date):
            errors.append(f"{path}.fecha debe usar YYYY-MM-DD y ser válida.")
        elif challenge_date in seen_dates:
            errors.append(f"{path}.fecha está duplicada: {challenge_date}.")
        else:
            seen_dates.add(challenge_date)

        title = challenge.get("titulo")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{path}.titulo debe ser texto no vacío.")

        ids = challenge.get("preguntas_ids")
        if not isinstance(ids, list) or not ids:
            errors.append(f"{path}.preguntas_ids debe contener IDs.")
        elif any(not isinstance(item, str) or not item.strip() for item in ids):
            errors.append(f"{path}.preguntas_ids contiene valores inválidos.")
        else:
            if len(ids) != len(set(ids)):
                errors.append(f"{path}.preguntas_ids no puede repetir preguntas.")
            missing = sorted(set(ids) - question_ids)
            if missing:
                errors.append(
                    f"{path}.preguntas_ids referencia IDs inexistentes: "
                    f"{', '.join(missing)}."
                )

        resource = challenge.get("recurso_resolucion")
        if not isinstance(resource, dict):
            errors.append(f"{path}.recurso_resolucion es obligatorio.")
        else:
            for field in ("tipo", "titulo"):
                value = resource.get(field)
                if not isinstance(value, str) or not value.strip():
                    errors.append(
                        f"{path}.recurso_resolucion.{field} debe ser texto no vacío."
                    )
            url = resource.get("url")
            if not isinstance(url, str) or not is_https_url(url):
                errors.append(
                    f"{path}.recurso_resolucion.url debe ser una URL HTTPS."
                )

    return errors


def validate_cards(data) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["El banco de cards debe contener un objeto JSON."]
    errors.extend(validate_metadata(data, "cards"))
    cards = data.get("cards")
    if not isinstance(cards, list):
        return errors + ["cards debe ser una lista."]

    ids: set[str] = set()
    for index, card in enumerate(cards):
        path = f"cards[{index}]"
        if not isinstance(card, dict):
            errors.append(f"{path} debe ser un objeto.")
            continue
        card_id = card.get("id")
        if not isinstance(card_id, str) or not card_id.strip():
            errors.append(f"{path}.id debe ser texto no vacío.")
        elif card_id in ids:
            errors.append(f"{path}.id está duplicado: {card_id}.")
        else:
            ids.add(card_id)

        for field in ("titulo", "descripcion"):
            value = card.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path}.{field} debe ser texto no vacío.")
        if card.get("tipo") not in VALID_RESOURCE_TYPES:
            errors.append(f"{path}.tipo no es válido.")
        url = card.get("url")
        if not isinstance(url, str) or not is_https_url(url):
            errors.append(f"{path}.url debe ser una URL HTTPS.")
        image_url = card.get("imagen_url")
        if image_url is not None and (
            not isinstance(image_url, str) or not is_https_url(image_url)
        ):
            errors.append(f"{path}.imagen_url debe ser null o una URL HTTPS.")
        tags = card.get("etiquetas")
        if not isinstance(tags, list) or not tags or any(
            not isinstance(tag, str) or not tag.strip() for tag in tags
        ):
            errors.append(f"{path}.etiquetas debe contener texto no vacío.")
        priority = card.get("prioridad")
        if not isinstance(priority, int) or priority < 0:
            errors.append(f"{path}.prioridad debe ser un entero no negativo.")
        if not is_iso_date(card.get("fecha_publicacion")):
            errors.append(f"{path}.fecha_publicacion debe usar YYYY-MM-DD.")
        if not isinstance(card.get("activa"), bool):
            errors.append(f"{path}.activa debe ser booleano.")
    return errors


def validate_ranks(data) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["El banco de rangos debe contener un objeto JSON."]
    errors.extend(validate_metadata(data, "rangos"))
    ranks = data.get("rangos")
    if not isinstance(ranks, list) or not ranks:
        return errors + ["rangos debe ser una lista no vacía."]

    ids: set[str] = set()
    thresholds: set[int] = set()
    for index, rank in enumerate(ranks):
        path = f"rangos[{index}]"
        if not isinstance(rank, dict):
            errors.append(f"{path} debe ser un objeto.")
            continue
        rank_id = rank.get("id")
        if not isinstance(rank_id, str) or not rank_id.strip():
            errors.append(f"{path}.id debe ser texto no vacío.")
        elif rank_id in ids:
            errors.append(f"{path}.id está duplicado: {rank_id}.")
        else:
            ids.add(rank_id)
        for field in ("nombre", "descripcion"):
            value = rank.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path}.{field} debe ser texto no vacío.")
        threshold = rank.get("racha_minima")
        if not isinstance(threshold, int) or threshold < 0:
            errors.append(f"{path}.racha_minima debe ser un entero no negativo.")
        elif threshold in thresholds:
            errors.append(f"{path}.racha_minima no puede repetirse.")
        else:
            thresholds.add(threshold)
    if 0 not in thresholds:
        errors.append("Debe existir un rango con racha_minima igual a 0.")
    return errors


def main() -> int:
    try:
        bank = load_json(BANK_PATH)
        challenges = load_json(CHALLENGES_PATH)
        cards = load_json(CARDS_PATH)
        ranks = load_json(RANKS_PATH)
        index = load_json(INDEX_PATH)
    except ValueError as error:
        print(f"ERROR: {error}")
        return 1

    bank_errors, question_ids = validate_bank(bank)
    errors = (
        bank_errors
        + validate_challenges(challenges, question_ids)
        + validate_cards(cards)
        + validate_ranks(ranks)
        + validate_index(index, {
            "questions": bank,
            "challenges": challenges,
            "resources": cards,
            "ranks": ranks,
        })
    )
    if errors:
        print("Contenido inválido:")
        for error in errors:
            print(f"- {error}")
        return 1

    active_cards = sum(1 for card in cards["cards"] if card["activa"])
    print(
        f"Contenido válido: {len(bank['preguntas'])} preguntas, "
        f"{len(challenges['retos'])} retos, {active_cards} cards activas y "
        f"{len(ranks['rangos'])} rangos."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
