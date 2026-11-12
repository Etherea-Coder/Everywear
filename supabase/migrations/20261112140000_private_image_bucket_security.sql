-- Keep wardrobe and avatar images private and owner-scoped. On a fresh project,
-- create the buckets; on the recovered project, preserve existing bucket
-- metadata while disabling public access. Production rollout must wait until
-- image references have been converted and the compatible client is deployed.
BEGIN;

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('wardrobe-images', 'wardrobe-images', false),
  ('avatars', 'avatars', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Remove the exact public and per-owner policies observed in the recovered
-- production catalog. IF EXISTS also makes this safe for the fresh staging DB.
DROP POLICY IF EXISTS "Public can read wardrobe images" ON storage.objects;
DROP POLICY IF EXISTS "Public Read 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Users can read their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users Update Own Avatar 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Users Update Own Avatar 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Users Upload Own Avatar 1oj01fe_0" ON storage.objects;

CREATE POLICY everywear_owner_image_read ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id IN ('wardrobe-images', 'avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY everywear_owner_image_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('wardrobe-images', 'avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY everywear_owner_image_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('wardrobe-images', 'avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  )
  WITH CHECK (
    bucket_id IN ('wardrobe-images', 'avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

CREATE POLICY everywear_owner_image_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('wardrobe-images', 'avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

COMMIT;
