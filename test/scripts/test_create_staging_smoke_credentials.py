import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "create_staging_smoke_credentials.py"
SPEC = importlib.util.spec_from_file_location("smoke_credentials", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class SmokeCredentialEntryTest(unittest.TestCase):
    def test_prompts_for_separate_accounts_and_writes_private_json(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / ".config" / "credentials.json"
            output = io.StringIO()
            with (
                mock.patch.object(MODULE, "DESTINATION", destination),
                mock.patch("builtins.input", side_effect=["login@staging.invalid", "signup@staging.invalid"]),
                mock.patch("getpass.getpass", side_effect=["synthetic-password", "synthetic-password"]),
                contextlib.redirect_stdout(output),
            ):
                self.assertEqual(MODULE.main(), 0)

            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)
            self.assertEqual(
                set(json.loads(destination.read_text())),
                {"login_email", "login_password", "signup_email"},
            )
            self.assertNotIn("synthetic-password", output.getvalue())
            self.assertNotIn("login@staging.invalid", output.getvalue())
            self.assertNotIn("signup@staging.invalid", output.getvalue())

    def test_refuses_to_overwrite_existing_credentials(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "credentials.json"
            destination.write_text("preserve")
            with (
                mock.patch.object(MODULE, "DESTINATION", destination),
                mock.patch("builtins.input") as input_mock,
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(MODULE.main(), 2)
            input_mock.assert_not_called()
            self.assertEqual(destination.read_text(), "preserve")


if __name__ == "__main__":
    unittest.main()
