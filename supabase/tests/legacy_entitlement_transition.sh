#!/usr/bin/env bash
set -euo pipefail

# Local-only transition fixture. Start from the early app migrations plus the
# recovered legacy profile shape: expiry exists, subscription_status does not.
: "${EVERYWEAR_TEST_DATABASE_URL:?Set a disposable local migration-test URL}"
python3 - <<'PY'
import ipaddress, os, sys, urllib.parse
host = urllib.parse.urlsplit(os.environ['EVERYWEAR_TEST_DATABASE_URL']).hostname
try:
    local = host is not None and ipaddress.ip_address(host).is_loopback
except ValueError:
    local = host == 'localhost'
if not local:
    sys.exit('Refusing non-local database host.')
PY

fixture_user="$(python3 -c 'import uuid; print(uuid.uuid4())')"
cleanup() {
  psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
    -c "DELETE FROM auth.users WHERE id = '$fixture_user'::uuid" \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT

status_column="$(psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='user_profiles' AND column_name='subscription_status'")"
expiry_column="$(psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='user_profiles' AND column_name='subscription_expires_at'")"
if [[ "$status_column" != 0 || "$expiry_column" != 1 ]]; then
  echo "Expected recovered legacy shape (expiry present, status absent)." >&2
  exit 1
fi

psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -v fixture_user="$fixture_user" <<'SQL'
-- The preceding expiry prerequisite added this column to the fresh chain.
CREATE TABLE public.subscription_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  product_id text,
  event_type text,
  store text,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.subscription_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY legacy_transactions_own_read ON public.subscription_transactions
  FOR SELECT TO authenticated USING (user_id = auth.uid());
INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  :'fixture_user', 'authenticated', 'authenticated',
  :'fixture_user' || '@legacy-transition.invalid', '', now(), '{}',
  '{"tier":"premium","subscription_status":"active","subscription_expires_at":"2099-01-01T00:00:00Z"}',
  now(), now()
);
UPDATE public.user_profiles
  SET tier='premium', subscription_expires_at=now()+interval '30 days'
  WHERE id=:'fixture_user';
CREATE FUNCTION public.upgrade_user_to_premium(text)
RETURNS text LANGUAGE sql SECURITY DEFINER SET search_path=public AS
$$ SELECT 'legacy overloaded self-upgrade survived the first cleanup' $$;
GRANT EXECUTE ON FUNCTION public.upgrade_user_to_premium(text) TO authenticated;
SQL

repo_root="$(git rev-parse --show-toplevel)"
psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -f "$repo_root/supabase/migrations/20261111090000_reconstruct_and_secure_backend.sql"

# The status migration must not infer paid status from a legacy premium flag or
# future expiry. The extra text overload simulates an unanticipated RPC variant.
psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "SELECT subscription_status FROM public.user_profiles WHERE id='$fixture_user'::uuid" |
  grep -qx inactive

# Prove rollback restores only the disposable database's pre-migration grant;
# then apply the hardening migration permanently and prove it revokes the path.
psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" <<SQL
BEGIN;
\\i $repo_root/supabase/migrations/20261111120000_lock_entitlement_mutator_grants.sql
DO \$\$ BEGIN
  IF has_function_privilege('authenticated','public.upgrade_user_to_premium(text)','EXECUTE')
  THEN RAISE EXCEPTION 'hardening migration left a client-executable overload'; END IF;
END \$\$;
ROLLBACK;
DO \$\$ BEGIN
  IF NOT has_function_privilege('authenticated','public.upgrade_user_to_premium(text)','EXECUTE')
  THEN RAISE EXCEPTION 'transaction rollback did not restore disposable pre-test grant'; END IF;
END \$\$;
SQL

psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -f "$repo_root/supabase/migrations/20261111120000_lock_entitlement_mutator_grants.sql"
psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -f "$repo_root/supabase/migrations/20261112100000_server_ai_action_quotas.sql"

assert_value() {
  local expected="$1" query="$2" actual
  actual="$(psql -XqAt -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" -c "$query")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected '$expected', received '$actual': $query" >&2
    exit 1
  fi
}

assert_value inactive \
  "SELECT subscription_status FROM public.user_profiles WHERE id='$fixture_user'::uuid"
assert_value premium \
  "SELECT tier FROM public.user_profiles WHERE id='$fixture_user'::uuid"
assert_value f \
  "SELECT has_function_privilege('authenticated','public.upgrade_user_to_premium(text)','EXECUTE')"
if psql -Xq -v ON_ERROR_STOP=1 "$EVERYWEAR_TEST_DATABASE_URL" \
  -c "BEGIN; SET LOCAL ROLE authenticated; SET LOCAL \"request.jwt.claim.sub\"='$fixture_user'; SELECT public.upgrade_user_to_premium('$fixture_user'); COMMIT" \
  >/dev/null 2>&1; then
  echo "Authenticated caller executed the legacy self-upgrade overload." >&2
  exit 1
fi
assert_value free \
  "BEGIN; SET LOCAL ROLE authenticated; SET LOCAL \"request.jwt.claim.sub\"='$fixture_user'; SELECT get_ai_allowance()->>'tier'; COMMIT"
assert_value applied \
  "BEGIN; SET LOCAL ROLE service_role; SELECT apply_subscription_event('legacy-verified-$fixture_user','$fixture_user'::uuid,'VERIFIED_SNAPSHOT',now(),now()+interval '30 days','test-entitlement','{}'::jsonb,'premium','active'); COMMIT"
assert_value premium \
  "BEGIN; SET LOCAL ROLE authenticated; SET LOCAL \"request.jwt.claim.sub\"='$fixture_user'; SELECT get_ai_allowance()->>'tier'; COMMIT"

echo "Legacy entitlement transition passed: no implicit premium backfill; verified service event restores premium; rollback and overload revocation verified."
