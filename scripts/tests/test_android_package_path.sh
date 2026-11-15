#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
source "$repo_root/scripts/lib/android_package_path.sh"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
fake_adb="$temp_dir/adb"
cat > "$fake_adb" <<'SH'
#!/usr/bin/env bash
printf '%s' "${FAKE_ADB_OUTPUT:-}"
exit "${FAKE_ADB_STATUS:-0}"
SH
chmod +x "$fake_adb"

installed_path="$(FAKE_ADB_STATUS=0 FAKE_ADB_OUTPUT='package:/data/app/base.apk' \
  read_android_package_path "$fake_adb" device com.stylewise.app.stagingtest)"
[[ "$installed_path" == 'package:/data/app/base.apk' ]]

missing_path="$(FAKE_ADB_STATUS=1 FAKE_ADB_OUTPUT= \
  read_android_package_path "$fake_adb" device com.stylewise.app.stagingtest)"
[[ -z "$missing_path" ]]

if FAKE_ADB_STATUS=1 FAKE_ADB_OUTPUT='error: device offline' \
  read_android_package_path "$fake_adb" device com.stylewise.app; then
  echo "Expected a real adb error to remain a failure." >&2
  exit 1
fi

echo 'Android package-path guard passed: installed, expected absence, and adb error cases.'
