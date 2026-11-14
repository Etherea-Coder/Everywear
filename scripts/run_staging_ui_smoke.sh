#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-}"
config_file="${EVERYWEAR_STAGE_CONFIG_FILE:-}"
device_serial="${EVERYWEAR_UI_SMOKE_DEVICE_SERIAL:-}"
if [[ "$project_ref" != "aftdbphdobfrshienple" ]]; then
  echo "Set EVERYWEAR_STAGE_PROJECT_REF to the approved staging project." >&2
  exit 2
fi
if [[ -z "$config_file" || ! -f "$config_file" ]]; then
  echo "Set EVERYWEAR_STAGE_CONFIG_FILE to the private staging config file." >&2
  exit 2
fi
if [[ -z "$device_serial" ]]; then
  echo "Set EVERYWEAR_UI_SMOKE_DEVICE_SERIAL to the intended connected Android device serial." >&2
  exit 2
fi

flutter_bin="${FLUTTER_BIN:-$repo_root/.tooling/flutter/bin/flutter}"
adb_bin="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
defines_file="$(mktemp "${TMPDIR:-/tmp}/everywear-ui-smoke.XXXXXX.json")"
old_stay_on=""
restore_stay_on=0
cleanup() {
  if [[ "$restore_stay_on" == "1" ]]; then
    if [[ -z "$old_stay_on" || "$old_stay_on" == "null" ]]; then
      "$adb_bin" -s "$device_serial" shell settings delete global stay_on_while_plugged_in >/dev/null
    else
      "$adb_bin" -s "$device_serial" shell settings put global stay_on_while_plugged_in "$old_stay_on" >/dev/null
    fi
  fi
  rm -f "$defines_file"
}
trap cleanup EXIT
chmod 600 "$defines_file"

python3 - "$config_file" "$project_ref" "$repo_root" "$defines_file" <<'PY'
import json, os, pathlib, stat, sys, urllib.parse
config_path = pathlib.Path(sys.argv[1]).resolve(strict=True)
project_ref, repo_root, output_path = sys.argv[2:]
repo = pathlib.Path(repo_root).resolve()
if os.path.commonpath((str(config_path), str(repo))) == str(repo):
    raise SystemExit("Keep staging config outside the checkout.")
if stat.S_IMODE(config_path.stat().st_mode) & 0o077:
    raise SystemExit("Staging config must be private (mode 0600).")
try:
    config = json.loads(config_path.read_text())
except (OSError, json.JSONDecodeError) as error:
    raise SystemExit(f"Cannot read staging config JSON: {error}")
if not isinstance(config, dict) or set(config) != {"SUPABASE_URL", "SUPABASE_ANON_KEY"}:
    raise SystemExit("Config must contain exactly SUPABASE_URL and SUPABASE_ANON_KEY.")
url = urllib.parse.urlsplit(config["SUPABASE_URL"])
if (url.scheme != "https" or url.hostname != f"{project_ref}.supabase.co" or
        url.username or url.password or url.port or url.path or url.query or url.fragment):
    raise SystemExit("Staging URL must exactly match the approved project ref.")
if not isinstance(config["SUPABASE_ANON_KEY"], str) or not config["SUPABASE_ANON_KEY"].strip():
    raise SystemExit("Staging anon key is missing.")
config.update({
    "EVERYWEAR_STAGING": True,
    "EVERYWEAR_FREE_BETA": True,
    "APP_DISTRIBUTION": "uptodown",
    "REVENUECAT_BILLING_ENVIRONMENT": "unavailable",
    "EVERYWEAR_ADS_ENABLED": False,
    "EVERYWEAR_AD_PROVIDER": "disabled",
    "EVERYWEAR_UI_SMOKE_TEST": True,
})
pathlib.Path(output_path).write_text(json.dumps(config))
PY

if [[ ! -x "$adb_bin" ]]; then
  echo "adb not found at the configured path." >&2
  exit 2
fi
matches="$("$adb_bin" devices | awk -v serial="$device_serial" '$1 == serial && $2 == "device" { n++ } END { print n+0 }')"
if [[ "$matches" != "1" ]]; then
  echo "The selected Android device is not uniquely connected and authorized." >&2
  exit 2
fi
old_stay_on="$("$adb_bin" -s "$device_serial" shell settings get global stay_on_while_plugged_in | tr -d '\r')"
restore_stay_on=1
"$adb_bin" -s "$device_serial" shell svc power stayon usb

cd "$repo_root"
"$flutter_bin" test integration_test/app_test.dart \
  --device-id "$device_serial" \
  --dart-define-from-file="$defines_file"
