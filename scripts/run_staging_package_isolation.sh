#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
source "$repo_root/scripts/lib/android_package_path.sh"
project_ref="${EVERYWEAR_STAGE_PROJECT_REF:-}"
device_serial="${EVERYWEAR_UI_SMOKE_DEVICE_SERIAL:-}"
if [[ "$project_ref" != "aftdbphdobfrshienple" ]]; then
  echo "Set EVERYWEAR_STAGE_PROJECT_REF to the approved staging project ref." >&2
  exit 2
fi
if [[ -z "$device_serial" ]]; then
  echo "Set EVERYWEAR_UI_SMOKE_DEVICE_SERIAL to the authorized device serial." >&2
  exit 2
fi

normal_application_id="com.stylewise.app"
test_application_id="com.stylewise.app.stagingtest"
flutter_bin="${FLUTTER_BIN:-$repo_root/.tooling/flutter/bin/flutter}"
adb_bin="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
java21_home="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk}"
flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd)"
flutter_android_package_source="$flutter_root/packages/flutter_tools/lib/src/android/application_package.dart"
flutter_integration_source="$flutter_root/packages/flutter_tools/lib/src/test/integration_test_device.dart"
flutter_android_device_source="$flutter_root/packages/flutter_tools/lib/src/android/android_device.dart"

if [[ "$normal_application_id" == "$test_application_id" ]]; then
  echo "Refusing a package-isolation run against the normal app ID." >&2
  exit 2
fi
if [[ ! -x "$java21_home/bin/java" || ! -x "$adb_bin" ]]; then
  echo "Java 21 or adb is unavailable." >&2
  exit 2
fi
for source in "$flutter_android_package_source" "$flutter_integration_source" "$flutter_android_device_source"; do
  if [[ ! -f "$source" ]]; then
    echo "Cannot inspect a required pinned Flutter package-operation source." >&2
    exit 2
  fi
done

# Pin this run to the reviewed runner paths: package resolution (APK ID or
# namespace fallback), start/install/launch, then stop/uninstall the same
# package object held by IntegrationTestTestDevice.
rg -q "manifests\.first\.getAttribute\('package'\) \?\? androidProject\.namespace" "$flutter_android_package_source"
rg -q 'getPackageForPlatform\(' "$flutter_integration_source"
rg -q 'device\.startApp\(' "$flutter_integration_source"
rg -q 'device\.stopApp\(applicationPackage' "$flutter_integration_source"
rg -q 'device\.uninstallApp\(applicationPackage' "$flutter_integration_source"
rg -q "'install'," "$flutter_android_device_source"
rg -q 'builtPackage\.launchActivity' "$flutter_android_device_source"
rg -q 'app\.id,' "$flutter_android_device_source"

export JAVA_HOME="$java21_home"
export PATH="$JAVA_HOME/bin:$PATH"
old_flutter_jdk="$("$flutter_bin" config --list | sed -n 's/^  jdk-dir: //p' | head -n 1)"
restore_flutter_jdk=0
logcat_file=""
logcat_pid=""
run_log=""
cleanup() {
  if [[ -n "$logcat_pid" ]]; then
    kill "$logcat_pid" 2>/dev/null || true
    wait "$logcat_pid" 2>/dev/null || true
    echo "Private continuous package-operation logcat: $logcat_file"
  fi
  if [[ "$restore_flutter_jdk" == "1" ]]; then
    "$flutter_bin" config --jdk-dir="$old_flutter_jdk" >/dev/null || \
      echo "WARNING: could not restore Flutter's previous JDK override." >&2
  fi
}
trap cleanup EXIT
restore_flutter_jdk=1
"$flutter_bin" config --jdk-dir="$JAVA_HOME" >/dev/null

device_count="$("$adb_bin" devices | awk -v serial="$device_serial" '$1 == serial && $2 == "device" { n++ } END { print n+0 }')"
if [[ "$device_count" != "1" ]]; then
  echo "The selected Android device is not uniquely connected and authorized." >&2
  exit 2
fi

if ! normal_apk_path="$(read_android_package_path "$adb_bin" "$device_serial" "$normal_application_id")"; then
  echo "Cannot query the normal app package; refusing the isolation test." >&2
  exit 2
fi
if [[ -z "$normal_apk_path" ]]; then
  echo "Normal app is not installed; refusing the isolation test." >&2
  exit 2
fi
normal_package_dump="$("$adb_bin" -s "$device_serial" shell dumpsys package "$normal_application_id")"
normal_first_install="$(printf '%s\n' "$normal_package_dump" | sed -n 's/^ *firstInstallTime=//p' | head -n 1)"
normal_version="$(printf '%s\n' "$normal_package_dump" | sed -n 's/^ *versionCode=\([^ ]*\).*/\1/p' | head -n 1)"
normal_last_update="$(printf '%s\n' "$normal_package_dump" | sed -n 's/^ *lastUpdateTime=//p' | head -n 1)"
if [[ -z "$normal_first_install" || -z "$normal_version" || -z "$normal_last_update" ]]; then
  echo "Cannot record normal app package identity; refusing the isolation test." >&2
  exit 2
fi

gradle_identity="$(
  cd "$repo_root/android"
  JAVA_HOME="$JAVA_HOME" PATH="$JAVA_HOME/bin:$PATH" \
    ORG_GRADLE_PROJECT_everywearStagingTestApplication=true \
    ./gradlew --no-daemon --max-workers=1 --quiet :app:printEverywearApplicationId
)"
if ! printf '%s\n' "$gradle_identity" | rg -qx "EVERYWEAR_APPLICATION_ID=$test_application_id" || \
  ! printf '%s\n' "$gradle_identity" | rg -qx "EVERYWEAR_NAMESPACE=$test_application_id"; then
  echo "Gradle package ID/namespace is unsafe; refusing before installation." >&2
  exit 2
fi

umask 077
logcat_file="/tmp/everywear-a065-package-isolation-$(date +%Y%m%d-%H%M%S)-$$.log"
run_log="/tmp/everywear-package-isolation-run-$(date +%Y%m%d-%H%M%S)-$$.log"
: > "$logcat_file"
: > "$run_log"
chmod 600 "$logcat_file"
chmod 600 "$run_log"
"$adb_bin" -s "$device_serial" logcat -T 1 -v epoch >"$logcat_file" 2>&1 &
logcat_pid=$!

set +e
(
  cd "$repo_root"
  export ORG_GRADLE_PROJECT_everywearStagingTestApplication=true
  export ORG_GRADLE_PROJECT_everywearAppLabel="Everywear UI Smoke Test (STAGING)"
  "$flutter_bin" test --no-pub --verbose \
    integration_test/package_isolation_test.dart \
    --device-id "$device_serial" \
    --dart-define=EVERYWEAR_STAGING=true
) 2>&1 | tee "$run_log"
test_status=${PIPESTATUS[0]}
set -e
echo "Private Flutter runner log: $run_log"
echo "Flutter CLI exit status: $test_status"

device_count_after="$("$adb_bin" devices | awk -v serial="$device_serial" '$1 == serial && $2 == "device" { n++ } END { print n+0 }')"
if [[ "$device_count_after" != "1" ]]; then
  echo "The selected device disconnected during the isolation test." >&2
  exit 1
fi
if ! normal_apk_path_after="$(read_android_package_path "$adb_bin" "$device_serial" "$normal_application_id")"; then
  echo "Could not verify the normal app package after the isolation test." >&2
  exit 1
fi
normal_package_dump_after="$("$adb_bin" -s "$device_serial" shell dumpsys package "$normal_application_id" 2>&1 || true)"
normal_first_install_after="$(printf '%s\n' "$normal_package_dump_after" | sed -n 's/^ *firstInstallTime=//p' | head -n 1)"
normal_version_after="$(printf '%s\n' "$normal_package_dump_after" | sed -n 's/^ *versionCode=\([^ ]*\).*/\1/p' | head -n 1)"
normal_last_update_after="$(printf '%s\n' "$normal_package_dump_after" | sed -n 's/^ *lastUpdateTime=//p' | head -n 1)"
if ! test_apk_path_after="$(read_android_package_path "$adb_bin" "$device_serial" "$test_application_id")"; then
  echo "Could not verify isolated test package cleanup." >&2
  exit 1
fi

if [[ -z "$normal_apk_path_after" || "$normal_first_install_after" != "$normal_first_install" || "$normal_version_after" != "$normal_version" || "$normal_last_update_after" != "$normal_last_update" ]]; then
  echo "FAIL: normal app package changed during the package-isolation test." >&2
  exit 1
fi
if [[ -n "$test_apk_path_after" ]]; then
  echo "FAIL: Flutter did not clean up the isolated test package." >&2
  exit 1
fi

if rg -n "force-stop ['\"]?$normal_application_id(['\"[:space:]]|$)|Force stopping $normal_application_id([[:space:]]|$)|package ['\"]uninstall['\"] ['\"]?$normal_application_id(['\"[:space:]]|$)|handlePackageRemove: removing $normal_application_id([[:space:]]|$)|ACTION_PACKAGE_FULLY_REMOVED pkg=$normal_application_id([[:space:]]|$)" "$logcat_file"; then
  echo "FAIL: device logs show a stop/removal operation for the normal package." >&2
  exit 1
fi
if ! rg -q -F "$test_application_id" "$logcat_file"; then
  echo "WARNING: logcat had no test-package operation text; inspect Flutter verbose output." >&2
fi
if [[ "$test_status" != "0" ]]; then
  echo "FAIL: Flutter CLI returned nonzero after the integration test completed." >&2
  exit "$test_status"
fi

echo "PASS: minimal integration test launched; Flutter cleanup left $normal_application_id installed and removed $test_application_id."
echo "Normal baseline: version=$normal_version firstInstallTime=$normal_first_install lastUpdateTime=$normal_last_update"
