#!/usr/bin/env python3
"""Create one synthetic staging signup and verify Auth/profile name metadata."""

from __future__ import annotations

import json
import os
import secrets
import stat
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


PROJECT_REF = "aftdbphdobfrshienple"
CALLBACK = "io.supabase.everywear://login-callback"
REPO = Path(__file__).resolve().parent.parent
SUPABASE = REPO / ".tooling" / "supabase" / "node_modules" / ".bin" / "supabase"
CONFIG_DEFAULT = Path(
    "/tmp/everywear-staging-aftdbphdobfrshienple-private/app-config.json"
)
CREDENTIALS_DEFAULT = (
    Path.home() / ".config" / "everywear" / "staging-smoke-credentials.json"
)


def load_private_json(path: Path, required: set[str], label: str) -> dict:
    resolved = path.resolve(strict=True)
    if os.path.commonpath((str(resolved), str(REPO))) == str(REPO):
        raise ValueError(f"Keep the {label} outside the repository.")
    mode = stat.S_IMODE(resolved.stat().st_mode)
    if mode != 0o600:
        raise ValueError(f"The {label} must have mode 0600.")
    value = json.loads(resolved.read_text(encoding="utf-8"))
    if not isinstance(value, dict) or set(value) != required:
        raise ValueError(f"The {label} has an unexpected field set.")
    return value


def sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def run_sql(sql: str) -> dict:
    if not SUPABASE.is_file():
        raise RuntimeError("Supabase CLI is unavailable.")
    with tempfile.TemporaryDirectory(prefix="everywear-signup-check-") as temp:
        query_file = Path(temp) / "query.sql"
        descriptor = os.open(
            query_file,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL,
            stat.S_IRUSR | stat.S_IWUSR,
        )
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(sql)
        os.chmod(query_file, 0o600)
        result = subprocess.run(
            [
                str(SUPABASE),
                "db",
                "query",
                f"--remote={PROJECT_REF}",
                "--read-only",
                "--output-format",
                "json",
                "--file",
                str(query_file),
            ],
            cwd=REPO,
            capture_output=True,
            text=True,
            timeout=45,
            check=False,
        )
        if result.returncode != 0:
            raise RuntimeError("Read-only staging metadata query failed.")
        # The CLI may prefix the JSON result with a target identity line.
        start = result.stdout.find("{")
        if start < 0:
            raise RuntimeError("Staging metadata query returned no result.")
        try:
            parsed, _ = json.JSONDecoder().raw_decode(result.stdout[start:])
        except json.JSONDecodeError as error:
            raise RuntimeError("Staging metadata query result was malformed.") from error
        if not isinstance(parsed, dict) or not isinstance(parsed.get("rows"), list):
            raise RuntimeError("Staging metadata query returned an unexpected result.")
        return {"rows": parsed["rows"]}


def emit(label: str, passed: bool) -> None:
    print(f"{label}={'PASS' if passed else 'FAIL'}")


def main() -> int:
    config_path = Path(os.environ.get("EVERYWEAR_STAGE_CONFIG_FILE", CONFIG_DEFAULT))
    credentials_path = Path(
        os.environ.get("EVERYWEAR_SMOKE_CREDENTIALS_FILE", CREDENTIALS_DEFAULT)
    )
    config = load_private_json(
        config_path, {"SUPABASE_URL", "SUPABASE_ANON_KEY"}, "staging app config"
    )
    credentials = load_private_json(
        credentials_path,
        {"login_email", "login_password", "signup_email"},
        "smoke credentials",
    )
    url = config["SUPABASE_URL"]
    anon_key = config["SUPABASE_ANON_KEY"]
    login_email = credentials["login_email"].strip()
    signup_email = credentials["signup_email"].strip()
    if not isinstance(url, str) or url != f"https://{PROJECT_REF}.supabase.co":
        raise ValueError("Staging app config does not target the approved project.")
    if not isinstance(anon_key, str) or not anon_key.strip():
        raise ValueError("Staging app config is missing its public client key.")
    if not login_email or not signup_email or login_email.casefold() == signup_email.casefold():
        raise ValueError("Login and disposable signup addresses must be distinct.")
    if not isinstance(credentials["login_password"], str) or not credentials[
        "login_password"
    ]:
        raise ValueError("Dedicated staging login password is missing.")

    email_sql = sql_literal(signup_email)
    existing = run_sql(
        "SELECT count(*)::integer AS existing_accounts "
        "FROM auth.users WHERE lower(email) = lower(" + email_sql + ")"
    )
    if len(existing["rows"]) != 1 or existing["rows"][0].get("existing_accounts") != 0:
        print("SIGNUP_ADDRESS_UNUSED=FAIL")
        print("CONTROLLED_SIGNUP=NOT_RUN")
        return 1
    print("SIGNUP_ADDRESS_UNUSED=PASS")

    expected_name = f"Everywear Synthetic Signup {secrets.token_hex(4)}"
    password = secrets.token_urlsafe(32)
    endpoint = (
        url
        + "/auth/v1/signup?"
        + urllib.parse.urlencode({"redirect_to": CALLBACK})
    )
    payload = json.dumps(
        {
            "email": signup_email,
            "password": password,
            "data": {"full_name": expected_name},
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        endpoint,
        data=payload,
        method="POST",
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {anon_key}",
            "Content-Type": "application/json",
        },
    )
    auth_user = None
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            response_body = json.loads(response.read())
        auth_user = response_body.get("user", response_body)
    except urllib.error.HTTPError as error:
        # Never print the response body: auth errors may echo the submitted address.
        print(f"CONTROLLED_SIGNUP_REQUEST=FAIL (HTTP {error.code})")
        return 1
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        print("CONTROLLED_SIGNUP_REQUEST=FAIL (network or response error)")
        return 1

    user_metadata = (
        auth_user.get("user_metadata") if isinstance(auth_user, dict) else None
    )
    auth_response_matches = (
        isinstance(user_metadata, dict)
        and user_metadata.get("full_name") == expected_name
    )
    emit("CONTROLLED_SIGNUP_REQUEST", True)
    emit("AUTH_RESPONSE_METADATA", auth_response_matches)

    verification_sql = (
        "SELECT count(*)::integer AS matched_accounts, "
        "bool_or(u.raw_user_meta_data->>'full_name' = "
        + sql_literal(expected_name)
        + ") AS auth_metadata_matches, "
        "bool_or(p.full_name = "
        + sql_literal(expected_name)
        + ") AS profile_metadata_matches, "
        "bool_and(u.email_confirmed_at IS NULL) AS remains_unconfirmed "
        "FROM auth.users AS u LEFT JOIN public.user_profiles AS p ON p.id = u.id "
        "WHERE lower(u.email) = lower("
        + email_sql
        + ")"
    )
    try:
        verification = run_sql(verification_sql)
    except (OSError, RuntimeError, subprocess.SubprocessError):
        print("AUTH_STORED_METADATA=NOT_VERIFIED")
        print("PROFILE_TRIGGER_METADATA=NOT_VERIFIED")
        print("EMAIL_CONFIRMATION=NOT_TESTED")
        return 1
    rows = verification["rows"]
    row = rows[0] if len(rows) == 1 else {}
    one_account = row.get("matched_accounts") == 1
    emit("AUTH_STORED_METADATA", one_account and row.get("auth_metadata_matches") is True)
    emit(
        "PROFILE_TRIGGER_METADATA",
        one_account and row.get("profile_metadata_matches") is True,
    )
    print("EMAIL_CONFIRMATION=NOT_TESTED")
    if row.get("remains_unconfirmed") is True:
        print("SYNTHETIC_SIGNUP_STATE=UNCONFIRMED (retained in staging)")
    else:
        print(
            "SYNTHETIC_SIGNUP_STATE=AUTH_CONFIRMED; "
            "EMAIL_DELIVERY_AND_LINK_RETURN_STILL_NOT_TESTED"
        )
    return 0 if (
        auth_response_matches
        and one_account
        and row.get("auth_metadata_matches") is True
        and row.get("profile_metadata_matches") is True
    ) else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"Controlled signup stopped safely: {error}", file=sys.stderr)
        raise SystemExit(2)
