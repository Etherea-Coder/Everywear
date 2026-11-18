-- Local-only pgTAP fixture. Never run against the recovered production project.
-- Runs after the complete migration chain in a disposable local database.
BEGIN;
SELECT plan(48);

INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES
  ('11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
   'recovery-a@example.invalid', '', now(), '{}',
   '{"tier":"premium","subscription_status":"active","subscription_expires_at":"2099-01-01T00:00:00Z","items_limit":999999,"monthly_suggestions_used":0}', now(), now()),
  ('22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated',
   'recovery-b@example.invalid', '', now(), '{}', '{}', now(), now());

INSERT INTO public.wardrobe_items (id, user_id, name, category)
VALUES
  ('33333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111', 'Fixture item A', 'Tops'),
  ('44444444-4444-4444-8444-444444444444', '22222222-2222-4222-8222-222222222222', 'Fixture item B', 'Tops');

SELECT ok(
  NOT has_column_privilege('authenticated', 'public.user_profiles', 'tier', 'UPDATE'),
  'authenticated cannot update the tier column'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);

SELECT is(
  (SELECT count(*)::integer FROM public.user_profiles WHERE id = '11111111-1111-4111-8111-111111111111'),
  1,
  'user A can read their own profile'
);
SELECT is(
  (SELECT count(*)::integer FROM public.user_profiles WHERE id = '22222222-2222-4222-8222-222222222222'),
  0,
  'user A cannot read user B profile'
);

INSERT INTO public.outfit_logs (id, user_id, occasion)
VALUES ('55555555-5555-4555-8555-555555555555', '11111111-1111-4111-8111-111111111111', 'fixture');

SELECT ok(
  public.user_owns_outfit_and_item(
    '55555555-5555-4555-8555-555555555555',
    '33333333-3333-4333-8333-333333333333'
  ),
  'user A may link their own outfit and wardrobe item'
);
SELECT ok(
  NOT public.user_owns_outfit_and_item(
    '55555555-5555-4555-8555-555555555555',
    '44444444-4444-4444-8444-444444444444'
  ),
  'user A cannot link user B wardrobe item'
);
SELECT throws_ok(
  $$UPDATE public.user_profiles SET tier = 'premium' WHERE id = '11111111-1111-4111-8111-111111111111'$$,
  '42501',
  'permission denied for table user_profiles',
  'authenticated cannot write protected profile fields'
);
SELECT throws_ok(
  $$INSERT INTO public.outfit_items (outfit_id, item_id)
    VALUES ('55555555-5555-4555-8555-555555555555', '44444444-4444-4444-8444-444444444444')$$,
  '42501',
  'new row violates row-level security policy for table "outfit_items"',
  'outfit_items RLS rejects a link to another user wardrobe item'
);

SELECT ok(
  NOT has_function_privilege('authenticated', 'public.consume_ai_quota(text)', 'EXECUTE'),
  'legacy client-callable quota RPC is revoked'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.reserve_ai_action(uuid,text)', 'EXECUTE'),
  'anonymous sessions cannot reserve AI actions'
);
SELECT ok(
  (public.reserve_ai_action('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'today-suggestion')->>'allowed')::boolean
    AND public.get_ai_allowance()->>'tier' = 'free'
    AND public.get_ai_allowance()->>'month_limit' = '20',
  'forged metadata cannot reserve a premium-level AI allowance'
);
SELECT is(
  public.reserve_ai_action('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'style-coach')->>'reason',
  'duplicate',
  'same user request id cannot be replayed through another endpoint'
);
SELECT is(
  public.reserve_ai_action('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'style-coach')->>'reason',
  'burst',
  'free-tier burst limit blocks a second action in the same UTC minute'
);

RESET ROLE;
UPDATE public.user_profiles
SET tier = 'premium', subscription_status = 'active',
    subscription_expires_at = now() - interval '1 second'
WHERE id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(public.get_ai_allowance()->>'tier', 'free', 'expired premium access immediately uses free quota');
SELECT ok(
  (public.reserve_ai_action('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'today-suggestion')->>'allowed')::boolean,
  'user B receives an independent allowance'
);
SELECT ok(
  public.finalize_ai_action('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'provider_error', 'provider_unavailable'),
  'non-coach provider failure retains the existing charged-attempt policy'
);
SELECT is(public.get_ai_allowance()->>'month_remaining', '19', 'non-coach failure still consumes monthly usage');
SELECT ok(
  NOT has_table_privilege('authenticated', 'public.ai_action_reservations', 'SELECT'),
  'authenticated clients cannot read the private idempotency ledger'
);
SELECT ok(
  NOT has_table_privilege('authenticated', 'public.ai_quota_policies', 'SELECT'),
  'authenticated clients cannot read or modify server quota policy'
);
SELECT is(
  public.get_ai_allowance()->>'month_limit',
  '20',
  'free monthly allowance comes from the private configurable policy'
);

RESET ROLE;
UPDATE public.user_profiles
SET tier = 'free', subscription_status = 'active',
    subscription_expires_at = now() + interval '1 day'
WHERE id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(public.get_ai_allowance()->>'tier', 'free', 'a downgraded profile uses the free policy even if old subscription fields remain active');

RESET ROLE;
UPDATE public.user_profiles
SET tier = 'premium', subscription_status = 'active',
    subscription_expires_at = NULL
WHERE id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(public.get_ai_allowance()->>'tier', 'free', 'active premium without a recorded expiry fails closed to free');

RESET ROLE;
UPDATE public.ai_usage_buckets
SET month_start = (date_trunc('month', now() AT TIME ZONE 'UTC')::date - interval '1 month')::date,
    month_used = 20,
    day_start = (now() AT TIME ZONE 'UTC')::date - 1,
    day_used = 3,
    burst_start = date_trunc('minute', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' - interval '1 minute',
    burst_used = 1
WHERE user_id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(public.get_ai_allowance()->>'month_remaining', '20', 'monthly allowance resets at UTC month boundary');
SELECT is(public.get_ai_allowance()->>'day_remaining', '3', 'daily allowance resets at UTC day boundary');
SELECT is(public.get_ai_allowance()->>'burst_remaining', '1', 'burst allowance resets at fixed UTC minute boundary');
SELECT ok(
  (public.reserve_ai_action('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'today-suggestion')->>'allowed')::boolean,
  'reservation lazily resets elapsed UTC counters'
);

RESET ROLE;
UPDATE public.user_profiles
SET tier = 'premium', subscription_status = 'active',
    subscription_expires_at = now() + interval '1 day'
WHERE id = '22222222-2222-4222-8222-222222222222';
UPDATE public.ai_usage_buckets
SET month_start = date_trunc('month', now() AT TIME ZONE 'UTC')::date,
    month_used = 199,
    day_start = (now() AT TIME ZONE 'UTC')::date,
    day_used = 19,
    burst_start = date_trunc('minute', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC',
    burst_used = 0
WHERE user_id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(public.get_ai_allowance()->>'tier', 'premium', 'unexpired server entitlement grants premium policy');
SELECT ok(
  (public.reserve_ai_action('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'style-coach')->>'allowed')::boolean,
  'premium can use its final monthly and daily action'
);
SELECT is(
  public.reserve_ai_action('ffffffff-ffff-4fff-8fff-ffffffffffff', 'generate-ai-insights')->>'reason',
  'monthly',
  'premium monthly maximum is atomic across endpoint names'
);
RESET ROLE;
UPDATE public.ai_usage_buckets SET month_used = 50, day_used = 20, burst_used = 0,
  burst_start = date_trunc('minute', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'
WHERE user_id = '22222222-2222-4222-8222-222222222222';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(
  public.reserve_ai_action('abababab-abab-4bab-8bab-abababababab', 'today-suggestion')->>'reason',
  'daily',
  'premium daily limit applies independently from the monthly allowance'
);

RESET ROLE;
SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname = ANY (ARRAY[
        'upgrade_user_to_premium','reset_monthly_suggestions',
        'can_request_suggestion','increment_suggestions_count',
        'increment_daily_suggestions','increment_coaching_sessions',
        'increment_outfit_log_count','consume_ai_quota',
        'check_item_limit_before_insert','decrement_items_count',
        'handle_new_user','increment_items_count','increment_wear_count',
        'update_updated_at_column'
      ])
      AND (has_function_privilege('anon',p.oid,'EXECUTE') OR
           has_function_privilege('authenticated',p.oid,'EXECUTE'))
  ),
  'no overload of a legacy tier or quota mutator is client-executable'
);
SELECT ok(
  NOT has_table_privilege('anon','public.subscription_transactions','SELECT') AND
  NOT has_table_privilege('authenticated','public.subscription_transactions','SELECT') AND
  NOT has_table_privilege('authenticated','public.subscription_transactions','INSERT'),
  'billing history is inaccessible to client roles'
);
SELECT ok(
  NOT has_table_privilege('authenticated','public.ai_usage_buckets','SELECT') AND
  NOT has_table_privilege('authenticated','public.ai_usage_buckets','UPDATE') AND
  NOT has_table_privilege('authenticated','public.ai_action_reservations','SELECT') AND
  NOT has_table_privilege('authenticated','public.ai_action_reservations','UPDATE'),
  'clients cannot read or mutate quota counters and reservations'
);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT is(
  (SELECT tier::text FROM public.user_profiles WHERE id='11111111-1111-4111-8111-111111111111'),
  'free',
  'forged user metadata does not set the tier'
);
SELECT is(
  (SELECT subscription_status FROM public.user_profiles WHERE id='11111111-1111-4111-8111-111111111111'),
  'inactive',
  'forged user metadata does not set subscription status'
);
SELECT ok(
  (SELECT subscription_expires_at IS NULL FROM public.user_profiles WHERE id='11111111-1111-4111-8111-111111111111'),
  'forged user metadata does not set subscription expiry'
);
UPDATE public.user_profiles SET full_name='Legitimate profile edit'
WHERE id='11111111-1111-4111-8111-111111111111';
SELECT is(
  (SELECT full_name FROM public.user_profiles WHERE id='11111111-1111-4111-8111-111111111111'),
  'Legitimate profile edit',
  'authenticated users retain permitted profile editing'
);
SELECT throws_ok(
  $$UPDATE public.user_profiles
    SET tier='premium', subscription_status='active',
        subscription_expires_at='2099-01-01T00:00:00Z', revenue_cat_id='forged',
        items_limit=999999, suggestions_limit=999999,
        items_count=0, monthly_suggestions_used=0,
        daily_suggestions_used=0, coaching_sessions_used=0
    WHERE id='11111111-1111-4111-8111-111111111111'$$,
  '42501',
  'permission denied for table user_profiles',
  'authenticated users cannot directly change entitlement, limits, or counters'
);
SELECT ok(
  NOT has_table_privilege('anon','public.user_profiles','INSERT') AND
  NOT has_table_privilege('authenticated','public.user_profiles','INSERT'),
  'clients cannot create profiles with forged billing state'
);
RESET ROLE;
SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT * FROM public.user_profiles$$,
  '42501',
  'permission denied for table user_profiles',
  'anonymous clients cannot read profile or billing state'
);
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT throws_ok(
  $$DELETE FROM public.user_profiles WHERE id='11111111-1111-4111-8111-111111111111'$$,
  '42501',
  'permission denied for table user_profiles',
  'authenticated clients cannot delete profiles outside verified account deletion'
);
SELECT throws_ok(
  $$SELECT * FROM public.ai_usage_buckets$$,
  '42501',
  'permission denied for table ai_usage_buckets',
  'authenticated users cannot read another account quota state'
);
RESET ROLE;

SELECT ok(
  has_function_privilege(
    'service_role',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ),
  'server role retains verified billing update access'
);
SELECT ok(
  NOT has_function_privilege(
    'anon',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ) AND NOT has_function_privilege(
    'authenticated',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ),
  'client roles cannot invoke verified billing updates'
);
SET LOCAL ROLE service_role;
SELECT is(
  public.apply_subscription_event(
    'fixture-event-current', '22222222-2222-4222-8222-222222222222',
    'INITIAL_PURCHASE', now(), now()+interval '30 days', 'fixture-entitlement',
    '{}', 'premium', 'active'
  ),
  'applied',
  'authorized server billing event applies premium state'
);
RESET ROLE;
SELECT is(
  (SELECT tier::text FROM public.user_profiles WHERE id='22222222-2222-4222-8222-222222222222'),
  'premium',
  'verified billing event updates the server-owned tier'
);
SET LOCAL ROLE service_role;
SELECT is(
  public.apply_subscription_event(
    'fixture-event-current', '22222222-2222-4222-8222-222222222222',
    'CANCELLATION', now()+interval '2 days', now(), 'fixture-entitlement',
    '{}', 'free', 'expired'
  ),
  'duplicate',
  'duplicate billing event cannot overwrite current state'
);
SELECT is(
  public.apply_subscription_event(
    'fixture-event-stale', '22222222-2222-4222-8222-222222222222',
    'INITIAL_PURCHASE', now()-interval '1 day', now(), 'fixture-entitlement',
    '{}', 'free', 'expired'
  ),
  'stale',
  'older billing event is recorded but cannot overwrite current state'
);
RESET ROLE;
SELECT is(
  (SELECT subscription_status FROM public.user_profiles WHERE id='22222222-2222-4222-8222-222222222222'),
  'active',
  'stale billing event preserves current verified status'
);
SELECT * FROM finish();
ROLLBACK;
