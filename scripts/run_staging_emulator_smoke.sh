#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-aftdbphdobfrshienple}"
config_file="${EVERYWEAR_STAGE_CONFIG_FILE:-/tmp/everywear-staging-aftdbphdobfrshienple-private/app-config.json}"
credentials_file="${EVERYWEAR_SMOKE_CREDENTIALS_FILE:-$HOME/.config/everywear/staging-smoke-credentials.json}"
normal_apk="${EVERYWEAR_NORMAL_STAGING_APK:-$repo_root/build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-4-aftdbphdobfrshienple-debug-AUTH-EVENTS-20261116.apk}"
avd_name="Medium_Phone"
device_serial="emulator-5554"
test_package="com.stylewise.app.stagingtest"
adb_bin="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
emulator_bin="${EMULATOR_BIN:-$HOME/Android/Sdk/emulator/emulator}"
aapt_bin=""
emulator_started=0
boot_log=""

if [[ "$project_ref" != "aftdbphdobfrshienple" ]]; then
  echo "Refusing any project other than the approved Everywear staging project." >&2
  exit 2
fi
if [[ ! -f "$config_file" ]]; then
  echo "The private staging app config is missing." >&2
  exit 2
fi
if [[ ! -f "$credentials_file" ]]; then
  echo "Private smoke credentials are missing. Run: python3 scripts/create_staging_smoke_credentials.py" >&2
  exit 2
fi
python3 - "$config_file" "$credentials_file" "$repo_root" <<'PY'
import json, os, pathlib, re, stat, sys
repo = pathlib.Path(sys.argv[3]).resolve()
for raw, required, label in (
    (sys.argv[1], {"SUPABASE_URL", "SUPABASE_ANON_KEY"}, "staging app config"),
    (sys.argv[2], {"login_email", "login_password", "signup_email"}, "smoke credentials"),
):
    path = pathlib.Path(raw).resolve(strict=True)
    if os.path.commonpath((str(path), str(repo))) == str(repo):
        raise SystemExit(f"Keep {label} outside Git.")
    if stat.S_IMODE(path.stat().st_mode) != 0o600:
        raise SystemExit(f"{label} must have mode 0600.")
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        raise SystemExit(f"{label} is unreadable or malformed.")
    if not isinstance(value, dict) or set(value) != required:
        raise SystemExit(f"{label} has an unexpected field set.")
    if label == "staging app config":
        if value["SUPABASE_URL"] != "https://aftdbphdobfrshienple.supabase.co":
            raise SystemExit("Staging app config does not target the approved project.")
        if not isinstance(value["SUPABASE_ANON_KEY"], str) or not value["SUPABASE_ANON_KEY"]:
            raise SystemExit("Staging app config is missing the public client key.")
    else:
        for key in ("login_email", "signup_email"):
            if not isinstance(value[key], str) or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", value[key].strip()):
                raise SystemExit("Smoke credentials contain an invalid email.")
        if value["login_email"].casefold() == value["signup_email"].casefold():
            raise SystemExit("Login and disposable signup addresses must differ.")
        if not isinstance(value["login_password"], str) or len(value["login_password"]) < 6:
            raise SystemExit("Dedicated staging login password is invalid.")
PY
if [[ ! -f "$normal_apk" || ! -x "$adb_bin" || ! -x "$emulator_bin" ]]; then
  echo "The retained normal staging APK or Android tools are unavailable." >&2
  exit 2
fi
if [[ ! -e /dev/kvm || ! -r /dev/kvm || ! -w /dev/kvm ]]; then
  echo "Hardware acceleration through /dev/kvm is unavailable." >&2
  exit 2
fi
if [[ ! -f "$HOME/.android/avd/$avd_name.avd/config.ini" ]]; then
  echo "The existing Medium_Phone AVD is unavailable." >&2
  exit 2
fi
if ! rg -qx 'abi.type=x86_64' "$HOME/.android/avd/$avd_name.avd/config.ini" || \
   ! rg -qx 'hw.ramSize=2048' "$HOME/.android/avd/$avd_name.avd/config.ini"; then
  echo "The existing AVD does not match the inspected x86_64/2 GiB configuration." >&2
  exit 2
fi
if pgrep -af 'GradleWrapperMain|GradleDaemon|KotlinCompileDaemon|flutter_tools.snapshot (build|test)|emulator.*-avd|qemu-system' | rg -v 'pgrep|rg ' >/dev/null; then
  echo "A build, compiler daemon, or emulator is active; refusing to overlap work." >&2
  exit 2
fi
available_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
if [[ -z "$available_kb" || "$available_kb" -lt 6291456 ]]; then
  echo "Need at least 6 GiB available RAM before starting the 2 GiB AVD." >&2
  exit 2
fi
if [[ -x "$HOME/Android/Sdk/build-tools/36.0.0/aapt" ]]; then
  aapt_bin="$HOME/Android/Sdk/build-tools/36.0.0/aapt"
else
  aapt_bin="$(find "$HOME/Android/Sdk/build-tools" -mindepth 2 -maxdepth 2 -type f -name aapt -print 2>/dev/null | sort -V | tail -n 1)"
fi
if [[ -z "$aapt_bin" || ! -x "$aapt_bin" ]]; then
  echo "Android build-tools aapt is unavailable." >&2
  exit 2
fi
normal_package="$("$aapt_bin" dump badging "$normal_apk" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)"
if [[ "$normal_package" != "com.stylewise.app" ]]; then
  echo "The retained APK is not the normal Everywear staging package." >&2
  exit 2
fi

boot_log="/tmp/everywear-emulator-boot-$(date +%Y%m%d-%H%M%S)-$$.log"
umask 077
: > "$boot_log"
chmod 600 "$boot_log"
cleanup() {
  if [[ "$emulator_started" == "1" ]]; then
    "$adb_bin" -s "$device_serial" emu kill >/dev/null 2>&1 || true
  fi
  if [[ -n "$boot_log" ]]; then
    echo "Private emulator boot log: $boot_log"
  fi
}
trap cleanup EXIT

"$emulator_bin" -avd "$avd_name" -port 5554 -no-snapshot -no-boot-anim \
  -no-window -no-audio -gpu swiftshader_indirect -memory 2048 >"$boot_log" 2>&1 &
emulator_started=1
for _ in $(seq 1 120); do
  if "$adb_bin" -s "$device_serial" get-state >/dev/null 2>&1; then break; fi
  sleep 1
done
"$adb_bin" -s "$device_serial" wait-for-device
booted=""
for _ in $(seq 1 180); do
  booted="$("$adb_bin" -s "$device_serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
  [[ "$booted" == "1" ]] && break
  sleep 2
done
if [[ "$booted" != "1" ]]; then
  echo "Existing AVD did not finish booting." >&2
  exit 1
fi
actual_avd="$("$adb_bin" -s "$device_serial" emu avd name | head -n 1 | tr -d '\r')"
if [[ "$actual_avd" != "$avd_name" ]]; then
  echo "The selected emulator serial does not match the approved AVD." >&2
  exit 2
fi
available_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
if [[ -z "$available_kb" || "$available_kb" -lt 4194304 ]]; then
  echo "Need at least 4 GiB available RAM after AVD boot; smoke build was not started." >&2
  exit 2
fi

# Install the normal package only as a preservation sentinel; never launch it.
"$adb_bin" -s "$device_serial" install -r "$normal_apk" >/dev/null

EVERYWEAR_STAGE_PROJECT_REF="$project_ref" \
EVERYWEAR_STAGE_CONFIG_FILE="$config_file" \
EVERYWEAR_SMOKE_CREDENTIALS_FILE="$credentials_file" \
  python3 "$repo_root/scripts/verify_staging_signup_metadata.py"

EVERYWEAR_STAGE_PROJECT_REF="$project_ref" \
EVERYWEAR_STAGE_CONFIG_FILE="$config_file" \
EVERYWEAR_SMOKE_CREDENTIALS_FILE="$credentials_file" \
EVERYWEAR_UI_SMOKE_DEVICE_SERIAL="$device_serial" \
EVERYWEAR_UI_SMOKE_TEST_TARGET="integration_test/app_test.dart" \
EVERYWEAR_UI_SMOKE_RUNTIME_AUTH="true" \
  "$repo_root/scripts/run_staging_ui_smoke.sh"

echo "EMULATOR_CORE_SMOKE=PASS"
