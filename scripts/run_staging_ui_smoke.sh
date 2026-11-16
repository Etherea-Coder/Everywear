#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
source "$repo_root/scripts/lib/android_package_path.sh"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-}"
config_file="${EVERYWEAR_STAGE_CONFIG_FILE:-}"
device_serial="${EVERYWEAR_UI_SMOKE_DEVICE_SERIAL:-}"
test_target="${EVERYWEAR_UI_SMOKE_TEST_TARGET:-integration_test/app_test.dart}"
prebuild_only="${EVERYWEAR_UI_SMOKE_PREBUILD_ONLY:-false}"
prebuilt_apk="${EVERYWEAR_UI_SMOKE_PREBUILT_APK:-}"
if [[ "$project_ref" != "aftdbphdobfrshienple" ]]; then
  echo "Set EVERYWEAR_STAGE_PROJECT_REF to the approved staging project." >&2
  exit 2
fi
if [[ -z "$config_file" || ! -f "$config_file" ]]; then
  echo "Set EVERYWEAR_STAGE_CONFIG_FILE to the private staging config file." >&2
  exit 2
fi
if [[ "$prebuild_only" != "true" && "$prebuild_only" != "false" ]]; then
  echo "EVERYWEAR_UI_SMOKE_PREBUILD_ONLY must be true or false." >&2
  exit 2
fi
if [[ "$prebuild_only" == "false" && -z "$device_serial" ]]; then
  echo "Set EVERYWEAR_UI_SMOKE_DEVICE_SERIAL to the intended connected Android device serial." >&2
  exit 2
fi
if [[ "$test_target" != "integration_test/app_test.dart" && \
      "$test_target" != "integration_test/auth_session_isolation_test.dart" && \
      "$test_target" != "integration_test/package_isolation_test.dart" ]]; then
  echo "Refusing an unreviewed UI smoke target." >&2
  exit 2
fi
runtime_auth="${EVERYWEAR_UI_SMOKE_RUNTIME_AUTH:-false}"
credentials_file="${EVERYWEAR_SMOKE_CREDENTIALS_FILE:-$HOME/.config/everywear/staging-smoke-credentials.json}"
if [[ "$runtime_auth" != "true" && "$runtime_auth" != "false" ]]; then
  echo "EVERYWEAR_UI_SMOKE_RUNTIME_AUTH must be true or false." >&2
  exit 2
fi
if [[ "$runtime_auth" == "true" && "$test_target" != "integration_test/app_test.dart" ]]; then
  echo "Runtime credentials are accepted only by the guarded core smoke target." >&2
  exit 2
fi
if [[ "$runtime_auth" == "true" ]]; then
  python3 - "$credentials_file" "$repo_root" <<'PY'
import json, os, pathlib, stat, sys
path = pathlib.Path(sys.argv[1]).resolve(strict=True)
repo = pathlib.Path(sys.argv[2]).resolve()
if os.path.commonpath((str(path), str(repo))) == str(repo):
    raise SystemExit("Keep smoke credentials outside Git.")
if stat.S_IMODE(path.stat().st_mode) != 0o600:
    raise SystemExit("Smoke credentials must have mode 0600.")
try:
    value = json.loads(path.read_text())
except (OSError, json.JSONDecodeError):
    raise SystemExit("Smoke credentials are unreadable or malformed.")
if not isinstance(value, dict) or set(value) != {"login_email", "login_password", "signup_email"}:
    raise SystemExit("Smoke credentials have an unexpected field set.")
if not all(isinstance(value[key], str) and value[key] for key in value):
    raise SystemExit("Smoke credentials have an empty or invalid field.")
if value["login_email"].casefold() == value["signup_email"].casefold():
    raise SystemExit("Login and disposable signup accounts must differ.")
PY
fi

flutter_bin="${FLUTTER_BIN:-$repo_root/.tooling/flutter/bin/flutter}"
adb_bin="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
java21_home="${EVERYWEAR_JAVA21_HOME:-/usr/lib/jvm/java-21-openjdk}"
aapt_bin="${AAPT_BIN:-}"
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
if ! "$java21_home/bin/java" -version 2>&1 | head -n 1 | rg -q 'version "21([.+-]|$)'; then
  echo "The configured Java installation is not Java 21." >&2
  exit 2
fi
if ! rg -q '^org\.gradle\.jvmargs=.*-Xmx2G' "$repo_root/android/gradle.properties" || \
   ! rg -qx 'org\.gradle\.workers\.max=1' "$repo_root/android/gradle.properties"; then
  echo "The Android Gradle configuration must retain a 2 GiB heap and one worker." >&2
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
run_log=""
base_install_time=""
base_version_code=""
base_last_update_time=""
test_package_cleanup=0
cleanup() {
  cleanup_failed=0
  if [[ -n "$logcat_pid" ]]; then
    kill "$logcat_pid" 2>/dev/null || true
    wait "$logcat_pid" 2>/dev/null || true
    logcat_pid=""
    echo "Private device logcat saved at: $logcat_file"
    if [[ -n "$run_log" ]]; then
      echo "Private Flutter runner log saved at: $run_log"
    fi
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
  if [[ "$test_package_cleanup" == "1" && -n "$device_serial" && -x "$adb_bin" ]] && \
    "$adb_bin" -s "$device_serial" get-state >/dev/null 2>&1; then
    "$adb_bin" -s "$device_serial" shell am force-stop "$test_application_id" >/dev/null 2>&1 || true
    "$adb_bin" -s "$device_serial" uninstall "$test_application_id" >/dev/null 2>&1 || true
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
configured_flutter_jdk="$("$flutter_bin" config --list | sed -n 's/^  jdk-dir: //p' | head -n 1)"
if [[ "$configured_flutter_jdk" != "$JAVA_HOME" ]]; then
  echo "Flutter did not select the requested Java 21 installation." >&2
  exit 2
fi

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
    "EVERYWEAR_STAGING_TEST": True,
    "EVERYWEAR_FREE_BETA": True,
    "APP_DISTRIBUTION": "uptodown",
    "REVENUECAT_BILLING_ENVIRONMENT": "unavailable",
    "EVERYWEAR_ADS_ENABLED": False,
    "EVERYWEAR_AD_PROVIDER": "disabled",
})
pathlib.Path(output_path).write_text(json.dumps(config))
PY

android_sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
if [[ -z "$aapt_bin" ]]; then
  aapt_bin="$(find "$android_sdk_root/build-tools" -mindepth 2 -maxdepth 2 -type f -name aapt -print 2>/dev/null | sort -V | tail -n 1)"
fi
if [[ ! -x "$aapt_bin" ]]; then
  echo "Cannot verify the isolated staging APK package ID; set AAPT_BIN to Android build-tools aapt." >&2
  exit 2
fi

build_isolated_apk() {
  (
    cd "$repo_root"
    ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
    ORG_GRADLE_PROJECT_everywearAppLabel="Everywear UI Smoke Test (STAGING)" \
      "$flutter_bin" build apk --debug --no-pub \
        --target="$test_target" \
        --dart-define-from-file="$defines_file"
  )
}

verify_isolated_apk() {
  local candidate="$1"
  if [[ ! -f "$candidate" ]]; then
    echo "The isolated staging APK is missing." >&2
    return 2
  fi
  local package_id
  package_id="$("$aapt_bin" dump badging "$candidate" | sed -n "s/^package: name='\\([^']*\\)'.*/\\1/p" | head -n 1)"
  if [[ "$package_id" != "$test_application_id" ]]; then
    echo "APK identity is unsafe ('$package_id'); expected only '$test_application_id'." >&2
    return 2
  fi
  printf '%s\n' "$package_id"
}

app_apk="$repo_root/build/app/outputs/flutter-apk/app-debug.apk"
if [[ "$prebuild_only" == "true" ]]; then
  if [[ "$test_target" != "integration_test/app_test.dart" ]]; then
    echo "Prebuilt emulator smoke currently supports only the reviewed core integration target." >&2
    exit 2
  fi
  gradle_app_identity="$(
    cd "$repo_root/android"
    ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
      ./gradlew --quiet :app:printEverywearApplicationId
  )"
  if ! printf '%s\n' "$gradle_app_identity" | rg -qx "EVERYWEAR_APPLICATION_ID=$test_application_id" || \
     ! printf '%s\n' "$gradle_app_identity" | rg -qx "EVERYWEAR_NAMESPACE=$test_application_id"; then
    echo "Gradle resolved an unsafe integration-test package or namespace." >&2
    exit 2
  fi
  echo "Prebuilding the isolated integration APK while the emulator is stopped."
  build_isolated_apk
  apk_package_id="$(verify_isolated_apk "$app_apk")"
  apk_label="$("$aapt_bin" dump badging "$app_apk" | sed -n "s/^application-label:'\\(.*\\)'$/\\1/p" | head -n 1)"
  if [[ "$apk_label" != "Everywear UI Smoke Test (STAGING)" ]]; then
    echo "The prebuilt APK does not carry the expected staging-test label." >&2
    exit 2
  fi
  echo "PREBUILT_STAGING_TEST_APK=$app_apk"
  echo "PREBUILT_STAGING_TEST_PACKAGE=$apk_package_id"
  exit 0
fi

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
if [[ -z "$prebuilt_apk" ]]; then
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
else
  # Flutter drive resolves identity from the provided APK and uses that same
  # package for install, launch, stop, and teardown.
  drive_source="$flutter_root/packages/flutter_tools/lib/src/commands/drive.dart"
  drive_service_source="$flutter_root/packages/flutter_tools/lib/src/drive/drive_service.dart"
  android_device_source="$flutter_root/packages/flutter_tools/lib/src/android/android_device.dart"
  for required in \
    "$drive_source|applicationBinary: applicationBinary" \
    "$drive_service_source|var prebuiltApplication = applicationBinary != null;" \
    "$drive_service_source|prebuiltApplication: prebuiltApplication" \
    "$android_device_source|if (!prebuiltApplication ||" \
    "$drive_service_source|await _device!.uninstallApp(package"; do
    source_file="${required%%|*}"
    source_text="${required#*|}"
    if ! rg -Fq "$source_text" "$source_file"; then
      echo "Pinned Flutter does not match the inspected prebuilt drive lifecycle; refusing to run." >&2
      exit 2
    fi
  done
fi

# Flutter's pinned IntegrationTestTestDevice captures the APK package ID
# before AndroidDevice.startApp builds it, then uses that captured package
# object for teardown. If the output APK is still the normal app, Flutter can
# correctly launch .stagingtest and later uninstall the normal package. Build
# the isolated APK first so package resolution and teardown see the same ID.
if [[ -n "$prebuilt_apk" ]]; then
  app_apk="$(realpath "$prebuilt_apk")"
  apk_package_id="$(verify_isolated_apk "$app_apk")"
else
  echo "Building the isolated APK before Flutter resolves its cleanup package."
  build_isolated_apk
  apk_package_id="$(verify_isolated_apk "$app_apk")"
fi
echo "FLUTTER_RESOLVED_PACKAGE_ID_BEFORE_LAUNCH=$apk_package_id"
echo "Flutter resolves this prebuilt APK package before launch and retains it for teardown."
if [[ "$runtime_auth" == "true" ]]; then
  # Install the exact debug-signed APK before Flutter starts so credentials
  # enter only the isolated package's private files. The later Flutter install
  # is -r with the same signature; teardown removes only the test package.
  "$adb_bin" -s "$device_serial" uninstall "$test_application_id" >/dev/null 2>&1 || true
  test_package_cleanup=1
  "$adb_bin" -s "$device_serial" install "$app_apk" >/dev/null
  EVERYWEAR_SMOKE_CREDENTIALS_FILE="$credentials_file" \
  EVERYWEAR_SMOKE_PACKAGE="$test_application_id" \
  EVERYWEAR_ADB_BIN="$adb_bin" \
  EVERYWEAR_EMULATOR_SERIAL="$device_serial" \
    python3 - <<'PY'
import json, os, subprocess
with open(os.environ['EVERYWEAR_SMOKE_CREDENTIALS_FILE'], encoding='utf-8') as source:
    credentials = json.load(source)
payload = json.dumps({
    'login_email': credentials['login_email'],
    'login_password': credentials['login_password'],
}, separators=(',', ':')).encode('utf-8')
package = os.environ['EVERYWEAR_SMOKE_PACKAGE']
provision = (
    "umask 077; mkdir -p no_backup && "
    "cat > no_backup/.everywear_smoke_login_credentials.tmp && "
    "chmod 600 no_backup/.everywear_smoke_login_credentials.tmp && "
    "mv no_backup/.everywear_smoke_login_credentials.tmp "
    "no_backup/everywear_smoke_login_credentials.json"
)
command = (
    f"run-as {package} sh -c '{provision}'"
)
try:
    result = subprocess.run(
        [os.environ['EVERYWEAR_ADB_BIN'], '-s',
         os.environ['EVERYWEAR_EMULATOR_SERIAL'], 'shell', '-T', command],
        input=payload,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=20,
        check=False,
    )
except (OSError, subprocess.SubprocessError):
    raise SystemExit('Could not provision private credentials to the isolated emulator app.')
if result.returncode != 0:
    raise SystemExit('Could not provision private credentials to the isolated emulator app.')
verification = (
    f"run-as {package} sh -c 'test -s no_backup/everywear_smoke_login_credentials.json && "
    "test \"$(stat -c %a no_backup/everywear_smoke_login_credentials.json)\" = 600'"
)
try:
    checked = subprocess.run(
        [os.environ['EVERYWEAR_ADB_BIN'], '-s',
         os.environ['EVERYWEAR_EMULATOR_SERIAL'], 'shell', '-T', verification],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=20,
        check=False,
    )
except (OSError, subprocess.SubprocessError):
    raise SystemExit('Could not verify private staging credential provisioning.')
if checked.returncode != 0:
    raise SystemExit('Could not verify private staging credential provisioning.')
PY
fi
old_stay_on="$("$adb_bin" -s "$device_serial" shell settings get global stay_on_while_plugged_in | tr -d '\r')"
restore_stay_on=1
"$adb_bin" -s "$device_serial" shell svc power stayon usb

umask 077
logcat_file="/tmp/everywear-a065-ui-smoke-$(date +%Y%m%d-%H%M%S)-$$.log"
run_log="/tmp/everywear-full-isolated-smoke-$(date +%Y%m%d-%H%M%S)-$$.log"
: > "$run_log"
chmod 600 "$run_log"
printf 'FLUTTER_RESOLVED_PACKAGE_ID_BEFORE_LAUNCH=%s\n' "$apk_package_id" >> "$run_log"
if [[ "$runtime_auth" == "true" ]]; then
  # Runtime auth is deliberately excluded from device log capture so a
  # platform/library diagnostic cannot accidentally persist a password.
  logcat_file=""
else
  : > "$logcat_file"
  chmod 600 "$logcat_file"
  "$adb_bin" -s "$device_serial" logcat -T 1 -v epoch >"$logcat_file" 2>&1 &
  logcat_pid=$!
fi

cd "$repo_root"
set +e
if [[ -n "$prebuilt_apk" ]]; then
  "$flutter_bin" drive --no-pub --no-build \
    --use-application-binary="$app_apk" \
    --driver=test_driver/integration_test.dart \
    --target="$test_target" \
    --device-id="$device_serial" \
    --dart-define-from-file="$defines_file" 2>&1 | tee -a "$run_log"
else
  ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
    "$flutter_bin" test --no-pub "$test_target" \
      --device-id "$device_serial" \
      --dart-define-from-file="$defines_file" 2>&1 | tee -a "$run_log"
fi
test_status=${PIPESTATUS[0]}
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
test_package_cleanup=0
echo "Verified normal app package unchanged: $normal_application_id ($base_version_code; install $base_install_time; update $base_last_update_time)."
echo "Verified Flutter cleanup removed the isolated test package: $test_application_id."
if [[ -n "$logcat_file" ]] && rg -n "force-stop ['\"]?$normal_application_id(['\"[:space:]]|$)|Force stopping $normal_application_id([[:space:]]|$)|package ['\"]uninstall['\"] ['\"]?$normal_application_id(['\"[:space:]]|$)|handlePackageRemove: removing $normal_application_id([[:space:]]|$)|ACTION_PACKAGE_FULLY_REMOVED pkg=$normal_application_id([[:space:]]|$)" "$logcat_file"; then
  echo "FAIL: device log shows a stop/removal operation for the normal app." >&2
  exit 1
fi
if [[ "$test_target" == "integration_test/package_isolation_test.dart" ]]; then
  if ! rg -q -F "FLUTTER_RESOLVED_PACKAGE_ID_BEFORE_LAUNCH=$test_application_id" "$run_log"; then
    echo "FAIL: the test log lacks the pre-launch package identity evidence." >&2
    exit 1
  fi
  if ! rg -q "cmd package .*uninstall.*$test_application_id|adb uninstall .*${test_application_id}" "$logcat_file" "$run_log"; then
    echo "FAIL: no teardown uninstall for the isolated package was observed." >&2
    exit 1
  fi
  if rg -n "(force-stop|uninstall)[^\n]*$normal_application_id(['\"[:space:]]|$)" "$run_log" "$logcat_file"; then
    echo "FAIL: runner logs show a package operation targeting the normal app." >&2
    exit 1
  fi
fi
if [[ "$test_status" != "0" ]]; then
  exit "$test_status"
fi

echo "Isolated UI smoke passed under $test_application_id; normal app remains installed."
