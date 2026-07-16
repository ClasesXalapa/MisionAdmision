from __future__ import annotations

import csv
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tool.generate_content_from_csv import (
    ContentGenerationError,
    generate,
)


class GenerateContentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = Path(__file__).resolve().parents[2]
        cls.samples = cls.root / "admin/csv_samples"

    def test_generates_and_validates_all_documents(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "content"
            documents = generate(self.samples, output)

            expected = [
                "index.json",
                "preguntas/banco_global.json",
                "retos/retos_actuales.json",
                "cards/cards_actuales.json",
                "config/rangos.json",
            ]
            for relative in expected:
                path = output / relative
                self.assertTrue(path.is_file(), relative)
                json.loads(path.read_text(encoding="utf-8"))

            questions = documents["questions"]
            self.assertIsInstance(questions, dict)
            assert isinstance(questions, dict)
            self.assertGreaterEqual(len(questions["preguntas"]), 10)

    def test_check_only_does_not_create_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "content"
            generate(self.samples, output, check_only=True)
            self.assertFalse(output.exists())

    def test_inactive_rows_are_omitted(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            input_dir = Path(temporary) / "csv"
            shutil.copytree(self.samples, input_dir)
            question_path = input_dir / "preguntas.csv"
            with question_path.open(
                "a", encoding="utf-8", newline=""
            ) as handle:
                writer = csv.writer(handle)
                writer.writerow(
                    [
                        "INACTIVA-001",
                        "No debe publicarse",
                        "",
                        "A",
                        "B",
                        "C",
                        "D",
                        "A",
                        "matematicas",
                        "prueba",
                        "basico",
                        "NO",
                    ]
                )
            documents = generate(input_dir, Path(temporary) / "output")
            questions = documents["questions"]
            assert isinstance(questions, dict)
            ids = {item["id"] for item in questions["preguntas"]}
            self.assertNotIn("INACTIVA-001", ids)

    def test_invalid_challenge_does_not_replace_existing_content(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            input_dir = root / "csv"
            output = root / "content"
            shutil.copytree(self.samples, input_dir)
            output.mkdir()
            marker = output / "index.json"
            marker.write_text('{"original": true}\n', encoding="utf-8")

            challenge_path = input_dir / "retos.csv"
            rows = list(
                csv.DictReader(
                    challenge_path.read_text(encoding="utf-8-sig").splitlines()
                )
            )
            rows[0]["preguntas_ids"] += ";ID-QUE-NO-EXISTE"
            with challenge_path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
                writer.writeheader()
                writer.writerows(rows)

            with self.assertRaises(ContentGenerationError):
                generate(input_dir, output)
            self.assertEqual(marker.read_text(encoding="utf-8"), '{"original": true}\n')
            self.assertFalse((output / "preguntas/banco_global.json").exists())

    def test_missing_header_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            input_dir = Path(temporary) / "csv"
            shutil.copytree(self.samples, input_dir)
            path = input_dir / "cards.csv"
            text = path.read_text(encoding="utf-8-sig")
            path.write_text(text.replace("prioridad", "prioriddad", 1), encoding="utf-8")

            with self.assertRaisesRegex(ContentGenerationError, "Encabezados inválidos"):
                generate(input_dir, Path(temporary) / "content")


if __name__ == "__main__":
    unittest.main()
