#!/usr/bin/env bash

# adb shell pm path returns status 1 with empty output when a package is not
# installed. Normalize only that expected absence; preserve real adb errors.
read_android_package_path() {
  if [[ "$#" -ne 3 ]]; then
    echo "read_android_package_path expects adb, serial, and package ID." >&2
    return 2
  fi

  local adb_bin="$1"
  local device_serial="$2"
  local package_id="$3"
  local output
  local command_status

  if output="$("$adb_bin" -s "$device_serial" shell pm path "$package_id" 2>&1)"; then
    command_status=0
  else
    command_status=$?
  fi
  output="${output//$'\r'/}"

  if [[ "$command_status" -eq 0 ]]; then
    printf '%s' "$output"
    return 0
  fi
  if [[ "$command_status" -eq 1 && -z "$output" ]]; then
    return 0
  fi

  echo "adb could not inspect package $package_id (exit $command_status)." >&2
  return "$command_status"
}
