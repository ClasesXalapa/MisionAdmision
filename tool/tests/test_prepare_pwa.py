from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tool.prepare_pwa import prepare


class PreparePwaTest(unittest.TestCase):
    def test_generates_versioned_service_worker(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            build = root / "build"
            build.mkdir()
            for name in [
                "index.html",
                "offline.html",
                "manifest.json",
                "flutter_bootstrap.js",
                "main.dart.js",
                "pwa_bridge.js",
                "firebase_config.js",
                "notifications_bridge.js",
                "backup_bridge.js",
                "diagnostics_bridge.js",
            ]:
                (build / name).write_text(name, encoding="utf-8")
            (build / "content").mkdir()
            (build / "content" / "index.json").write_text(
                "{}",
                encoding="utf-8",
            )
            template = root / "worker.js"
            template.write_text(
                "const version='__BUILD_VERSION__';"
                "const app=__APP_SHELL__;"
                "const content=__CONTENT_ASSETS__;",
                encoding="utf-8",
            )

            metadata = prepare(build, template)

            worker = (build / "app_service_worker.js").read_text(
                encoding="utf-8"
            )
            self.assertNotIn("__BUILD_VERSION__", worker)
            self.assertIn("content/index.json", worker)
            self.assertTrue((build / ".nojekyll").exists())
            saved = json.loads((build / "pwa_build.json").read_text())
            self.assertEqual(saved["version"], metadata["version"])
            self.assertEqual(saved["content_files"], 1)

    def test_rejects_missing_required_build_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            build = root / "build"
            build.mkdir()
            template = root / "worker.js"
            template.write_text(
                "__BUILD_VERSION____APP_SHELL____CONTENT_ASSETS__",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Faltan archivos"):
                prepare(build, template)


if __name__ == "__main__":
    unittest.main()
