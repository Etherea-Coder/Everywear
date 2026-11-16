#!/usr/bin/env python3
"""Privately collect emulator-only staging smoke credentials."""

from __future__ import annotations

import getpass
import json
import os
import re
import secrets
import stat
import sys
from pathlib import Path


DESTINATION = (
    Path.home() / ".config" / "everywear" / "staging-smoke-credentials.json"
)
EMAIL = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


def prompt_email(prompt: str) -> str:
    value = input(prompt).strip()
    if not EMAIL.fullmatch(value):
        raise ValueError("Enter a valid email address.")
    return value


def main() -> int:
    if DESTINATION.exists():
        print(
            "Credential file already exists; refusing to overwrite it. "
            "Move it securely before creating a replacement.",
            file=sys.stderr,
        )
        return 2

    print("Staging emulator test credentials (values are never echoed).")
    print("Use a dedicated, preconfirmed staging login account—not your account.")
    login_email = prompt_email("Preconfirmed staging login email: ")
    login_password = getpass.getpass("Preconfirmed staging login password: ")
    if len(login_password) < 6:
        raise ValueError("The staging login password must be at least 6 characters.")
    if getpass.getpass("Re-enter preconfirmed staging login password: ") != login_password:
        raise ValueError("The password entries did not match.")

    print(
        "Use a separate, disposable staging signup inbox address. The test "
        "creates a synthetic signup; email delivery and confirmation are not tested."
    )
    signup_email = prompt_email("Disposable staging signup email: ")
    if login_email.casefold() == signup_email.casefold():
        raise ValueError("Login and disposable signup addresses must differ.")

    DESTINATION.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(DESTINATION.parent, 0o700)
    payload = json.dumps(
        {
            "login_email": login_email,
            "login_password": login_password,
            "signup_email": signup_email,
        },
        separators=(",", ":"),
    )
    temporary = DESTINATION.with_name(
        f".{DESTINATION.name}.{secrets.token_hex(8)}.tmp"
    )
    descriptor = os.open(
        temporary,
        os.O_WRONLY | os.O_CREAT | os.O_EXCL,
        stat.S_IRUSR | stat.S_IWUSR,
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(payload)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        # Linking is atomic and fails if another file appeared at the target;
        # never replace a credential file created after the initial check.
        os.link(temporary, DESTINATION)
        temporary.unlink()
    except Exception:
        temporary.unlink(missing_ok=True)
        raise

    print(f"Saved private credentials to {DESTINATION} (mode 0600).")
    print("Do not copy its contents into chat, Git, build defines, or an APK.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (EOFError, KeyboardInterrupt):
        print("Credential entry cancelled; no values were displayed.", file=sys.stderr)
        raise SystemExit(130)
    except (OSError, ValueError) as error:
        # Only controlled validation errors are reported; never print entered values.
        print(f"Could not create the private credential file: {error}", file=sys.stderr)
        raise SystemExit(2)
