-- Apply after 20261112100000_server_ai_action_quotas.sql, before deploying
-- the matching style-coach handler. Never expose refund authority to clients.
BEGIN;

ALTER TABLE public.ai_action_reservations
  ADD COLUMN IF NOT EXISTS reserved_month_start date,
  ADD COLUMN IF NOT EXISTS reserved_day_start date,
  ADD COLUMN IF NOT EXISTS allowance_refunded_at timestamptz;
UPDATE public.ai_action_reservations
SET reserved_month_start = date_trunc('month', created_at AT TIME ZONE 'UTC')::date,
    reserved_day_start = (created_at AT TIME ZONE 'UTC')::date
WHERE reserved_month_start IS NULL OR reserved_day_start IS NULL;
ALTER TABLE public.ai_action_reservations
  ALTER COLUMN reserved_month_start SET DEFAULT date_trunc('month', now() AT TIME ZONE 'UTC')::date,
  ALTER COLUMN reserved_day_start SET DEFAULT (now() AT TIME ZONE 'UTC')::date,
  ALTER COLUMN reserved_month_start SET NOT NULL,
  ALTER COLUMN reserved_day_start SET NOT NULL;

-- Existing client JWT finalization remains available for other AI functions,
-- but cannot finalize a coach reservation or release its concurrency slot.
CREATE OR REPLACE FUNCTION public.finalize_ai_action(
  p_request_id uuid, p_outcome text, p_error_code text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE uid uuid := auth.uid(); action text;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501'; END IF;
  IF p_outcome IS NULL OR p_outcome NOT IN ('succeeded','provider_error','timeout','invalid_response','internal_error')
    OR (p_error_code IS NOT NULL AND p_error_code NOT IN
      ('provider_unavailable','provider_rejected','invalid_response','timeout','internal_error'))
  THEN RAISE EXCEPTION 'invalid outcome' USING ERRCODE = '22023'; END IF;
  SELECT action_name INTO action FROM public.ai_action_reservations
    WHERE user_id = uid AND request_id = p_request_id;
  IF action = 'style-coach' THEN
    RAISE EXCEPTION 'coach finalization is server-only' USING ERRCODE = '42501';
  END IF;
  UPDATE public.ai_action_reservations SET status = p_outcome,
    error_code = p_error_code, finalized_at = now()
    WHERE user_id = uid AND request_id = p_request_id AND status = 'reserved';
  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_style_coach_action(
  p_user_id uuid, p_request_id uuid, p_outcome text, p_error_code text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE r public.ai_action_reservations%ROWTYPE; u public.ai_usage_buckets%ROWTYPE;
BEGIN
  IF p_user_id IS NULL OR p_request_id IS NULL OR p_outcome IS NULL OR
    p_outcome NOT IN ('succeeded','provider_error','timeout','invalid_response','internal_error')
    OR (p_error_code IS NOT NULL AND p_error_code NOT IN
      ('provider_unavailable','provider_rejected','invalid_response','timeout','internal_error'))
  THEN RAISE EXCEPTION 'invalid coach finalization' USING ERRCODE = '22023'; END IF;

  -- Same first lock as reserve_ai_action: serialize per user and avoid
  -- counter/ledger races with concurrent reservations and finalizations.
  PERFORM 1 FROM public.user_profiles WHERE id = p_user_id FOR UPDATE;
  IF NOT FOUND THEN RETURN false; END IF;
  SELECT * INTO r FROM public.ai_action_reservations
    WHERE user_id = p_user_id AND request_id = p_request_id
      AND action_name = 'style-coach' FOR UPDATE;
  IF NOT FOUND OR r.status <> 'reserved' THEN RETURN false; END IF;

  IF p_outcome IN ('provider_error','timeout','invalid_response') THEN
    SELECT * INTO u FROM public.ai_usage_buckets WHERE user_id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'AI usage bucket unavailable' USING ERRCODE = 'P0002'; END IF;
    -- The single-row bucket may already have rolled forward. Never subtract
    -- an old reservation from a new day or month; the old window has expired.
    UPDATE public.ai_usage_buckets SET
      month_used = CASE WHEN u.month_start = r.reserved_month_start
        THEN greatest(0, u.month_used - 1) ELSE u.month_used END,
      day_used = CASE WHEN u.day_start = r.reserved_day_start
        THEN greatest(0, u.day_used - 1) ELSE u.day_used END,
      updated_at = now()
    WHERE user_id = p_user_id;
    UPDATE public.ai_action_reservations
      SET allowance_refunded_at = now()
      WHERE id = r.id;
  END IF;
  UPDATE public.ai_action_reservations SET status = p_outcome,
    error_code = p_error_code, finalized_at = now() WHERE id = r.id;
  RETURN true;
END;
$$;

-- An interrupted handler has an unknown provider outcome. Keep its charge,
-- close the stale ledger entry, and let the existing 30-second slot window
-- expire. Do not guess that provider work was free.
CREATE OR REPLACE FUNCTION public.reconcile_stale_style_coach_actions(p_user_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE changed integer;
BEGIN
  IF p_user_id IS NULL THEN RAISE EXCEPTION 'invalid user' USING ERRCODE = '22023'; END IF;
  PERFORM 1 FROM public.user_profiles WHERE id = p_user_id FOR UPDATE;
  IF NOT FOUND THEN RETURN 0; END IF;
  UPDATE public.ai_action_reservations
    SET status = 'internal_error', error_code = 'internal_error', finalized_at = now()
    WHERE user_id = p_user_id AND action_name = 'style-coach'
      AND status = 'reserved' AND created_at < now() - interval '30 seconds';
  GET DIAGNOSTICS changed = ROW_COUNT;
  RETURN changed;
END;
$$;

REVOKE ALL ON FUNCTION public.finalize_ai_action(uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finalize_ai_action(uuid,text,text) TO authenticated;
REVOKE ALL ON FUNCTION public.finalize_style_coach_action(uuid,uuid,text,text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reconcile_stale_style_coach_actions(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_style_coach_action(uuid,uuid,text,text)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.reconcile_stale_style_coach_actions(uuid)
  TO service_role;
COMMENT ON TABLE public.ai_action_reservations IS
  'Private user/request ledger. Failed finalized style-coach attempts restore monthly/daily allowance; burst and unknown interrupted attempts remain charged.';
COMMIT;
