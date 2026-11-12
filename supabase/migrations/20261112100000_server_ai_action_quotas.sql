-- Requires the reviewed identity/subscription columns from
-- 20261111090000_reconstruct_and_secure_backend.sql. Apply only after the
-- recovered schema has been reconciled and the preceding migration approved.
-- All quota windows use UTC calendar month/day and a fixed UTC minute.

CREATE TABLE IF NOT EXISTS public.ai_usage_buckets (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  month_start date NOT NULL,
  month_used integer NOT NULL DEFAULT 0 CHECK (month_used >= 0),
  day_start date NOT NULL,
  day_used integer NOT NULL DEFAULT 0 CHECK (day_used >= 0),
  burst_start timestamptz NOT NULL,
  burst_used integer NOT NULL DEFAULT 0 CHECK (burst_used >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ai_action_reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  request_id uuid NOT NULL,
  action_name text NOT NULL CHECK (action_name IN (
    'analyze-clothing', 'ai-suggestions', 'today-suggestion',
    'style-coach', 'generate-ai-insights'
  )),
  status text NOT NULL DEFAULT 'reserved' CHECK (status IN (
    'reserved', 'succeeded', 'provider_error', 'timeout',
    'invalid_response', 'internal_error'
  )),
  created_at timestamptz NOT NULL DEFAULT now(),
  finalized_at timestamptz,
  error_code text CHECK (error_code IS NULL OR error_code IN (
    'provider_unavailable', 'provider_rejected', 'invalid_response',
    'timeout', 'internal_error'
  )),
  UNIQUE (user_id, request_id)
);

-- Defaults are deliberately stored in a private table so operators can tune
-- them through reviewed database changes without trusting client values.
CREATE TABLE IF NOT EXISTS public.ai_quota_policies (
  tier text PRIMARY KEY CHECK (tier IN ('free', 'premium')),
  monthly_limit integer NOT NULL CHECK (monthly_limit BETWEEN 1 AND 200),
  daily_limit integer NOT NULL CHECK (daily_limit BETWEEN 1 AND 20),
  burst_limit integer NOT NULL CHECK (burst_limit BETWEEN 1 AND 5),
  concurrency_limit integer NOT NULL CHECK (concurrency_limit BETWEEN 1 AND 3),
  CHECK (daily_limit <= monthly_limit),
  CHECK (burst_limit <= daily_limit),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.ai_quota_policies
  (tier, monthly_limit, daily_limit, burst_limit, concurrency_limit)
VALUES
  ('free', 20, 3, 1, 1),
  ('premium', 200, 20, 5, 3)
ON CONFLICT (tier) DO NOTHING;

CREATE INDEX IF NOT EXISTS ai_action_reservations_active_idx
  ON public.ai_action_reservations(user_id, created_at)
  WHERE status = 'reserved';
CREATE INDEX IF NOT EXISTS ai_action_reservations_retention_idx
  ON public.ai_action_reservations(created_at);

ALTER TABLE public.ai_usage_buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_action_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_quota_policies ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_usage_buckets, public.ai_action_reservations,
  public.ai_quota_policies
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_ai_allowance()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  uid uuid := auth.uid();
  p public.user_profiles%ROWTYPE;
  u public.ai_usage_buckets%ROWTYPE;
  now_utc timestamptz := now();
  v_paid boolean;
  month_limit integer;
  day_limit integer;
  burst_limit integer;
  concurrency_limit integer;
  policy_tier text;
  month_start date := date_trunc('month', now() AT TIME ZONE 'UTC')::date;
  day_start date := (now() AT TIME ZONE 'UTC')::date;
  burst_start timestamptz := date_trunc('minute', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501'; END IF;
  SELECT * INTO p FROM public.user_profiles WHERE id = uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile unavailable' USING ERRCODE = 'P0002'; END IF;
  v_paid := p.tier = 'premium' AND (
    (p.subscription_status = 'active' AND
      p.subscription_expires_at > now_utc) OR
    (p.subscription_status IN ('grace_period', 'cancelled') AND
      p.subscription_expires_at > now_utc)
  );
  policy_tier := CASE WHEN v_paid THEN 'premium' ELSE 'free' END;
  SELECT q.monthly_limit, q.daily_limit, q.burst_limit, q.concurrency_limit
    INTO month_limit, day_limit, burst_limit, concurrency_limit
    FROM public.ai_quota_policies AS q WHERE q.tier = policy_tier;
  IF NOT FOUND THEN RAISE EXCEPTION 'AI quota policy unavailable' USING ERRCODE = 'P0002'; END IF;
  SELECT * INTO u FROM public.ai_usage_buckets WHERE user_id = uid;
  RETURN jsonb_build_object(
    'tier', CASE WHEN v_paid THEN 'premium' ELSE 'free' END,
    'month_limit', month_limit,
    'month_used', CASE WHEN u.month_start = month_start THEN u.month_used ELSE 0 END,
    'month_remaining', greatest(0, month_limit - CASE WHEN u.month_start = month_start THEN u.month_used ELSE 0 END),
    'month_resets_at', (month_start + interval '1 month')::date::text || 'T00:00:00Z',
    'day_limit', day_limit,
    'day_used', CASE WHEN u.day_start = day_start THEN u.day_used ELSE 0 END,
    'day_remaining', greatest(0, day_limit - CASE WHEN u.day_start = day_start THEN u.day_used ELSE 0 END),
    'day_resets_at', (day_start + 1)::text || 'T00:00:00Z',
    'burst_limit', burst_limit,
    'burst_remaining', greatest(0, burst_limit - CASE WHEN u.burst_start = burst_start THEN u.burst_used ELSE 0 END),
    'burst_resets_at', to_char(
      (burst_start + interval '1 minute') AT TIME ZONE 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS"Z"'
    ),
    'concurrency_limit', concurrency_limit
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.reserve_ai_action(p_request_id uuid, p_action_name text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  uid uuid := auth.uid();
  p public.user_profiles%ROWTYPE;
  u public.ai_usage_buckets%ROWTYPE;
  now_utc timestamptz := now();
  v_month_start date := date_trunc('month', now() AT TIME ZONE 'UTC')::date;
  v_day_start date := (now() AT TIME ZONE 'UTC')::date;
  v_burst_start timestamptz := date_trunc('minute', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
  v_paid boolean;
  ml integer;
  dl integer;
  bl integer;
  cl integer;
  policy_tier text;
  active_count integer;
  prior public.ai_action_reservations%ROWTYPE;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501'; END IF;
  IF p_request_id IS NULL OR p_action_name IS NULL OR p_action_name NOT IN (
    'analyze-clothing', 'ai-suggestions', 'today-suggestion',
    'style-coach', 'generate-ai-insights'
  ) THEN RAISE EXCEPTION 'invalid action' USING ERRCODE = '22023'; END IF;

  -- Serialize identity, entitlement, deduplication, and all counters per user.
  SELECT * INTO p FROM public.user_profiles WHERE id = uid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile unavailable' USING ERRCODE = 'P0002'; END IF;
  v_paid := p.tier = 'premium' AND (
    (p.subscription_status = 'active' AND
      p.subscription_expires_at > now_utc) OR
    (p.subscription_status IN ('grace_period', 'cancelled') AND
      p.subscription_expires_at > now_utc)
  );
  policy_tier := CASE WHEN v_paid THEN 'premium' ELSE 'free' END;
  SELECT q.monthly_limit, q.daily_limit, q.burst_limit, q.concurrency_limit
    INTO ml, dl, bl, cl
    FROM public.ai_quota_policies AS q WHERE q.tier = policy_tier;
  IF NOT FOUND THEN RAISE EXCEPTION 'AI quota policy unavailable' USING ERRCODE = 'P0002'; END IF;

  DELETE FROM public.ai_action_reservations
    WHERE user_id = uid AND created_at < now_utc - interval '90 days';
  SELECT * INTO prior FROM public.ai_action_reservations
    WHERE user_id = uid AND request_id = p_request_id;
  IF FOUND THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'duplicate',
      'action', prior.action_name, 'status', prior.status,
      'allowance', public.get_ai_allowance());
  END IF;

  INSERT INTO public.ai_usage_buckets(user_id, month_start, day_start, burst_start)
    VALUES (uid, v_month_start, v_day_start, v_burst_start)
    ON CONFLICT (user_id) DO NOTHING;
  SELECT * INTO u FROM public.ai_usage_buckets WHERE user_id = uid FOR UPDATE;
  IF u.month_start <> v_month_start THEN UPDATE public.ai_usage_buckets
    SET month_start = v_month_start, month_used = 0 WHERE user_id = uid;
    u.month_start := v_month_start; u.month_used := 0;
  END IF;
  IF u.day_start <> v_day_start THEN UPDATE public.ai_usage_buckets
    SET day_start = v_day_start, day_used = 0 WHERE user_id = uid;
    u.day_start := v_day_start; u.day_used := 0;
  END IF;
  IF u.burst_start <> v_burst_start THEN UPDATE public.ai_usage_buckets
    SET burst_start = v_burst_start, burst_used = 0 WHERE user_id = uid;
    u.burst_start := v_burst_start; u.burst_used := 0;
  END IF;

  IF u.month_used >= ml THEN RETURN jsonb_build_object('allowed', false, 'reason', 'monthly',
    'allowance', public.get_ai_allowance()); END IF;
  IF u.day_used >= dl THEN RETURN jsonb_build_object('allowed', false, 'reason', 'daily',
    'allowance', public.get_ai_allowance()); END IF;
  IF u.burst_used >= bl THEN RETURN jsonb_build_object('allowed', false, 'reason', 'burst',
    'allowance', public.get_ai_allowance()); END IF;
  SELECT count(*) INTO active_count FROM public.ai_action_reservations
    WHERE user_id = uid AND status = 'reserved' AND created_at > now_utc - interval '30 seconds';
  IF active_count >= cl THEN RETURN jsonb_build_object('allowed', false, 'reason', 'concurrency',
    'allowance', public.get_ai_allowance()); END IF;

  UPDATE public.ai_usage_buckets SET month_used = u.month_used + 1,
    day_used = u.day_used + 1, burst_used = u.burst_used + 1, updated_at = now()
    WHERE user_id = uid;
  INSERT INTO public.ai_action_reservations(user_id, request_id, action_name)
    VALUES (uid, p_request_id, p_action_name);
  RETURN jsonb_build_object('allowed', true, 'tier', CASE WHEN v_paid THEN 'premium' ELSE 'free' END,
    'month_limit', ml, 'month_remaining', ml - u.month_used - 1,
    'day_limit', dl, 'day_remaining', dl - u.day_used - 1,
    'burst_limit', bl, 'burst_remaining', bl - u.burst_used - 1,
    'month_resets_at', (v_month_start + interval '1 month')::date::text || 'T00:00:00Z',
    'day_resets_at', (v_day_start + 1)::text || 'T00:00:00Z',
    'burst_resets_at', to_char(
      (v_burst_start + interval '1 minute') AT TIME ZONE 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS"Z"'
    ));
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_ai_action(
  p_request_id uuid, p_outcome text, p_error_code text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501'; END IF;
  IF p_outcome IS NULL OR p_outcome NOT IN ('succeeded', 'provider_error', 'timeout', 'invalid_response', 'internal_error')
    OR (p_error_code IS NOT NULL AND p_error_code NOT IN
      ('provider_unavailable', 'provider_rejected', 'invalid_response', 'timeout', 'internal_error'))
  THEN RAISE EXCEPTION 'invalid outcome' USING ERRCODE = '22023'; END IF;
  UPDATE public.ai_action_reservations SET status = p_outcome,
    error_code = p_error_code, finalized_at = now()
    WHERE user_id = uid AND request_id = p_request_id AND status = 'reserved';
  RETURN FOUND;
END;
$$;

REVOKE ALL ON FUNCTION public.get_ai_allowance() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reserve_ai_action(uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.finalize_ai_action(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_ai_allowance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_ai_action(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_ai_action(uuid, text, text) TO authenticated;
REVOKE ALL ON FUNCTION public.consume_ai_quota(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.can_request_suggestion() FROM PUBLIC, anon, authenticated;

COMMENT ON TABLE public.ai_usage_buckets IS
  'Private per-user UTC AI action counters; limits are server policy defaults, not customer promises.';
COMMENT ON TABLE public.ai_action_reservations IS
  'Private idempotency ledger; all provider attempts consume quota, including failed or interrupted attempts.';
COMMENT ON TABLE public.ai_quota_policies IS
  'Private server-only configurable AI action defaults. Configuration changes require reviewed database access.';
