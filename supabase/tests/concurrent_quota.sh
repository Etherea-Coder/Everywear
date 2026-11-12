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
request_a="$(python3 -c 'import uuid; print(uuid.uuid4())')"
request_b="$(python3 -c 'import uuid; print(uuid.uuid4())')"
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
SET tier = 'free', subscription_status = 'inactive', subscription_expires_at = NULL
WHERE id = :'fixture_user';
DELETE FROM public.ai_usage_buckets WHERE user_id = :'fixture_user';
DELETE FROM public.ai_action_reservations WHERE user_id = :'fixture_user';
SQL

profile_count="$(psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "SELECT count(*) FROM public.user_profiles WHERE id = '$fixture_user'::uuid")"
if [[ "$profile_count" != 1 ]]; then
  echo "Test user did not receive exactly one profile." >&2
  exit 1
fi

run_concurrent_quota_check() {
  local release_file="$scratch_dir/release"
  local output_a="$scratch_dir/action-a"
  local output_b="$scratch_dir/action-b"

  (
    while [[ ! -e "$release_file" ]]; do sleep 0.01; done
    psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "BEGIN;
          SET LOCAL ROLE authenticated;
          SELECT set_config('request.jwt.claim.sub', '$fixture_user', true);
          SELECT CASE (public.reserve_ai_action('$request_a', 'today-suggestion')->>'allowed')::boolean
            WHEN true THEN 'true' ELSE 'false' END;
          COMMIT;" |
      awk '$0 == "true" || $0 == "false" { print }' >"$output_a"
  ) &
  local pid_a=$!

  (
    while [[ ! -e "$release_file" ]]; do sleep 0.01; done
    psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "BEGIN;
          SET LOCAL ROLE authenticated;
          SELECT set_config('request.jwt.claim.sub', '$fixture_user', true);
          SELECT CASE (public.reserve_ai_action('$request_b', 'style-coach')->>'allowed')::boolean
            WHEN true THEN 'true' ELSE 'false' END;
          COMMIT;" |
      awk '$0 == "true" || $0 == "false" { print }' >"$output_b"
  ) &
  local pid_b=$!

  touch "$release_file"
  local process_status=0
  wait "$pid_a" || process_status=1
  wait "$pid_b" || process_status=1
  if [[ "$process_status" != 0 ]]; then
    echo "One or both AI quota sessions failed." >&2
    return 1
  fi

  local successes
  local denials
  successes="$(cat "$output_a" "$output_b" | grep -cx 'true' || true)"
  denials="$(cat "$output_a" "$output_b" | grep -cx 'false' || true)"
  if [[ "$successes" != 1 || "$denials" != 1 ]]; then
    echo "Concurrent free-tier burst expected one success and one denial; got $successes success(es), $denials denial(s)." >&2
    return 1
  fi
  echo "Concurrent free-tier burst reservation: one success, one denial."
}

run_concurrent_quota_check

# Exercise the premium in-flight cap independently from monthly/day/burst
# limits. Four simultaneous reservations must leave exactly three active.
concurrency_requests=(
  "$(python3 -c 'import uuid; print(uuid.uuid4())')"
  "$(python3 -c 'import uuid; print(uuid.uuid4())')"
  "$(python3 -c 'import uuid; print(uuid.uuid4())')"
  "$(python3 -c 'import uuid; print(uuid.uuid4())')"
)
psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "UPDATE public.user_profiles SET tier = 'premium', subscription_status = 'active',
        subscription_expires_at = now() + interval '1 day' WHERE id = '$fixture_user';
      DELETE FROM public.ai_action_reservations WHERE user_id = '$fixture_user';
      DELETE FROM public.ai_usage_buckets WHERE user_id = '$fixture_user';"

release_file="$scratch_dir/concurrency-release"
outputs=("$scratch_dir/concurrency-1" "$scratch_dir/concurrency-2" \
  "$scratch_dir/concurrency-3" "$scratch_dir/concurrency-4")
pids=()
for index in 0 1 2 3; do
  (
    while [[ ! -e "$release_file" ]]; do sleep 0.01; done
    psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
      -c "BEGIN;
          SET LOCAL ROLE authenticated;
          SELECT set_config('request.jwt.claim.sub', '$fixture_user', true);
          SELECT CASE (public.reserve_ai_action('${concurrency_requests[$index]}', 'style-coach')->>'allowed')::boolean
            WHEN true THEN 'true' ELSE 'false' END;
          COMMIT;" |
      awk '$0 == "true" || $0 == "false" { print }' >"${outputs[$index]}"
  ) &
  pids+=("$!")
done
touch "$release_file"
process_status=0
for pid in "${pids[@]}"; do wait "$pid" || process_status=1; done
if [[ "$process_status" != 0 ]]; then
  echo "One or more premium concurrency sessions failed." >&2
  exit 1
fi
concurrency_successes="$(cat "${outputs[@]}" | grep -cx 'true' || true)"
concurrency_denials="$(cat "${outputs[@]}" | grep -cx 'false' || true)"
if [[ "$concurrency_successes" != 3 || "$concurrency_denials" != 1 ]]; then
  echo "Premium concurrency cap expected three successes and one denial; got $concurrency_successes success(es), $concurrency_denials denial(s)." >&2
  exit 1
fi
echo "Concurrent premium reservations: three successes, one concurrency denial."
