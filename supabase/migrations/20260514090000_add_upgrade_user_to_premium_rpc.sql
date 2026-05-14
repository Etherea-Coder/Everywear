-- Location: supabase/migrations/20260514090000_add_upgrade_user_to_premium_rpc.sql
-- Purpose: Create the upgrade_user_to_premium RPC function called by UserTierService

-- Drop existing function if return type has changed (e.g. VOID -> JSONB)
DROP FUNCTION IF EXISTS public.upgrade_user_to_premium(UUID);

CREATE OR REPLACE FUNCTION public.upgrade_user_to_premium(user_uuid UUID)
RETURNS JSONB
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    current_tier TEXT;
    result JSONB;
BEGIN
    -- Verify the calling user matches the requested user_uuid
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF auth.uid() != user_uuid THEN
        RAISE EXCEPTION 'Only the authenticated user can request tier changes';
    END IF;

    -- Get current tier
    SELECT tier INTO current_tier
    FROM public.user_profiles
    WHERE id = user_uuid;

    IF current_tier IS NULL THEN
        RAISE EXCEPTION 'User profile not found';
    END IF;

    IF current_tier = 'premium' THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'User is already premium',
            'tier', 'premium'
        );
    END IF;

    -- Upgrade to premium
    UPDATE public.user_profiles
    SET
        tier = 'premium',
        items_limit = 100,
        suggestions_limit = 50,
        updated_at = now()
    WHERE id = user_uuid
    RETURNING jsonb_build_object(
        'success', true,
        'message', 'Upgraded to premium',
        'tier', tier,
        'items_limit', items_limit,
        'suggestions_limit', suggestions_limit
    ) INTO result;

    RETURN result;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.upgrade_user_to_premium(UUID) TO authenticated;

-- Create function to reset monthly suggestion counters (call from cron or manually)
CREATE OR REPLACE FUNCTION public.reset_monthly_suggestions()
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.user_profiles
    SET monthly_suggestions_used = 0
    WHERE monthly_suggestions_used > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_monthly_suggestions() TO service_role;
