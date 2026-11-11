-- REVIEW-ONLY production rollout SQL. Never included in supabase/migrations and
-- never apply until the ordered checklist in docs/recovered-supabase-reconciliation.md
-- is approved, legacy references are inventoried, and a backup is confirmed.
-- This script intentionally preserves private access on rollback.
BEGIN;

UPDATE storage.buckets SET public = false
WHERE id IN ('wardrobe-images', 'avatars');

-- Names and predicates were read-only inspected on recovered production on
-- 2026-11-11. Remove only the two public read policies for these buckets.
DROP POLICY IF EXISTS "Public can read wardrobe images" ON storage.objects;
DROP POLICY IF EXISTS "Public Read 1oj01fe_0" ON storage.objects;

-- Replace the existing per-bucket policies with explicit owner checks for all
-- operations. Stable references use {bucket}/{auth.uid()}/{object path}.
DROP POLICY IF EXISTS "Users can read their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;
DROP POLICY IF EXISTS "Users Update Own Avatar 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Users Update Own Avatar 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Users Upload Own Avatar 1oj01fe_0" ON storage.objects;

CREATE POLICY everywear_owner_image_read ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id IN ('wardrobe-images','avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
CREATE POLICY everywear_owner_image_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('wardrobe-images','avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
CREATE POLICY everywear_owner_image_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id IN ('wardrobe-images','avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)
  WITH CHECK (bucket_id IN ('wardrobe-images','avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
CREATE POLICY everywear_owner_image_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id IN ('wardrobe-images','avatars')
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

COMMIT;
