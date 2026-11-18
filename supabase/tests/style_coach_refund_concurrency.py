#!/usr/bin/env python3
"""Two-connection refund fixture; refuses anything outside local disposable PG."""
import concurrent.futures
import ipaddress
import os
import pathlib
import subprocess
import urllib.parse
import uuid

url = os.environ["EVERYWEAR_TEST_DATABASE_URL"]
parsed = urllib.parse.urlsplit(url)
if (not parsed.hostname or
        not ipaddress.ip_address(parsed.hostname).is_loopback or
        not parsed.path.startswith("/everywear_coach_refund_")):
    raise SystemExit("Refusing non-disposable local database.")
psql = pathlib.Path(__file__).resolve().parents[2] / ".tooling/local-postgres/install/bin/psql"
uid = str(uuid.uuid4())
request_id = str(uuid.uuid4())


def query(sql):
    result = subprocess.run(
        [str(psql), "-XAt", "-v", "ON_ERROR_STOP=1", url, "-c", sql],
        capture_output=True, text=True, check=False, timeout=20,
    )
    if result.returncode:
        raise RuntimeError("Local PostgreSQL fixture query failed.")
    return result.stdout.strip().splitlines()


try:
    query(f"""INSERT INTO auth.users (id,aud,role,email,encrypted_password,
      email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
      VALUES ('{uid}','authenticated','authenticated',
      '{uid}@coach-refund.invalid','',now(),'{{}}','{{}}',now(),now());""")
    result = query(f"""BEGIN; SET LOCAL ROLE authenticated;
      SELECT set_config('request.jwt.claim.sub','{uid}',true);
      SELECT public.reserve_ai_action('{request_id}','style-coach')->>'allowed';
      COMMIT;""")
    if "true" not in result:
        raise RuntimeError("Local coach reservation was denied.")

    def finalize(_):
        return query(f"""BEGIN; SET LOCAL ROLE service_role;
          SELECT public.finalize_style_coach_action(
            '{uid}','{request_id}','provider_error','provider_rejected');
          COMMIT;""")

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        outcomes = list(executor.map(finalize, range(2)))
    booleans = sorted(value for lines in outcomes for value in lines if value in ("t", "f"))
    if booleans != ["f", "t"]:
        raise RuntimeError("Concurrent finalization did not yield one transition.")
    state = query(f"""SELECT month_used,day_used,burst_used FROM public.ai_usage_buckets
      WHERE user_id='{uid}';""")
    ledger = query(f"""SELECT status,allowance_refunded_at IS NOT NULL
      FROM public.ai_action_reservations WHERE user_id='{uid}';""")
    if state != ["0|0|1"] or ledger != ["provider_error|t"]:
        raise RuntimeError("Concurrent finalization changed counters more than once.")
    print("CONCURRENT_COACH_FINALIZATION=PASS one transition, one refund, burst retained")
finally:
    query(f"DELETE FROM auth.users WHERE id='{uid}';")
