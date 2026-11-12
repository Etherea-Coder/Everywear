-- Some recovered Everywear databases already have this column. The original
-- local migration chain did not create it, although later subscription/quota
-- functions require it. This additive prerequisite is therefore a no-op on
-- the recovered schema and completes fresh local installations.
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;
