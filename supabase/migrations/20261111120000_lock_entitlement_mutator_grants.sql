-- Defense in depth after the profile/entitlement reconstruction and before
-- server AI quota objects are installed. Catch every overload of the known
-- legacy profile/quota RPC names rather than only their historical signatures.
DO $$
DECLARE
  routine record;
BEGIN
  FOR routine IN
    SELECT p.oid::regprocedure AS signature, p.prosecdef
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = ANY (ARRAY[
        'upgrade_user_to_premium',
        'consume_ai_quota',
        'reset_monthly_suggestions',
        'can_request_suggestion',
        'increment_suggestions_count',
        'increment_daily_suggestions',
        'increment_coaching_sessions',
        'increment_outfit_log_count',
        'check_item_limit_before_insert',
        'decrement_items_count',
        'handle_new_user',
        'increment_items_count',
        'increment_wear_count',
        'update_updated_at_column'
      ])
  LOOP
    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role',
      routine.signature
    );
    IF routine.prosecdef THEN
      EXECUTE format(
        'ALTER FUNCTION %s SET search_path = pg_catalog, public, auth',
        routine.signature
      );
    END IF;
  END LOOP;

  -- Keep exactly one server-only entitlement mutation entry point. Revoke all
  -- overloads first, then grant the verified-event signature back to service_role.
  FOR routine IN
    SELECT p.oid::regprocedure AS signature, p.prosecdef
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'apply_subscription_event'
  LOOP
    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role',
      routine.signature
    );
    IF routine.prosecdef THEN
      EXECUTE format(
        'ALTER FUNCTION %s SET search_path = pg_catalog, public, auth',
        routine.signature
      );
    END IF;
  END LOOP;

  IF to_regprocedure(
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)'
  ) IS NULL THEN
    RAISE EXCEPTION 'verified subscription event RPC is missing';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_subscription_event(
  text, uuid, text, timestamptz, timestamptz, text, jsonb, text, text
) TO service_role;

-- The recovered schema already has this nullable text field. The earlier
-- local migrations did not; add it here before the verified billing RPC can be
-- invoked, without editing the already-versioned reconstruction migration.
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS revenue_cat_id text;
REVOKE ALL (revenue_cat_id) ON TABLE public.user_profiles
  FROM PUBLIC, anon, authenticated;

-- A recovered schema may have had an older nullable status column. Never infer
-- paid access from the legacy tier/expiry fields; null is conservatively inactive.
ALTER TABLE public.user_profiles
  ALTER COLUMN subscription_status SET DEFAULT 'inactive';
UPDATE public.user_profiles
  SET subscription_status = 'inactive'
  WHERE subscription_status IS NULL;
ALTER TABLE public.user_profiles
  ALTER COLUMN subscription_status SET NOT NULL;
ALTER TABLE public.user_profiles
  VALIDATE CONSTRAINT user_profiles_subscription_status_check;

-- Fail the migration if a client-facing overload remains executable or any
-- protected profile column is directly writable by anon/authenticated.
DO $$
DECLARE
  routine record;
  column_name text;
BEGIN
  FOR routine IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = ANY (ARRAY[
        'upgrade_user_to_premium',
        'consume_ai_quota',
        'reset_monthly_suggestions',
        'can_request_suggestion',
        'increment_suggestions_count',
        'increment_daily_suggestions',
        'increment_coaching_sessions',
        'increment_outfit_log_count',
        'check_item_limit_before_insert',
        'decrement_items_count',
        'handle_new_user',
        'increment_items_count',
        'increment_wear_count',
        'update_updated_at_column'
      ])
      AND (
        has_function_privilege('anon', p.oid, 'EXECUTE') OR
        has_function_privilege('authenticated', p.oid, 'EXECUTE')
      )
  LOOP
    RAISE EXCEPTION 'legacy client-executable entitlement routine remains: %',
      routine.signature;
  END LOOP;

  -- Catch a newly named overload too: client-executable routines which update
  -- protected profile state must be explicitly reviewed before this migration.
  FOR routine IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosrc ~* 'update[[:space:]]+(public[.])?user_profiles[[:space:]]+set'
      AND p.prosrc ~* '(tier|subscription_status|subscription_expires_at|items_limit|suggestions_limit|items_count|monthly_suggestions_used|daily_suggestions_used|coaching_sessions_used)'
      AND (
        has_function_privilege('anon', p.oid, 'EXECUTE') OR
        has_function_privilege('authenticated', p.oid, 'EXECUTE')
      )
  LOOP
    RAISE EXCEPTION 'client-executable protected profile mutator remains: %',
      routine.signature;
  END LOOP;

  FOR column_name IN
    SELECT c.column_name
    FROM information_schema.columns AS c
    WHERE c.table_schema = 'public' AND c.table_name = 'user_profiles'
      AND c.column_name NOT IN (
        'full_name', 'avatar_url', 'updated_at', 'onboarding_completed',
        'style_preferences', 'work_environment', 'social_frequency', 'climate',
        'purchase_frequency', 'budget_consciousness', 'environmental_impact'
      )
  LOOP
    IF has_column_privilege(
      'anon', 'public.user_profiles', column_name, 'UPDATE'
    ) OR has_column_privilege(
      'authenticated', 'public.user_profiles', column_name, 'UPDATE'
    ) THEN
      RAISE EXCEPTION 'client can update protected profile column %', column_name;
    END IF;
  END LOOP;

  IF has_table_privilege('anon', 'public.user_profiles', 'INSERT') OR
     has_table_privilege('authenticated', 'public.user_profiles', 'INSERT') THEN
    RAISE EXCEPTION 'clients can insert server-managed profile rows';
  END IF;

  IF has_table_privilege('anon', 'public.user_profiles', 'SELECT') OR
     has_table_privilege('anon', 'public.user_profiles', 'UPDATE') OR
     has_table_privilege('authenticated', 'public.user_profiles', 'DELETE') THEN
    RAISE EXCEPTION 'client table-level profile grants exceed the reviewed policy';
  END IF;

  IF has_function_privilege(
    'anon',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ) OR has_function_privilege(
    'authenticated',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ) OR NOT has_function_privilege(
    'service_role',
    'public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)',
    'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'subscription event RPC grants are not server-only';
  END IF;
END;
$$;
