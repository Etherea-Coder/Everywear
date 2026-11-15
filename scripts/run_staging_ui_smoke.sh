#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
source "$repo_root/scripts/lib/android_package_path.sh"
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
java21_home="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}"
normal_application_id="com.stylewise.app"
test_application_id="com.stylewise.app.stagingtest"
if [[ "$test_application_id" == "$normal_application_id" ]]; then
  echo "Refusing to run UI smoke against the normal application identity." >&2
  exit 2
fi
flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd)"
flutter_android_package_source="$flutter_root/packages/flutter_tools/lib/src/android/application_package.dart"
if [[ ! -f "$flutter_android_package_source" ]] || \
  ! rg -q "androidProject\.namespace" "$flutter_android_package_source"; then
  echo "Cannot verify the pinned Flutter runner's Android package fallback; refusing the test." >&2
  exit 2
fi
if [[ ! -x "$java21_home/bin/java" ]]; then
  echo "Java 21 is required for the staging Android instrumentation build." >&2
  exit 2
fi
export JAVA_HOME="$java21_home"
export PATH="$JAVA_HOME/bin:$PATH"
old_flutter_jdk="$("$flutter_bin" config --list | sed -n 's/^  jdk-dir: //p' | head -n 1)"
restore_flutter_jdk=0
defines_file="$(mktemp "${TMPDIR:-/tmp}/everywear-ui-smoke.XXXXXX.json")"
old_stay_on=""
restore_stay_on=0
logcat_file=""
logcat_pid=""
base_install_time=""
base_version_code=""
base_last_update_time=""
cleanup() {
  cleanup_failed=0
  if [[ -n "$logcat_pid" ]]; then
    kill "$logcat_pid" 2>/dev/null || true
    wait "$logcat_pid" 2>/dev/null || true
    logcat_pid=""
    echo "Private device logcat saved at: $logcat_file"
  fi
  if [[ "$restore_flutter_jdk" == "1" ]]; then
    "$flutter_bin" config --jdk-dir="$old_flutter_jdk" >/dev/null || cleanup_failed=1
  fi
  if [[ "$restore_stay_on" == "1" ]]; then
    if [[ -z "$old_stay_on" || "$old_stay_on" == "null" ]]; then
      "$adb_bin" -s "$device_serial" shell settings delete global stay_on_while_plugged_in >/dev/null || cleanup_failed=1
    else
      "$adb_bin" -s "$device_serial" shell settings put global stay_on_while_plugged_in "$old_stay_on" >/dev/null || cleanup_failed=1
    fi
  fi
  rm -f "$defines_file"
  if [[ "$cleanup_failed" == "1" ]]; then
    echo "Unable to restore one or more temporary Flutter/device settings." >&2
  fi
}
trap cleanup EXIT
chmod 600 "$defines_file"
restore_flutter_jdk=1
"$flutter_bin" config --jdk-dir="$JAVA_HOME" >/dev/null

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
if ! normal_package_path="$(read_android_package_path "$adb_bin" "$device_serial" "$normal_application_id")"; then
  echo "Cannot query the normal app package; refusing the test." >&2
  exit 2
fi
if [[ -z "$normal_package_path" ]]; then
  echo "Install the normal Everywear staging app before running its isolated UI test." >&2
  exit 2
fi
package_dump="$("$adb_bin" -s "$device_serial" shell dumpsys package "$normal_application_id")"
base_install_time="$(printf '%s\n' "$package_dump" | sed -n 's/^ *firstInstallTime=//p' | head -n 1)"
base_version_code="$(printf '%s\n' "$package_dump" | sed -n 's/^ *versionCode=\([^ ]*\).*/\1/p' | head -n 1)"
base_last_update_time="$(printf '%s\n' "$package_dump" | sed -n 's/^ *lastUpdateTime=//p' | head -n 1)"
if [[ -z "$base_install_time" || -z "$base_version_code" || -z "$base_last_update_time" ]]; then
  echo "Cannot record the normal app installation identity; refusing the test." >&2
  exit 2
fi
test_application_identity="$(
  cd "$repo_root/android"
  ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
    ./gradlew --quiet :app:printEverywearApplicationId
)"
if ! printf '%s\n' "$test_application_identity" | rg -qx "EVERYWEAR_APPLICATION_ID=$test_application_id" || \
  ! printf '%s\n' "$test_application_identity" | rg -qx "EVERYWEAR_NAMESPACE=$test_application_id"; then
  echo "Gradle resolved an unsafe integration-test package or namespace; refusing to run Flutter's installer/teardown." >&2
  exit 2
fi
old_stay_on="$("$adb_bin" -s "$device_serial" shell settings get global stay_on_while_plugged_in | tr -d '\r')"
restore_stay_on=1
"$adb_bin" -s "$device_serial" shell svc power stayon usb

umask 077
logcat_file="/tmp/everywear-a065-ui-smoke-$(date +%Y%m%d-%H%M%S)-$$.log"
: > "$logcat_file"
chmod 600 "$logcat_file"
"$adb_bin" -s "$device_serial" logcat -v epoch >"$logcat_file" 2>&1 &
logcat_pid=$!

cd "$repo_root"
set +e
ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
  "$flutter_bin" test integration_test/app_test.dart \
  --device-id "$device_serial" \
  --dart-define-from-file="$defines_file"
test_status=$?
set -e

if ! normal_package_path_after="$(read_android_package_path "$adb_bin" "$device_serial" "$normal_application_id")"; then
  echo "Could not verify the normal app package after the isolated smoke test." >&2
  exit 1
fi
package_dump_after="$("$adb_bin" -s "$device_serial" shell dumpsys package "$normal_application_id" 2>&1 || true)"
base_install_time_after="$(printf '%s\n' "$package_dump_after" | sed -n 's/^ *firstInstallTime=//p' | head -n 1)"
base_version_code_after="$(printf '%s\n' "$package_dump_after" | sed -n 's/^ *versionCode=\([^ ]*\).*/\1/p' | head -n 1)"
base_last_update_time_after="$(printf '%s\n' "$package_dump_after" | sed -n 's/^ *lastUpdateTime=//p' | head -n 1)"
if [[ -z "$normal_package_path_after" || "$base_install_time_after" != "$base_install_time" || "$base_version_code_after" != "$base_version_code" || "$base_last_update_time_after" != "$base_last_update_time" ]]; then
  echo "FAIL: normal Everywear package was removed or changed during the isolated smoke test." >&2
  exit 1
fi
if ! test_package_path_after="$(read_android_package_path "$adb_bin" "$device_serial" "$test_application_id")"; then
  echo "Could not verify cleanup of the isolated test package." >&2
  exit 1
fi
if [[ -n "$test_package_path_after" ]]; then
  echo "FAIL: Flutter did not uninstall the isolated test package after the smoke test." >&2
  exit 1
fi
echo "Verified normal app package unchanged: $normal_application_id ($base_version_code; install $base_install_time; update $base_last_update_time)."
echo "Verified Flutter cleanup removed the isolated test package: $test_application_id."
if [[ "$test_status" != "0" ]]; then
  exit "$test_status"
fi

echo "Isolated UI smoke passed under $test_application_id; normal app remains installed."
