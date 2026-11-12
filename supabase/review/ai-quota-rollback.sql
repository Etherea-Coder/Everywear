-- Review-only safe stop for a quota rollout that must be paused.
-- This disables new AI reservations while preserving every usage counter and
-- reservation for investigation. Do not drop quota tables or reset counters.
-- Run only through a separately approved non-production/production change.
REVOKE ALL ON FUNCTION public.reserve_ai_action(uuid, text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.finalize_ai_action(uuid, text, text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_ai_allowance()
  FROM PUBLIC, anon, authenticated;

-- Privacy-safe rollback intentionally does not restore the legacy
-- consume_ai_quota grants. The app's AI functions must remain unavailable
-- until the quota migration is repaired and re-enabled.
