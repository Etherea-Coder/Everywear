#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-}"
config_file="${EVERYWEAR_STAGE_CONFIG_FILE:-}"
if [[ -z "$project_ref" || -z "$config_file" ]]; then
  echo "Set EVERYWEAR_STAGE_PROJECT_REF and EVERYWEAR_STAGE_CONFIG_FILE to an isolated staging project and private config file." >&2
  exit 2
fi
if [[ "$project_ref" != "aftdbphdobfrshienple" ]]; then
  echo "Refusing any Supabase project other than the approved Everywear staging ref." >&2
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
diagnostics = os.environ.get("EVERYWEAR_STARTUP_DIAGNOSTICS", "false").strip().lower()
engine_test = os.environ.get("EVERYWEAR_STARTUP_ENGINE_TEST", "false").strip().lower()
stage_probe = os.environ.get("EVERYWEAR_STARTUP_STAGE_PROBE", "false").strip().lower()
if diagnostics not in {"true", "false"} or engine_test not in {"true", "false"} or stage_probe not in {"true", "false"}:
    raise SystemExit("Startup mode environment values must be true or false.")
if sum(value == "true" for value in (diagnostics, engine_test, stage_probe)) > 1:
    raise SystemExit("Startup diagnostics, stage probe, and engine isolation modes are exclusive.")
defines["EVERYWEAR_STARTUP_DIAGNOSTICS"] = diagnostics == "true" or stage_probe == "true"
defines["EVERYWEAR_STARTUP_ENGINE_TEST"] = engine_test == "true"
pathlib.Path(output_path).write_text(json.dumps(defines))
PY

flutter_bin="${FLUTTER_BIN:-flutter}"
if [[ -x "$repo_root/.tooling/flutter/bin/flutter" && -z "${FLUTTER_BIN:-}" ]]; then
  flutter_bin="$repo_root/.tooling/flutter/bin/flutter"
fi
version="$(sed -n 's/^version:[[:space:]]*//p' "$repo_root/pubspec.yaml" | head -n 1 | tr '+' '-')"
artifact_dir="$repo_root/build/beta-artifacts"
mkdir -p "$artifact_dir"
diagnostics_enabled="${EVERYWEAR_STARTUP_DIAGNOSTICS:-false}"
diagnostics_enabled="${diagnostics_enabled,,}"
engine_test_enabled="${EVERYWEAR_STARTUP_ENGINE_TEST:-false}"
engine_test_enabled="${engine_test_enabled,,}"
stage_probe_enabled="${EVERYWEAR_STARTUP_STAGE_PROBE:-false}"
stage_probe_enabled="${stage_probe_enabled,,}"
flutter_args=(build apk --debug --no-pub --dart-define-from-file="$defines_file")
if [[ "$engine_test_enabled" == "true" ]]; then
  flutter_args+=(--target=lib/startup_engine_test.dart)
fi
if [[ "$stage_probe_enabled" == "true" ]]; then
  flutter_args+=(--target=lib/startup_stage_probe.dart)
fi
(
  cd "$repo_root"
  if [[ "$engine_test_enabled" == "true" ]]; then
    export ORG_GRADLE_PROJECT_everywearAppLabel="Everywear Engine Test (STAGING)"
  fi
  if [[ "$stage_probe_enabled" == "true" ]]; then
    export ORG_GRADLE_PROJECT_everywearAppLabel="Everywear Startup Probe (STAGING)"
  fi
  "$flutter_bin" "${flutter_args[@]}"
)
artifact="$artifact_dir/Everywear-Uptodown-Free-STAGING-Beta-${version}-${project_ref}-debug.apk"
if [[ "$diagnostics_enabled" == "true" ]]; then
  artifact="${artifact%-debug.apk}-STARTUP-DIAGNOSTIC-debug.apk"
fi
if [[ "$engine_test_enabled" == "true" ]]; then
  artifact="${artifact%-debug.apk}-ENGINE-ISOLATION-debug.apk"
fi
if [[ "$stage_probe_enabled" == "true" ]]; then
  artifact="${artifact%-debug.apk}-STARTUP-STAGE-PROBE-debug.apk"
fi
cp "$repo_root/build/app/outputs/flutter-apk/app-debug.apk" "$artifact"
sha256sum "$artifact"
printf 'Staging-only debug APK: %s\n' "$artifact"
printf 'Package identity remains com.stylewise.app; this debug APK is not a store release.\n'
