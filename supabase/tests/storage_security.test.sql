-- Local-only regression fixture. Requires the schema migration and the
-- review-only private-image cutover to have been applied to a disposable local
-- Supabase database. Never run against the recovered production project.
BEGIN;
SELECT plan(11);

INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES
  ('11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
   'storage-a@example.invalid', '', now(), '{}', '{}', now(), now()),
  ('22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated',
   'storage-b@example.invalid', '', now(), '{}', '{}', now(), now());

-- The rows and buckets are fixture-only and the surrounding transaction rolls
-- back. Force private visibility so this fixture catches a public bucket.
INSERT INTO storage.buckets (id, name, public)
VALUES ('wardrobe-images', 'wardrobe-images', false), ('avatars', 'avatars', false)
ON CONFLICT (id) DO UPDATE SET public = false;

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id, metadata)
VALUES
  ('33333333-3333-4333-8333-333333333333', 'wardrobe-images',
   '11111111-1111-4111-8111-111111111111/fixture-a.jpg',
   '11111111-1111-4111-8111-111111111111',
   '11111111-1111-4111-8111-111111111111', '{"mimetype":"image/jpeg","size":1}'),
  ('44444444-4444-4444-8444-444444444444', 'wardrobe-images',
   '22222222-2222-4222-8222-222222222222/fixture-b.jpg',
   '22222222-2222-4222-8222-222222222222',
   '22222222-2222-4222-8222-222222222222', '{"mimetype":"image/jpeg","size":1}'),
  ('55555555-5555-4555-8555-555555555555', 'avatars',
   '11111111-1111-4111-8111-111111111111/avatar.jpg',
   '11111111-1111-4111-8111-111111111111',
   '11111111-1111-4111-8111-111111111111', '{"mimetype":"image/jpeg","size":1}');

SELECT is(
  (SELECT count(*)::integer FROM storage.buckets
   WHERE id IN ('wardrobe-images', 'avatars') AND public),
  0,
  'both image buckets are private'
);

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '33333333-3333-4333-8333-333333333333'),
  0,
  'anonymous users cannot list/read a wardrobe object'
);
RESET ROLE;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '33333333-3333-4333-8333-333333333333'),
  1,
  'user A can read their wardrobe image'
);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '44444444-4444-4444-8444-444444444444'),
  0,
  'user A cannot read user B wardrobe image'
);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '55555555-5555-4555-8555-555555555555'),
  1,
  'user A can read their avatar'
);

INSERT INTO storage.objects (bucket_id, name, owner, owner_id, metadata)
VALUES ('wardrobe-images',
  '11111111-1111-4111-8111-111111111111/uploaded.jpg',
  '11111111-1111-4111-8111-111111111111',
  '11111111-1111-4111-8111-111111111111', '{"mimetype":"image/jpeg","size":1}');
SELECT ok(true, 'user A can upload into their own folder');

SELECT throws_ok(
  $$INSERT INTO storage.objects (bucket_id, name, owner, owner_id, metadata)
    VALUES ('wardrobe-images',
      '22222222-2222-4222-8222-222222222222/forbidden.jpg',
      '11111111-1111-4111-8111-111111111111',
      '11111111-1111-4111-8111-111111111111', '{"mimetype":"image/jpeg","size":1}')$$,
  '42501',
  'user A cannot upload into user B folder'
);
SELECT is(
  (WITH removed AS (
    DELETE FROM storage.objects
    WHERE id = '44444444-4444-4444-8444-444444444444'
    RETURNING id
  ) SELECT count(*)::integer FROM removed),
  0,
  'user A cannot delete user B image'
);
SELECT is(
  (WITH removed AS (
    DELETE FROM storage.objects
    WHERE id = '33333333-3333-4333-8333-333333333333'
    RETURNING id
  ) SELECT count(*)::integer FROM removed),
  1,
  'user A can delete their image'
);

RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
SELECT set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '44444444-4444-4444-8444-444444444444'),
  1,
  'user B can read their wardrobe image'
);
SELECT is(
  (SELECT count(*)::integer FROM storage.objects
   WHERE id = '55555555-5555-4555-8555-555555555555'),
  0,
  'user B cannot read user A avatar'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
