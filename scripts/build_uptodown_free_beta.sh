#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-}"
config_file="${EVERYWEAR_STAGE_CONFIG_FILE:-}"
if [[ -z "$project_ref" || -z "$config_file" ]]; then
  echo "Set EVERYWEAR_STAGE_PROJECT_REF and EVERYWEAR_STAGE_CONFIG_FILE to an isolated staging project and private config file." >&2
  exit 2
fi
if [[ ! "$project_ref" =~ ^[a-z0-9]{20}$ || "$project_ref" == "qxsdwwdrxoyxmnapuqqv" ]]; then
  echo "Refusing invalid or production Supabase project reference." >&2
  exit 2
fi
if [[ ! -f "$config_file" ]]; then
  echo "The private staging config file is not present." >&2
  exit 2
fi

defines_file="$(mktemp "${TMPDIR:-/tmp}/everywear-free-beta.XXXXXX.json")"
cleanup() {
  python3 - "$defines_file" <<'PY'
import pathlib, sys
pathlib.Path(sys.argv[1]).unlink(missing_ok=True)
PY
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
    raise SystemExit("Staging URL must exactly match the explicit non-production project ref.")
if not isinstance(config["SUPABASE_ANON_KEY"], str) or not config["SUPABASE_ANON_KEY"].strip():
    raise SystemExit("The staging anon key is missing.")
defines = {
    "SUPABASE_URL": config["SUPABASE_URL"],
    "SUPABASE_ANON_KEY": config["SUPABASE_ANON_KEY"],
    "EVERYWEAR_FREE_BETA": True,
    "EVERYWEAR_STAGING": True,
    "APP_DISTRIBUTION": "uptodown",
    "REVENUECAT_BILLING_ENVIRONMENT": "unavailable",
    "EVERYWEAR_ADS_ENABLED": False,
    "EVERYWEAR_AD_PROVIDER": "disabled",
}
pathlib.Path(output_path).write_text(json.dumps(defines))
PY

flutter_bin="${FLUTTER_BIN:-flutter}"
if [[ -x "$repo_root/.tooling/flutter/bin/flutter" && -z "${FLUTTER_BIN:-}" ]]; then
  flutter_bin="$repo_root/.tooling/flutter/bin/flutter"
fi
version="$(sed -n 's/^version:[[:space:]]*//p' "$repo_root/pubspec.yaml" | head -n 1 | tr '+' '-')"
artifact_dir="$repo_root/build/beta-artifacts"
mkdir -p "$artifact_dir"
(
  cd "$repo_root"
  "$flutter_bin" build apk --debug --no-pub --dart-define-from-file="$defines_file"
)
artifact="$artifact_dir/Everywear-Uptodown-Free-STAGING-Beta-${version}-${project_ref}-debug.apk"
cp "$repo_root/build/app/outputs/flutter-apk/app-debug.apk" "$artifact"
sha256sum "$artifact"
printf 'Staging-only debug APK: %s\n' "$artifact"
printf 'Package identity remains com.stylewise.app; this debug APK is not a store release.\n'
