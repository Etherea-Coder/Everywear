-- Disposable local PostgreSQL only. Run after the refund migration.
BEGIN;
SELECT plan(30);
INSERT INTO auth.users (id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES ('77777777-7777-4777-8777-777777777777', 'authenticated',
  'authenticated', 'coach-refund@example.invalid', '', now(), '{}', '{}', now(), now());

SELECT ok(NOT has_function_privilege('authenticated',
  'public.finalize_style_coach_action(uuid,uuid,text,text)', 'EXECUTE'),
  'authenticated users cannot invoke the refund finalizer');
SELECT ok(NOT has_function_privilege('authenticated',
  'public.reconcile_stale_style_coach_actions(uuid)', 'EXECUTE'),
  'authenticated users cannot reconcile provider outcomes');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','77777777-7777-4777-8777-777777777777',true);
SELECT is(public.get_ai_allowance()->>'month_used','0','before reservation quota is untouched');
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000001','style-coach')->>'allowed')::boolean,
  'valid coach request reserves once');
SELECT throws_ok(
  $$SELECT public.finalize_ai_action('10000000-0000-4000-8000-000000000001','provider_error','provider_rejected')$$,
  '42501', 'coach finalization is server-only',
  'caller JWT cannot finalize or refund a coach action');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT ok(public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000001','succeeded',NULL), 'success finalizes');
SELECT ok(NOT public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000001','provider_error','provider_rejected'),
  'duplicate failure cannot reverse success');
RESET ROLE;
SELECT is((SELECT month_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'successful action remains charged');
UPDATE public.ai_usage_buckets SET burst_start=now()-interval '1 minute'
  WHERE user_id='77777777-7777-4777-8777-777777777777';

SET LOCAL ROLE authenticated;
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000002','style-coach')->>'allowed')::boolean,
  'second coach request reserves in a new burst window');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT ok(public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000002','provider_error','provider_rejected'),
  'provider error finalizes and refunds');
RESET ROLE;
SELECT is((SELECT month_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'provider error restores monthly allowance');
SELECT is((SELECT day_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'provider error restores daily allowance');
SELECT is((SELECT burst_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'provider error retains burst protection');
SET LOCAL ROLE authenticated;
SELECT is(public.reserve_ai_action('10000000-0000-4000-8000-000000000003','style-coach')->>'reason',
  'burst','immediate retry is burst limited');
RESET ROLE;

-- Reserve in a new minute, then move only the recorded day behind the
-- current bucket to simulate a finalization after UTC day rollover.
UPDATE public.ai_usage_buckets SET burst_start=now()-interval '1 minute'
  WHERE user_id='77777777-7777-4777-8777-777777777777';
SET LOCAL ROLE authenticated;
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000004','style-coach')->>'allowed')::boolean,
  'timeout request reserves');
RESET ROLE;
UPDATE public.ai_action_reservations SET reserved_day_start=(now() AT TIME ZONE 'UTC')::date-1
  WHERE request_id='10000000-0000-4000-8000-000000000004';
SET LOCAL ROLE service_role;
SELECT ok(public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000004','timeout','timeout'),
  'timeout finalizes after day rollover');
RESET ROLE;
SELECT is((SELECT day_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),2,
  'old-day refund does not subtract from the new day');
SELECT is((SELECT month_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'same-month timeout restores original monthly allowance');

UPDATE public.ai_usage_buckets SET burst_start=now()-interval '1 minute'
  WHERE user_id='77777777-7777-4777-8777-777777777777';
SET LOCAL ROLE authenticated;
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000005','style-coach')->>'allowed')::boolean,
  'invalid-response request reserves');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT ok(public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000005','invalid_response','invalid_response'),
  'invalid response finalizes');
SELECT ok(NOT public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000005','invalid_response','invalid_response'),
  'duplicate failure cannot double refund');
RESET ROLE;
SELECT is((SELECT month_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),1,
  'invalid response restores monthly allowance exactly once');
SELECT is((SELECT day_used FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),2,
  'invalid response restores daily allowance exactly once');

UPDATE public.ai_usage_buckets SET burst_start=now()-interval '1 minute'
  WHERE user_id='77777777-7777-4777-8777-777777777777';
SET LOCAL ROLE authenticated;
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000006','style-coach')->>'allowed')::boolean,
  'month-rollover request reserves');
RESET ROLE;
UPDATE public.ai_action_reservations SET
  reserved_month_start=(date_trunc('month', now() AT TIME ZONE 'UTC')-interval '1 month')::date,
  reserved_day_start=(now() AT TIME ZONE 'UTC')::date-1
  WHERE request_id='10000000-0000-4000-8000-000000000006';
SET LOCAL ROLE service_role;
SELECT ok(public.finalize_style_coach_action('77777777-7777-4777-8777-777777777777',
  '10000000-0000-4000-8000-000000000006','provider_error','provider_rejected'),
  'old-month failure finalizes');
RESET ROLE;
SELECT ok((SELECT month_used=2 AND day_used=3 FROM public.ai_usage_buckets
  WHERE user_id='77777777-7777-4777-8777-777777777777'),
  'old-window refund cannot alter current month or day');

UPDATE public.ai_usage_buckets SET
  month_start=(date_trunc('month',now() AT TIME ZONE 'UTC')-interval '1 month')::date,
  day_start=(now() AT TIME ZONE 'UTC')::date-1,
  burst_start=now()-interval '1 minute'
  WHERE user_id='77777777-7777-4777-8777-777777777777';
SET LOCAL ROLE authenticated;
SELECT ok((public.reserve_ai_action('10000000-0000-4000-8000-000000000007','style-coach')->>'allowed')::boolean,
  'interrupted request reserves');
RESET ROLE;
UPDATE public.ai_action_reservations SET created_at=now()-interval '31 seconds'
  WHERE request_id='10000000-0000-4000-8000-000000000007';
SET LOCAL ROLE service_role;
SELECT is(public.reconcile_stale_style_coach_actions('77777777-7777-4777-8777-777777777777'),
  1,'stale interrupted request is closed once');
SELECT is(public.reconcile_stale_style_coach_actions('77777777-7777-4777-8777-777777777777'),
  0,'stale reconciliation is idempotent');
RESET ROLE;
SELECT ok((SELECT status='internal_error' AND finalized_at IS NOT NULL
  FROM public.ai_action_reservations
  WHERE request_id='10000000-0000-4000-8000-000000000007')
  AND (SELECT month_used=1 AND day_used=1 AND burst_used=1
  FROM public.ai_usage_buckets WHERE user_id='77777777-7777-4777-8777-777777777777'),
  'unknown interrupted outcome retains charge and releases reserved status');
SELECT * FROM finish();
ROLLBACK;
