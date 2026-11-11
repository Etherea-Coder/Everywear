-- Reconstruct the application contract and close privilege-escalation paths.
-- Forward-only: historical migrations remain intact for clean rebuilds.

-- The historical RPC allowed any authenticated user to grant themselves premium.
REVOKE ALL ON FUNCTION public.upgrade_user_to_premium(uuid) FROM PUBLIC, anon, authenticated;
DROP FUNCTION IF EXISTS public.upgrade_user_to_premium(uuid);
REVOKE ALL ON FUNCTION public.reset_monthly_suggestions() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.can_request_suggestion(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.increment_suggestions_count(uuid) FROM PUBLIC, anon, authenticated;

-- Wardrobe is unlimited in the current product contract.
DROP TRIGGER IF EXISTS enforce_item_limit ON public.wardrobe_items;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS subscription_status text NOT NULL DEFAULT 'inactive',
  ADD COLUMN IF NOT EXISTS revenuecat_customer_id text,
  ADD COLUMN IF NOT EXISTS daily_suggestions_used integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS suggestions_reset_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS coaching_sessions_used integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS coaching_reset_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS outfit_logs_count integer NOT NULL DEFAULT 0;

DO $$ BEGIN
  ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_tier_check
    CHECK (tier IN ('free', 'premium')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_subscription_status_check
    CHECK (subscription_status IN ('inactive', 'active', 'grace_period', 'cancelled', 'expired')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- The profile row is provisioned by the auth trigger. Authenticated clients
-- may update presentation/onboarding fields only; SECURITY DEFINER functions
-- and the service role retain authority over entitlements and counters.
DROP TRIGGER IF EXISTS protect_user_entitlements ON public.user_profiles;
DROP FUNCTION IF EXISTS public.reject_client_entitlement_changes();
REVOKE INSERT, UPDATE, DELETE ON public.user_profiles FROM authenticated;
GRANT SELECT ON public.user_profiles TO authenticated;
GRANT UPDATE (
  full_name, avatar_url, updated_at, onboarding_completed, style_preferences,
  work_environment, social_frequency, climate, purchase_frequency,
  budget_consciousness, environmental_impact
) ON public.user_profiles TO authenticated;

CREATE OR REPLACE FUNCTION public.user_owns_outfit_and_item(outfit_uuid uuid, item_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.outfit_logs o
    JOIN public.wardrobe_items w ON w.id = item_uuid
    WHERE o.id = outfit_uuid AND o.user_id = auth.uid() AND w.user_id = auth.uid()
  );
$$;
REVOKE ALL ON FUNCTION public.user_owns_outfit_and_item(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.user_owns_outfit_and_item(uuid, uuid) TO authenticated;

DROP POLICY IF EXISTS users_manage_own_outfit_items ON public.outfit_items;
CREATE POLICY users_manage_own_outfit_items ON public.outfit_items
FOR ALL TO authenticated
USING (public.user_owns_outfit_and_item(outfit_id, item_id))
WITH CHECK (public.user_owns_outfit_and_item(outfit_id, item_id));

CREATE OR REPLACE FUNCTION public.enforce_outfit_log_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE profile_tier text; current_count integer; quota_limit integer;
BEGIN
  IF auth.uid() IS NOT NULL AND NEW.user_id <> auth.uid() THEN
    RAISE EXCEPTION 'cannot create an outfit log for another user';
  END IF;
  SELECT tier INTO profile_tier FROM public.user_profiles
    WHERE id = NEW.user_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  SELECT count(*) INTO current_count FROM public.outfit_logs WHERE user_id = NEW.user_id;
  quota_limit := CASE WHEN profile_tier = 'premium' THEN 100 ELSE 30 END;
  IF current_count >= quota_limit THEN
    RAISE EXCEPTION 'outfit log limit reached' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.enforce_outfit_log_quota() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_outfit_log_quota ON public.outfit_logs;
CREATE TRIGGER enforce_outfit_log_quota
BEFORE INSERT ON public.outfit_logs
FOR EACH ROW EXECUTE FUNCTION public.enforce_outfit_log_quota();

CREATE OR REPLACE FUNCTION public.refresh_outfit_log_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE owner_id uuid := COALESCE(NEW.user_id, OLD.user_id);
BEGIN
  UPDATE public.user_profiles SET outfit_logs_count = (
    SELECT count(*) FROM public.outfit_logs WHERE user_id = owner_id
  ) WHERE id = owner_id;
  RETURN COALESCE(NEW, OLD);
END;
$$;
REVOKE ALL ON FUNCTION public.refresh_outfit_log_count() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS refresh_outfit_log_count ON public.outfit_logs;
CREATE TRIGGER refresh_outfit_log_count
AFTER INSERT OR DELETE ON public.outfit_logs
FOR EACH ROW EXECUTE FUNCTION public.refresh_outfit_log_count();

CREATE TABLE IF NOT EXISTS public.purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wardrobe_item_id uuid REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
  name text NOT NULL, price numeric(12,2) NOT NULL CHECK (price >= 0), purchase_date date NOT NULL,
  brand text, category text, image_url text, notes text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_budget (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  monthly_budget numeric(12,2) NOT NULL DEFAULT 0 CHECK (monthly_budget >= 0), currency text NOT NULL DEFAULT 'EUR',
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.wishlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL, brand text, category text, target_price numeric(12,2), current_price numeric(12,2),
  url text, image_url text, notes text, is_purchased boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL, event_date date NOT NULL, event_type text NOT NULL, dress_code text, notes text,
  outfit_id uuid REFERENCES public.outfit_logs(id) ON DELETE SET NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_quiz_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  style_profile text NOT NULL, preferred_colors text[] NOT NULL DEFAULT '{}', style_goals text[] NOT NULL DEFAULT '{}',
  answers jsonb NOT NULL DEFAULT '{}', style_intention text, completed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL, description text NOT NULL, challenge_type text NOT NULL,
  goal integer NOT NULL CHECK (goal > 0), duration_days integer NOT NULL DEFAULT 7, icon text,
  is_active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id uuid NOT NULL REFERENCES public.style_challenges(id) ON DELETE CASCADE,
  anchor_item_id uuid REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
  progress integer NOT NULL DEFAULT 0 CHECK (progress >= 0), insight text,
  started_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz, UNIQUE(user_id, challenge_id)
);
CREATE TABLE IF NOT EXISTS public.learning_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL, description text NOT NULL, content jsonb NOT NULL DEFAULT '{}',
  icon text, order_index integer NOT NULL UNIQUE, is_active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_module_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id uuid NOT NULL REFERENCES public.learning_modules(id) ON DELETE CASCADE,
  progress numeric(4,3) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1), started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz, UNIQUE(user_id, module_id)
);
CREATE TABLE IF NOT EXISTS public.feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text, message text NOT NULL, email text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.subscription_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), event_id text NOT NULL UNIQUE, user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL, event_at timestamptz NOT NULL, expires_at timestamptz, entitlement_id text,
  payload jsonb NOT NULL, processed_at timestamptz NOT NULL DEFAULT now()
);

-- Serialize billing events per account. Recording the ID and changing access
-- must succeed together, otherwise a retry could skip an unprocessed event.
CREATE OR REPLACE FUNCTION public.apply_subscription_event(
  input_event_id text, input_user_id uuid, input_type text,
  input_event_at timestamptz, input_expires_at timestamptz,
  input_entitlement text, input_payload jsonb, input_tier text, input_status text
) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  PERFORM 1 FROM public.user_profiles WHERE id = input_user_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  IF EXISTS (SELECT 1 FROM public.subscription_transactions WHERE event_id = input_event_id) THEN
    RETURN 'duplicate';
  END IF;
  INSERT INTO public.subscription_transactions
    (event_id,user_id,event_type,event_at,expires_at,entitlement_id,payload)
    VALUES (input_event_id,input_user_id,input_type,input_event_at,input_expires_at,input_entitlement,input_payload);
  IF EXISTS (
    SELECT 1 FROM public.subscription_transactions
    WHERE user_id = input_user_id AND entitlement_id = input_entitlement
      AND event_at > input_event_at
  ) THEN RETURN 'stale'; END IF;
  UPDATE public.user_profiles SET tier = input_tier,
    subscription_status = input_status, subscription_expires_at = input_expires_at,
    revenuecat_customer_id = input_user_id::text WHERE id = input_user_id;
  RETURN 'applied';
END;
$$;
REVOKE ALL ON FUNCTION public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)
  TO service_role;

CREATE INDEX IF NOT EXISTS purchases_user_date_idx ON public.purchases(user_id, purchase_date DESC);
CREATE INDEX IF NOT EXISTS wishlist_user_created_idx ON public.wishlist(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS style_events_user_date_idx ON public.style_events(user_id, event_date);
CREATE INDEX IF NOT EXISTS user_challenges_user_idx ON public.user_challenges(user_id);
CREATE INDEX IF NOT EXISTS module_progress_user_idx ON public.user_module_progress(user_id);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['purchases','user_budget','wishlist','style_events','style_quiz_results','user_challenges','user_module_progress','feedback']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS own_rows ON public.%I', t);
    EXECUTE format('CREATE POLICY own_rows ON public.%I FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t);
  END LOOP;
END $$;

ALTER TABLE public.style_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS authenticated_read_challenges ON public.style_challenges;
CREATE POLICY authenticated_read_challenges ON public.style_challenges FOR SELECT TO authenticated USING (is_active);
DROP POLICY IF EXISTS authenticated_read_learning ON public.learning_modules;
CREATE POLICY authenticated_read_learning ON public.learning_modules FOR SELECT TO authenticated USING (is_active);

-- Legitimate catalog seed only; no user activity or testimonials.
INSERT INTO public.style_challenges (id,title,description,challenge_type,goal,duration_days,icon) VALUES
('10000000-0000-4000-8000-000000000001','Rediscover a favorite','Wear an item you have not reached for recently.','rediscover',1,7,'refresh'),
('10000000-0000-4000-8000-000000000002','Three ways, one piece','Build three distinct outfits around one wardrobe item.','anchor_piece',3,7,'checkroom'),
('10000000-0000-4000-8000-000000000003','Try a tonal outfit','Create an outfit using shades from one color family.','color_outfit',1,7,'palette')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.learning_modules (id,title,description,content,icon,order_index) VALUES
('20000000-0000-4000-8000-000000000001','Know what you own','Build a useful wardrobe inventory before buying more.','{"lessons":["Photograph each item","Record fit, fabric and condition"]}','inventory_2',1),
('20000000-0000-4000-8000-000000000002','Cost per wear','Use wear history to understand the value of a purchase.','{"lessons":["Track real wears","Compare cost per wear over time"]}','calculate',2),
('20000000-0000-4000-8000-000000000003','Build a small capsule','Combine versatile pieces into more outfits with fewer items.','{"lessons":["Choose a color base","Test every combination"]}','checkroom',3)
ON CONFLICT (id) DO NOTHING;

-- Atomic quota consumption. Interactive Edge Functions call this once, before AI work.
CREATE OR REPLACE FUNCTION public.consume_ai_quota(quota_kind text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE p public.user_profiles%ROWTYPE; quota_limit integer;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  SELECT * INTO p FROM public.user_profiles WHERE id = auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  IF quota_kind = 'suggestion' THEN
    IF p.suggestions_reset_at::date < current_date THEN
      p.daily_suggestions_used := 0;
      UPDATE public.user_profiles SET daily_suggestions_used=0, suggestions_reset_at=now() WHERE id=auth.uid();
    END IF;
    quota_limit := CASE WHEN p.tier='premium' THEN 999 ELSE 1 END;
    IF p.daily_suggestions_used >= quota_limit THEN RETURN false; END IF;
    UPDATE public.user_profiles SET daily_suggestions_used=daily_suggestions_used+1 WHERE id=auth.uid();
    RETURN true;
  ELSIF quota_kind = 'coach' THEN
    IF (p.tier = 'premium' AND now() >= p.coaching_reset_at + interval '1 month') OR
       (p.tier <> 'premium' AND now() >= p.coaching_reset_at + interval '7 days') THEN
      p.coaching_sessions_used := 0;
      UPDATE public.user_profiles SET coaching_sessions_used=0, coaching_reset_at=now() WHERE id=auth.uid();
    END IF;
    quota_limit := CASE WHEN p.tier='premium' THEN 50 ELSE 1 END;
    IF p.coaching_sessions_used >= quota_limit THEN RETURN false; END IF;
    UPDATE public.user_profiles SET coaching_sessions_used=coaching_sessions_used+1 WHERE id=auth.uid();
    RETURN true;
  END IF;
  RAISE EXCEPTION 'unknown quota kind';
END;
$$;
REVOKE ALL ON FUNCTION public.consume_ai_quota(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consume_ai_quota(text) TO authenticated;

INSERT INTO storage.buckets (id,name,public) VALUES ('wardrobe-images','wardrobe-images',false),('avatars','avatars',false)
ON CONFLICT (id) DO UPDATE SET public=false;
DROP POLICY IF EXISTS user_owned_objects ON storage.objects;
CREATE POLICY user_owned_objects ON storage.objects FOR ALL TO authenticated
USING (bucket_id IN ('wardrobe-images','avatars') AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id IN ('wardrobe-images','avatars') AND (storage.foldername(name))[1] = auth.uid()::text);

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.wardrobe_items;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.outfit_logs;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
