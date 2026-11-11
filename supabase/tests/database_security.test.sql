-- Local-only pgTAP fixture. Never run against the recovered production project.
-- Runs after the complete migration chain in a disposable local database.
BEGIN;
SELECT plan(9);

INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES
  ('11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
   'recovery-a@example.invalid', '', now(), '{}', '{}', now(), now()),
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
  'authenticated cannot write protected profile fields'
);
SELECT throws_ok(
  $$INSERT INTO public.outfit_items (outfit_id, item_id)
    VALUES ('55555555-5555-4555-8555-555555555555', '44444444-4444-4444-8444-444444444444')$$,
  '42501',
  'outfit_items RLS rejects a link to another user wardrobe item'
);

SELECT ok(public.consume_ai_quota('suggestion'), 'first free suggestion consumes one quota unit');
SELECT ok(NOT public.consume_ai_quota('suggestion'), 'a second free suggestion is rejected');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
