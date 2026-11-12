#!/usr/bin/env bash
set -euo pipefail

# Run only against a disposable local Supabase/Postgres database after applying
# the complete reviewed migration chain. This refuses non-loopback endpoints.
: "${EVERYWEAR_TEST_DATABASE_URL:?Set this to a disposable local database URL}"

python3 - <<'PY'
import ipaddress
import os
import sys
import urllib.parse

host = urllib.parse.urlsplit(os.environ["EVERYWEAR_TEST_DATABASE_URL"]).hostname
try:
    is_local = host is not None and ipaddress.ip_address(host).is_loopback
except ValueError:
    is_local = host == "localhost"
if not is_local:
    sys.exit("Refusing non-local database host.")
PY

fixture_user="$(python3 -c 'import uuid; print(uuid.uuid4())')"
scratch_dir="$(mktemp -d)"

cleanup() {
  if [[ -n "$fixture_user" ]]; then
    psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "DELETE FROM auth.users WHERE id = '$fixture_user'::uuid" \
      >/dev/null 2>&1 || true
  fi
  rm -rf "$scratch_dir"
}
trap cleanup EXIT

psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -v fixture_user="$fixture_user" <<'SQL'
INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  :'fixture_user', 'authenticated', 'authenticated',
  :'fixture_user' || '@quota-test.invalid', '', now(), '{}', '{}', now(), now()
);

UPDATE public.user_profiles
SET tier = 'free', daily_suggestions_used = 0,
    suggestions_reset_at = current_date,
    coaching_sessions_used = 0, coaching_reset_at = now()
WHERE id = :'fixture_user';
SQL

profile_count="$(psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "SELECT count(*) FROM public.user_profiles WHERE id = '$fixture_user'::uuid")"
if [[ "$profile_count" != 1 ]]; then
  echo "Test user did not receive exactly one profile." >&2
  exit 1
fi

run_concurrent_quota_check() {
  local quota_kind="$1"
  local release_file="$scratch_dir/release-$quota_kind"
  local output_a="$scratch_dir/$quota_kind-a"
  local output_b="$scratch_dir/$quota_kind-b"

  (
    while [[ ! -e "$release_file" ]]; do sleep 0.01; done
    psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "BEGIN;
          SET LOCAL ROLE authenticated;
          SELECT set_config('request.jwt.claim.sub', '$fixture_user', true);
          SELECT public.consume_ai_quota('$quota_kind');
          COMMIT;" |
      awk '$0 == "t" || $0 == "f" { print }' >"$output_a"
  ) &
  local pid_a=$!

  (
    while [[ ! -e "$release_file" ]]; do sleep 0.01; done
    psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "BEGIN;
          SET LOCAL ROLE authenticated;
          SELECT set_config('request.jwt.claim.sub', '$fixture_user', true);
          SELECT public.consume_ai_quota('$quota_kind');
          COMMIT;" |
      awk '$0 == "t" || $0 == "f" { print }' >"$output_b"
  ) &
  local pid_b=$!

  touch "$release_file"
  local process_status=0
  wait "$pid_a" || process_status=1
  wait "$pid_b" || process_status=1
  if [[ "$process_status" != 0 ]]; then
    echo "One or both $quota_kind quota sessions failed." >&2
    return 1
  fi

  local successes
  local denials
  successes="$(cat "$output_a" "$output_b" | grep -cx 't' || true)"
  denials="$(cat "$output_a" "$output_b" | grep -cx 'f' || true)"
  if [[ "$successes" != 1 || "$denials" != 1 ]]; then
    echo "Concurrent $quota_kind quota expected one success and one denial; got $successes success(es), $denials denial(s)." >&2
    return 1
  fi
  echo "Concurrent $quota_kind quota: one success, one denial."
}

run_concurrent_quota_check suggestion
run_concurrent_quota_check coach
