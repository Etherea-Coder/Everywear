-- Reconcile the application backend without replacing recovered production rows.
-- Review against docs/recovered-supabase-reconciliation.md before any deployment.
-- Deliberately does not alter Storage bucket visibility or public policies.

-- Retire known client-callable legacy privilege RPCs. DROP IF EXISTS is safe for
-- the recovered project, where reset_monthly_suggestions is absent.
DROP FUNCTION IF EXISTS public.upgrade_user_to_premium(uuid);
DROP FUNCTION IF EXISTS public.reset_monthly_suggestions();
DROP FUNCTION IF EXISTS public.can_request_suggestion(uuid);
DROP FUNCTION IF EXISTS public.increment_suggestions_count(uuid);
DO $$ DECLARE signature text; BEGIN
  FOREACH signature IN ARRAY ARRAY[
    'public.increment_daily_suggestions(uuid)',
    'public.increment_coaching_sessions(uuid)',
    'public.increment_outfit_log_count(uuid)'
  ] LOOP
    IF to_regprocedure(signature) IS NOT NULL THEN
      EXECUTE 'REVOKE ALL ON FUNCTION ' || signature || ' FROM PUBLIC, anon, authenticated';
    END IF;
  END LOOP;
END $$;

-- Older local migrations create these application relations; the recovered
-- project already has them. Definitions below only apply on a clean local chain.
CREATE TABLE IF NOT EXISTS public.purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wardrobe_item_id uuid REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
  name text NOT NULL, price numeric(10,2) NOT NULL CHECK (price >= 0),
  purchase_date date NOT NULL, brand text, category public.clothing_category,
  image_url text, notes text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_budget (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  monthly_budget numeric(10,2) NOT NULL DEFAULT 0 CHECK (monthly_budget >= 0),
  currency text NOT NULL DEFAULT 'EUR', alert_at_percent integer NOT NULL DEFAULT 80,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.wishlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL, brand text, category text,
  target_price numeric(10,2), current_price numeric(10,2), url text,
  image_url text, notes text, is_purchased boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL, event_date date NOT NULL, event_type text NOT NULL,
  dress_code text, notes text,
  outfit_id uuid REFERENCES public.outfit_logs(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_quiz_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  style_profile text,
  preferred_colors jsonb NOT NULL DEFAULT '[]'::jsonb,
  style_goals jsonb NOT NULL DEFAULT '[]'::jsonb,
  answers jsonb NOT NULL DEFAULT '{}'::jsonb,
  style_intention text, completed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.style_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL,
  description text NOT NULL, type text NOT NULL DEFAULT 'general',
  goal integer NOT NULL DEFAULT 1 CHECK (goal > 0),
  duration_days integer NOT NULL DEFAULT 7, category text, is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(), points integer NOT NULL DEFAULT 0,
  difficulty text, icon text, estimated_time text, image_url text
);
ALTER TABLE public.style_challenges ADD COLUMN IF NOT EXISTS goal integer NOT NULL DEFAULT 1;
CREATE TABLE IF NOT EXISTS public.user_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id uuid NOT NULL REFERENCES public.style_challenges(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz,
  progress integer NOT NULL DEFAULT 0 CHECK (progress >= 0),
  anchor_item_id uuid REFERENCES public.wardrobe_items(id) ON DELETE SET NULL,
  insight text, UNIQUE(user_id, challenge_id)
);
ALTER TABLE public.user_challenges ADD COLUMN IF NOT EXISTS insight text;
CREATE TABLE IF NOT EXISTS public.learning_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), title text NOT NULL,
  description text NOT NULL, difficulty text, estimated_time text,
  unlock_required_outfits integer NOT NULL DEFAULT 0,
  unlock_requirement_label text, key_learnings text[] NOT NULL DEFAULT '{}',
  image_url text, semantic_label text, is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(), order_index integer NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS public.user_module_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id uuid NOT NULL REFERENCES public.learning_modules(id) ON DELETE CASCADE,
  progress double precision NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  started_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz,
  UNIQUE(user_id, module_id)
);
CREATE TABLE IF NOT EXISTS public.feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL, message text NOT NULL, rating integer, app_version text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.subscription_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  product_id text, event_type text, store text, expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Item counts may remain for display/legacy data, but wardrobe capacity is
-- unlimited in v1; remove the old free-tier item insert blocker.
DROP TRIGGER IF EXISTS enforce_item_limit ON public.wardrobe_items;

-- Add only the missing webhook columns; existing purchase audit fields and rows
-- remain intact. Null event ids on historical records allow a unique index.
ALTER TABLE public.subscription_transactions
  ADD COLUMN IF NOT EXISTS event_id text,
  ADD COLUMN IF NOT EXISTS event_at timestamptz,
  ADD COLUMN IF NOT EXISTS entitlement_id text,
  ADD COLUMN IF NOT EXISTS payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS processed_at timestamptz;
UPDATE public.subscription_transactions SET processed_at = created_at WHERE processed_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS subscription_transactions_event_id_uidx
  ON public.subscription_transactions(event_id) WHERE event_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS subscription_transactions_order_idx
  ON public.subscription_transactions(user_id, entitlement_id, event_at DESC)
  WHERE event_at IS NOT NULL;
ALTER TABLE public.subscription_transactions ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies
    WHERE schemaname='public' AND tablename='subscription_transactions' LOOP
    EXECUTE format('DROP POLICY %I ON public.subscription_transactions',p.policyname);
  END LOOP;
END $$;
REVOKE ALL ON public.subscription_transactions FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.subscription_transactions TO service_role;

-- Preserve the recovered DATE reset column and reuse the existing
-- revenue_cat_id field rather than creating a competing alias.
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS subscription_status text NOT NULL DEFAULT 'inactive',
  ADD COLUMN IF NOT EXISTS daily_suggestions_used integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS suggestions_reset_at date NOT NULL DEFAULT current_date,
  ADD COLUMN IF NOT EXISTS coaching_sessions_used integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS coaching_reset_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS outfit_logs_count integer NOT NULL DEFAULT 0;
DO $$ BEGIN
  ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_tier_check
    CHECK (tier IN ('free','premium')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_subscription_status_check
    CHECK (subscription_status IN ('inactive','active','grace_period','cancelled','expired')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Remove every permissive self-management profile policy before granting only
-- the intended profile/onboarding columns. The auth trigger provisions rows.
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies
    WHERE schemaname='public' AND tablename='user_profiles'
  LOOP EXECUTE format('DROP POLICY %I ON public.user_profiles', p.policyname); END LOOP;
END $$;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.user_profiles FROM PUBLIC, anon, authenticated;
DO $$ DECLARE column_name text; BEGIN
  FOR column_name IN SELECT c.column_name FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name='user_profiles' LOOP
    EXECUTE format('REVOKE UPDATE (%I), INSERT (%I), REFERENCES (%I) ON public.user_profiles FROM PUBLIC, anon, authenticated',
      column_name,column_name,column_name);
  END LOOP;
END $$;
GRANT SELECT ON public.user_profiles TO authenticated;
CREATE POLICY user_profiles_read_own ON public.user_profiles
  FOR SELECT TO authenticated USING (id = auth.uid());
GRANT UPDATE (full_name, avatar_url, updated_at, onboarding_completed,
  style_preferences, work_environment, social_frequency, climate,
  purchase_frequency, budget_consciousness, environmental_impact)
  ON public.user_profiles TO authenticated;
CREATE POLICY user_profiles_update_own ON public.user_profiles
  FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Verify both sides of outfit_items links under the authenticated identity.
CREATE OR REPLACE FUNCTION public.user_owns_outfit_and_item(outfit_uuid uuid, item_uuid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.outfit_logs o
    JOIN public.wardrobe_items w ON w.id = item_uuid
    WHERE o.id = outfit_uuid AND o.user_id = auth.uid() AND w.user_id = auth.uid()
  );
$$;
REVOKE ALL ON FUNCTION public.user_owns_outfit_and_item(uuid,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.user_owns_outfit_and_item(uuid,uuid) TO authenticated;
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies
    WHERE schemaname='public' AND tablename='outfit_items' LOOP
    EXECUTE format('DROP POLICY %I ON public.outfit_items',p.policyname);
  END LOOP;
END $$;
CREATE POLICY users_manage_own_outfit_items ON public.outfit_items
  FOR ALL TO authenticated
  USING (public.user_owns_outfit_and_item(outfit_id,item_id))
  WITH CHECK (public.user_owns_outfit_and_item(outfit_id,item_id));

-- Keep the product's 30/100 outfit-log limits and server-owned count accurate.
-- The profile row lock serializes concurrent inserts before counting.
UPDATE public.user_profiles p SET outfit_logs_count = (
  SELECT count(*) FROM public.outfit_logs o WHERE o.user_id=p.id
);
CREATE OR REPLACE FUNCTION public.enforce_outfit_log_quota()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE profile_tier text; profile_status text; profile_expiry timestamptz;
  has_paid_access boolean; current_count integer; quota_limit integer;
BEGIN
  IF auth.uid() IS NOT NULL AND NEW.user_id <> auth.uid() THEN
    RAISE EXCEPTION 'cannot create an outfit log for another user';
  END IF;
  SELECT tier, subscription_status, subscription_expires_at
    INTO profile_tier, profile_status, profile_expiry
    FROM public.user_profiles WHERE id=NEW.user_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  has_paid_access := profile_tier='premium' AND (
    (profile_status='active' AND (profile_expiry IS NULL OR profile_expiry > now())) OR
    (profile_status IN ('grace_period','cancelled') AND profile_expiry > now())
  );
  SELECT count(*) INTO current_count FROM public.outfit_logs WHERE user_id=NEW.user_id;
  quota_limit := CASE WHEN has_paid_access THEN 100 ELSE 30 END;
  IF current_count >= quota_limit THEN
    RAISE EXCEPTION 'outfit log limit reached' USING ERRCODE='check_violation';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.enforce_outfit_log_quota() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS enforce_outfit_log_quota ON public.outfit_logs;
CREATE TRIGGER enforce_outfit_log_quota BEFORE INSERT ON public.outfit_logs
  FOR EACH ROW EXECUTE FUNCTION public.enforce_outfit_log_quota();

CREATE OR REPLACE FUNCTION public.refresh_outfit_log_count()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE owner_id uuid;
BEGIN
  owner_id := COALESCE(NEW.user_id, OLD.user_id);
  UPDATE public.user_profiles SET outfit_logs_count=(
    SELECT count(*) FROM public.outfit_logs WHERE user_id=owner_id
  ) WHERE id=owner_id;
  RETURN COALESCE(NEW,OLD);
END;
$$;
REVOKE ALL ON FUNCTION public.refresh_outfit_log_count() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS refresh_outfit_log_count ON public.outfit_logs;
CREATE TRIGGER refresh_outfit_log_count AFTER INSERT OR DELETE ON public.outfit_logs
  FOR EACH ROW EXECUTE FUNCTION public.refresh_outfit_log_count();

-- Pin every existing privileged trigger helper and remove direct execution
-- grants from client-facing counter/inspection routines.
ALTER FUNCTION public.handle_new_user() SET search_path = pg_catalog, public;
ALTER FUNCTION public.check_item_limit_before_insert() SET search_path = pg_catalog, public;
ALTER FUNCTION public.increment_items_count() SET search_path = pg_catalog, public;
ALTER FUNCTION public.decrement_items_count() SET search_path = pg_catalog, public;
ALTER FUNCTION public.increment_wear_count() SET search_path = pg_catalog, public;
ALTER FUNCTION public.user_owns_outfit(uuid) SET search_path = pg_catalog, public;
ALTER FUNCTION public.update_updated_at_column() SET search_path = pg_catalog, public;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.user_owns_outfit(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.user_owns_outfit(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.check_item_limit_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.increment_items_count() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.decrement_items_count() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.increment_wear_count() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.update_updated_at_column() FROM PUBLIC, anon, authenticated;

-- Serialize event insertion and entitlement updates per user. event_id dedup
-- and event-time ordering are checked in the same transaction as profile state.
CREATE OR REPLACE FUNCTION public.apply_subscription_event(
  input_event_id text, input_user_id uuid, input_type text,
  input_event_at timestamptz, input_expires_at timestamptz,
  input_entitlement text, input_payload jsonb, input_tier text, input_status text
) RETURNS text LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE latest_event_at timestamptz;
BEGIN
  IF input_event_id IS NULL OR input_event_id = '' OR input_user_id IS NULL
     OR input_event_at IS NULL OR input_entitlement IS NULL
     OR input_tier NOT IN ('free','premium')
     OR input_status NOT IN ('inactive','active','grace_period','cancelled','expired') THEN
    RAISE EXCEPTION 'invalid subscription event';
  END IF;
  PERFORM 1 FROM public.user_profiles WHERE id=input_user_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  IF EXISTS (SELECT 1 FROM public.subscription_transactions WHERE event_id=input_event_id) THEN
    RETURN 'duplicate';
  END IF;
  SELECT max(event_at) INTO latest_event_at FROM public.subscription_transactions
    WHERE user_id=input_user_id AND entitlement_id=input_entitlement;
  INSERT INTO public.subscription_transactions
    (event_id,user_id,event_type,event_at,expires_at,entitlement_id,payload,processed_at)
  VALUES (input_event_id,input_user_id,input_type,input_event_at,input_expires_at,
    input_entitlement,coalesce(input_payload,'{}'::jsonb),now());
  IF latest_event_at IS NOT NULL AND latest_event_at >= input_event_at THEN RETURN 'stale'; END IF;
  UPDATE public.user_profiles SET tier=input_tier, subscription_status=input_status,
    subscription_expires_at=input_expires_at, revenue_cat_id=input_user_id::text
    WHERE id=input_user_id;
  RETURN 'applied';
END;
$$;
REVOKE ALL ON FUNCTION public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.apply_subscription_event(text,uuid,text,timestamptz,timestamptz,text,jsonb,text,text)
  TO service_role;

-- Atomic interactive AI quotas bind identity to auth.uid() and lock profile row.
-- This read-only helper is only a UI preflight. AI functions still consume
-- quota atomically through consume_ai_quota immediately before provider work.
CREATE OR REPLACE FUNCTION public.can_request_suggestion()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT CASE
    WHEN auth.uid() IS NULL THEN false
    WHEN p.suggestions_reset_at IS NULL OR p.suggestions_reset_at < current_date THEN true
    ELSE COALESCE(p.daily_suggestions_used,0) < CASE WHEN
      p.tier='premium' AND (
        (p.subscription_status='active' AND
          (p.subscription_expires_at IS NULL OR p.subscription_expires_at > now())) OR
        (p.subscription_status IN ('grace_period','cancelled') AND p.subscription_expires_at > now())
      ) THEN 999 ELSE 1 END
  END
  FROM public.user_profiles p WHERE p.id=auth.uid()
$$;
REVOKE ALL ON FUNCTION public.can_request_suggestion() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_request_suggestion() TO authenticated;

CREATE OR REPLACE FUNCTION public.consume_ai_quota(quota_kind text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE p public.user_profiles%ROWTYPE; quota_limit integer; has_paid_access boolean;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  SELECT * INTO p FROM public.user_profiles WHERE id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found'; END IF;
  has_paid_access := p.tier='premium' AND (
    (p.subscription_status='active' AND
      (p.subscription_expires_at IS NULL OR p.subscription_expires_at > now())) OR
    (p.subscription_status IN ('grace_period','cancelled') AND p.subscription_expires_at > now())
  );
  IF quota_kind='suggestion' THEN
    IF p.suggestions_reset_at IS NULL OR p.suggestions_reset_at < current_date THEN
      UPDATE public.user_profiles SET daily_suggestions_used=0,
        suggestions_reset_at=current_date WHERE id=auth.uid();
      p.daily_suggestions_used := 0;
    END IF;
    p.daily_suggestions_used := COALESCE(p.daily_suggestions_used,0);
    quota_limit := CASE WHEN has_paid_access THEN 999 ELSE 1 END;
    IF p.daily_suggestions_used >= quota_limit THEN RETURN false; END IF;
    UPDATE public.user_profiles SET daily_suggestions_used=daily_suggestions_used+1 WHERE id=auth.uid();
    RETURN true;
  ELSIF quota_kind='coach' THEN
    IF p.coaching_reset_at IS NULL OR
       (has_paid_access AND now() >= p.coaching_reset_at + interval '1 month') OR
       (NOT has_paid_access AND now() >= p.coaching_reset_at + interval '7 days') THEN
      UPDATE public.user_profiles SET coaching_sessions_used=0, coaching_reset_at=now()
        WHERE id=auth.uid();
      p.coaching_sessions_used := 0;
    END IF;
    p.coaching_sessions_used := COALESCE(p.coaching_sessions_used,0);
    quota_limit := CASE WHEN has_paid_access THEN 50 ELSE 1 END;
    IF p.coaching_sessions_used >= quota_limit THEN RETURN false; END IF;
    UPDATE public.user_profiles SET coaching_sessions_used=coaching_sessions_used+1 WHERE id=auth.uid();
    RETURN true;
  END IF;
  RAISE EXCEPTION 'unknown quota kind';
END;
$$;
REVOKE ALL ON FUNCTION public.consume_ai_quota(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consume_ai_quota(text) TO authenticated;

-- Consolidate owner tables to a single authenticated policy each.
DO $$ DECLARE t text; p record; BEGIN
  FOREACH t IN ARRAY ARRAY['purchases','user_budget','wishlist','style_events',
    'style_quiz_results','user_challenges','user_module_progress','feedback'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
    FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename=t LOOP
      EXECUTE format('DROP POLICY %I ON public.%I',p.policyname,t);
    END LOOP;
    EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon',t);
    EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO authenticated',t);
    EXECUTE format('CREATE POLICY owner_rows ON public.%I FOR ALL TO authenticated USING (user_id=auth.uid()) WITH CHECK (user_id=auth.uid())',t);
  END LOOP;
END $$;

ALTER TABLE public.style_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE p record; BEGIN
  FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename='style_challenges' LOOP
    EXECUTE format('DROP POLICY %I ON public.style_challenges',p.policyname);
  END LOOP;
  FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename='learning_modules' LOOP
    EXECUTE format('DROP POLICY %I ON public.learning_modules',p.policyname);
  END LOOP;
END $$;
REVOKE ALL ON public.style_challenges, public.learning_modules FROM PUBLIC, anon;
GRANT SELECT ON public.style_challenges, public.learning_modules TO authenticated;
CREATE POLICY authenticated_read_challenges ON public.style_challenges
  FOR SELECT TO authenticated USING (is_active);
CREATE POLICY authenticated_read_learning ON public.learning_modules
  FOR SELECT TO authenticated USING (is_active);

-- Stable public learning catalog content only. Do not fabricate user activity.
INSERT INTO public.style_challenges (id,title,description,type,goal,duration_days,icon,is_active)
VALUES
 ('10000000-0000-4000-8000-000000000001','Rediscover a favorite','Wear an item you have not reached for recently.','rediscover',1,7,'refresh',true),
 ('10000000-0000-4000-8000-000000000002','Three ways, one piece','Build three distinct outfits around one wardrobe item.','anchor_piece',3,7,'checkroom',true),
 ('10000000-0000-4000-8000-000000000003','Try a tonal outfit','Create an outfit using shades from one color family.','color_outfit',1,7,'palette',true)
ON CONFLICT DO NOTHING;

INSERT INTO public.learning_modules
  (id,order_index,title,description,difficulty,estimated_time,
   unlock_required_outfits,unlock_requirement_label,key_learnings,is_active)
VALUES
 ('20000000-0000-4000-8000-000000000001',1,'Know what you own','Build a useful wardrobe inventory before buying more.','Beginner','15 min',0,'Available from start',ARRAY['Photograph each item','Record fit, fabric and condition'],true),
 ('20000000-0000-4000-8000-000000000002',2,'Cost per wear','Use real wear history to understand the value of a purchase.','Beginner','15 min',0,'Available from start',ARRAY['Track actual wears','Compare cost per wear over time'],true),
 ('20000000-0000-4000-8000-000000000003',3,'Build a small capsule','Combine versatile pieces into more outfits with fewer items.','Beginner','20 min',0,'Available from start',ARRAY['Choose a color base','Test combinations you own'],true),
 ('20000000-0000-4000-8000-000000000004',4,'Understand color','Notice which colors work together in your existing wardrobe.','Beginner','15 min',3,'Log three outfits',ARRAY['Identify a neutral base','Repeat accent colors'],true),
 ('20000000-0000-4000-8000-000000000005',5,'Choose a reliable fit','Record how garments fit so future choices are more informed.','Beginner','15 min',3,'Log three outfits',ARRAY['Notice comfort and movement','Keep useful fit notes'],true),
 ('20000000-0000-4000-8000-000000000006',6,'Layer with intention','Use layers to adapt outfits to weather and activity.','Intermediate','20 min',5,'Log five outfits',ARRAY['Start with a light base','Add a practical outer layer'],true),
 ('20000000-0000-4000-8000-000000000007',7,'Care for garments','Use garment labels and fabric guidance to extend useful wear.','Beginner','15 min',5,'Log five outfits',ARRAY['Check the care label','Repair small issues early'],true),
 ('20000000-0000-4000-8000-000000000008',8,'Plan for an occasion','Build an outfit around the event, dress code and forecast.','Intermediate','20 min',7,'Log seven outfits',ARRAY['Check the dress code','Consider comfort and weather'],true),
 ('20000000-0000-4000-8000-000000000009',9,'Shop with a list','Compare a planned purchase with pieces already in your wardrobe.','Intermediate','15 min',7,'Log seven outfits',ARRAY['Define the wardrobe gap','Check cost and expected use'],true),
 ('20000000-0000-4000-8000-000000000010',10,'Repeat outfits confidently','Use outfit history to find combinations worth wearing again.','Intermediate','15 min',10,'Log ten outfits',ARRAY['Review outfits you liked','Save repeatable combinations'],true),
 ('20000000-0000-4000-8000-000000000011',11,'Make a seasonal edit','Review stored items against the season and your actual needs.','Intermediate','20 min',10,'Log ten outfits',ARRAY['Keep items in usable condition','Notice genuine wardrobe gaps'],true),
 ('20000000-0000-4000-8000-000000000012',12,'Build a personal uniform','Find repeatable outfit patterns that suit your daily routine.','Intermediate','20 min',12,'Log twelve outfits',ARRAY['Look for patterns in outfit history','Adapt a reliable base'],true)
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS purchases_user_date_idx ON public.purchases(user_id,purchase_date DESC);
CREATE INDEX IF NOT EXISTS wishlist_user_created_idx ON public.wishlist(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS style_events_user_date_idx ON public.style_events(user_id,event_date);
CREATE INDEX IF NOT EXISTS user_challenges_user_idx ON public.user_challenges(user_id);
CREATE INDEX IF NOT EXISTS module_progress_user_idx ON public.user_module_progress(user_id);

-- Do not change the recovered Storage buckets here. Private cutover is a
-- separate reviewed operation after clients and legacy-reference conversion.
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.wardrobe_items;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.outfit_logs;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
