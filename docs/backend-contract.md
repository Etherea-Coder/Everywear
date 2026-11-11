# Backend contract

Last updated: 2026-11-12

This document is derived from application code and Edge Functions. It is a living contract; it does not treat the incomplete historical migrations as authoritative.

The original Supabase project has been recovered. The forward migration in this branch is a reconciliation proposal, not an approved hosted migration. It must be compared with the recovered schema, policies, buckets, publications, functions, and existing data before any deployment.

## Recovered project facts (read-only, 2026-11-11)

The linked production project `qxsdwwdrxoyxmnapuqqv` was inspected using the Docker-free Supabase CLI read-only query path as `supabase_read_only_user` on PostgreSQL 17.6. The exact tables, policies, function/trigger inventory, bucket settings, grants, relationships, and deployed-function defects are recorded in [recovered-supabase-reconciliation.md](recovered-supabase-reconciliation.md). In brief: all 16 public app tables enable RLS but none forces it; the current profile policy/grants permit self-editing all protected columns; the self-upgrade SECURITY DEFINER RPC is present and callable; outfit links check outfit ownership only; counter helpers are callable; the Realtime publication has no tables; and both Storage buckets are public. These are production risks, not locally verified fixes.

The local forward migration has been reconciled to the recovered column names and types where metadata was available, but it remains an unexecuted review proposal. In particular it reuses the recovered `revenue_cat_id text` field and `suggestions_reset_at date`, and adds only missing subscription state/event fields and app relations. The `supabase_migrations.schema_migrations` relation was absent in the read-only lookup; migration history was not modified. Do not use `db push` or repair history against production.

## Trust boundaries

- The Flutter client receives only the Supabase URL, publishable/anon key, RevenueCat public Android SDK key, and the configured paid entitlement identifier.
- Gemini keys, Supabase service-role credentials, RevenueCat secret API keys, and webhook authorization secrets are server-only.
- Client callers never set subscription tier/expiry, quotas, or usage counters.
- Authenticated clients cannot insert/delete `user_profiles` or update protected columns; only profile/onboarding presentation columns are writable.
- Every user-owned row and object is isolated by `auth.uid()`. Cross-table mutations validate ownership of every referenced record.
- `SECURITY DEFINER` functions set a safe `search_path`, revoke public execution, and explicitly grant only required roles.
- AI quota checks and increments occur atomically in the database, not as separate client or function reads/writes.

## Application data contract

| Area | Relations / operations |
|---|---|
| Identity | `user_profiles`: profile/onboarding fields are user-editable; tier, subscription state, limits and counters are server-managed |
| Wardrobe | `wardrobe_items` CRUD and Realtime; private `wardrobe-images/{user_id}/...` objects |
| Outfit history | `outfit_logs` CRUD and Realtime; `outfit_items` links require ownership of both the outfit and item |
| Spending | `purchases`, `user_budget`, `wishlist` user-owned CRUD |
| Style | `style_events`, `style_quiz_results` user-owned CRUD |
| Challenges | authenticated catalog read from `style_challenges`; own progress in `user_challenges` |
| Learning | authenticated catalog read from `learning_modules`; own `user_module_progress` |
| Support | user-owned insert/read of `feedback` |
| Billing | server-only `subscription_transactions`; server-managed entitlement fields on `user_profiles` |
| Profile media | private `avatars/{user_id}/...` objects |

The catalog seed contains only factual learning modules and challenge definitions. It creates no user history, reviews, or testimonials.

## RPCs

- `consume_ai_quota(quota_kind text) -> boolean`: authenticated, row-locked atomic quota check/increment for `suggestion` or `coach`.
- Outfit-log limits and `outfit_logs_count` are enforced/maintained by database triggers under a locked profile row; the Flutter client does not mutate the counter.
- `user_owns_outfit_and_item(outfit_uuid uuid, item_uuid uuid) -> boolean`: authenticated policy helper validating both sides of a junction row.
- Legacy `upgrade_user_to_premium(uuid)` is revoked and dropped. A user can never directly grant a tier.
- Legacy counter RPCs are not a trusted authorization boundary and must not be callable by clients; interactive AI functions use `consume_ai_quota`.

## Edge Functions

Interactive functions `ai-suggestions`, `analyze-clothing`, `generate-ai-insights`, `style-coach`, `today-suggestion`, `check-and-request-suggestion`, `verify-purchase`, and `delete-account` must call `auth.getUser()` with the bearer token and reject invalid users before any privileged operation. `revenuecat-webhook` is machine-to-machine and authenticates its configured webhook secret.

`verify-purchase` derives the RevenueCat customer from the authenticated Supabase UUID, requires the exact configured entitlement, and fails closed. `revenuecat-webhook` reads fields from the wrapped `event`, records its unique event ID, and ignores stale events after comparing event time.

## Required security proofs

Local fixtures must cover anonymous, user A, and user B access for:

- CRUD isolation on every user-owned table.
- Outfit-to-wardrobe links where either side is owned by another user.
- Storage list/read/write/delete isolation.
- Protected subscription fields and quota counters.
- Concurrent AI quota requests at and beyond the limit.
- Edge Function rejection of absent, invalid, expired, and mismatched JWTs.

## Recovered-backend reconciliation checklist

- Obtain a schema-only dump or equivalent read-only inventory; do not expose row contents or secrets.
- Compare relation columns/types/constraints before running any `ALTER TABLE` or catalog seed.
- Inventory existing RLS policies, grants, SECURITY DEFINER owners/search paths, triggers, RPC grants, Storage bucket visibility/policies, and Realtime publication membership.
- Preserve existing user/account rows, object paths, catalog identifiers, and billing audit records.
- Resolve private Storage delivery in the client (authenticated/signed URLs) before changing an existing public bucket to private.
- Apply only reviewed, forward-only deltas and prove anonymous/user-A/user-B isolation in a non-production environment first.
