# Recovered Supabase reconciliation (read-only)

Inspection performed 2026-11-11 through Supabase CLI 3.1.0 `db query --remote=qxsdwwdrxoyxmnapuqqv --read-only` and `functions list/download`. The project name/ref, organization and region were confirmed from the authenticated project list before querying. The database reports PostgreSQL 17.6 and execution as `supabase_read_only_user`. No hosted mutation, customer-row query, object-content access, migration-history repair, deployment, or setting change was performed.

Deployed Edge Function source is preserved separately under the ignored `.tooling/recovery/remote-functions-project/supabase/functions/`; the earlier `.tooling/recovery/functions-downloaded-2026-11-11/` snapshot is also preserved. No downloaded source was copied into `supabase/functions`.

## Database inventory

All 16 application relations in `public` have RLS enabled, but none has FORCE ROW LEVEL SECURITY. Public-schema tables are `challenges`, `feedback`, `learning_modules`, `outfit_items`, `outfit_logs`, `purchases`, `style_challenges`, `style_events`, `style_quiz_results`, `subscription_transactions`, `user_budget`, `user_challenges`, `user_module_progress`, `user_profiles`, `wardrobe_items`, and `wishlist`.

Important recovered shapes:

- `user_profiles` already contains `tier`, `items_count`, `monthly_suggestions_used`, `items_limit`, `suggestions_limit`, `subscription_expires_at`, `revenue_cat_id`, AI counters/reset timestamps, onboarding fields, and `outfit_logs_count`. It lacks `subscription_status` and `revenuecat_customer_id`; its existing `revenue_cat_id` spelling is distinct.
- `subscription_transactions` is currently `id,user_id,product_id,event_type,store,expires_at,created_at`. It has no `event_id`, event timestamp, entitlement id, payload, or processed timestamp required for atomic webhook idempotency.
- `style_challenges` has `type`, `title`, `description`, `duration_days`, `goal`, and other presentation fields; it has no `challenge_type` column.
- `learning_modules` has difficulty/unlock/image fields but no `content` JSON field.
- `feedback` has required `type` and `message`, not the reconstruction migration’s `category` and optional `email` contract.
- `purchases` already exists with `price numeric(10,2)`, `category clothing_category`, and required `purchase_date`; `user_budget` already has an id PK, unique user id, currency and alert percentage.
- `style_quiz_results` stores preferred colors/goals as `jsonb` and has no unique `user_id` constraint.

Public relations have primary keys and the reported FK relationships. The outfit join has FKs to `outfit_logs` and `wardrobe_items`, plus uniqueness on `(outfit_id,item_id)`, but no owner column. Index inventory includes the expected owner/date/category indexes and does not include a recent webhook event id index because that column does not exist.

## Confirmed security and behavior differences

- The `users_manage_own_user_profiles` permissive `ALL` policy remains alongside the policy named `Users cannot self-upgrade tier`. PostgreSQL combines permissive policies with OR, so the broad policy defeats the narrower tier check. Authenticated role column privilege checks report UPDATE for every profile column, including `tier`, expiry, RevenueCat id, limits and counters. Table ACL checks also show `anon` and `authenticated` table privileges; effective row isolation is therefore critically dependent on RLS.
- `upgrade_user_to_premium(uuid)` is `SECURITY DEFINER`, checks only that caller and argument UUID match, sets premium and larger limits, and is executable by `anon`, `authenticated`, and `service_role` through effective grants. This is a confirmed self-upgrade vulnerability.
- `users_manage_own_outfit_items` calls `user_owns_outfit(outfit_id)`, which checks only the outfit owner. It does not verify that the linked wardrobe item belongs to the same user.
- Counter RPCs including `increment_suggestions_count(uuid)`, `increment_daily_suggestions(uuid)`, `increment_coaching_sessions(uuid)`, and `increment_outfit_log_count(uuid)` are callable by `anon` and `authenticated` according to effective function privileges. The SECURITY DEFINER suggestion counter accepts an arbitrary user UUID. `can_request_suggestion(uuid)` is also executable and can disclose a quota predicate for arbitrary profile ids. Interactive AI usage is not protected by an atomic quota RPC in the deployed AI functions.
- Eight public SECURITY DEFINER functions were inventoried. Their `proconfig` contains no pinned `search_path`; trigger helpers use schema-qualified table names, but all functions still require explicit execution-grant review and hardening. Trigger inventory includes auth user provisioning, item-limit/count triggers, wear-count updates, and timestamp updates. No outfit-log count/quota trigger was found.
- RLS policies on `user_challenges` are duplicated, including a `PUBLIC` owner-equality policy. They remain owner-filtered by `auth.uid()`, but should be consolidated in the reviewed migration.
- `supabase_realtime` currently publishes no tables. Existing client Realtime subscriptions therefore need a reconciled publication change before they can work.
- Storage buckets `wardrobe-images` and `avatars` both exist, are `public=true`, have no size/MIME restrictions, and have `STANDARD` type. `wardrobe-images` has a public/anon read policy plus authenticated owner-folder read/insert/delete; `avatars` has a public read policy and authenticated owner-folder read/insert/update, but no avatar DELETE policy. Existing buckets/objects were not changed.
- The read-only lookup of `supabase_migrations.schema_migrations` returned SQLSTATE `42P01` (relation absent). No alternate migration-history location was inferred and no history repair was attempted.

## Deployed Edge Functions

The recovered project has 10 active functions: `ai-suggestions` v15, `create-subscription-payment` v10, `analyze-clothing` v9, `style-coach` v16, `today-suggestion` v11, `revenuecat-webhook` v4, `delete-account` v4, `verify-purchase` v4, `generate-ai-insights` v6, and `check-and-request-suggestion` v3.

- `analyze-clothing` reads the Authorization header and rejects only if absent, then calls Gemini; it does not validate the user token, make a user-bound Supabase `auth.getUser()` call, or consume quota before the model request. This defect is confirmed from its complete deployed source. The local version validates identity and consumes the atomic quota RPC; that fix awaits deployment.
- `today-suggestion` does not read/validate Authorization or call a shared auth helper. It accepts user/profile/wardrobe content in the request body and calls Gemini. No bundled/helper import exists in the downloaded source. This defect is confirmed. Local code validates via `auth.getUser()` and atomically consumes quota; that fix awaits deployment.
- `style-coach`, `generate-ai-insights`, `ai-suggestions`, `check-and-request-suggestion`, `verify-purchase`, `delete-account`, and `create-subscription-payment` validate caller identity via `auth.getUser()` in their source. Their gateway JWT configuration was not treated as proof either way.
- Deployed `verify-purchase` trusts caller `revenue_cat_user_id`, uses RevenueCat API v1 subscriber endpoint, accepts any entitlement with null/future expiry, writes tier `premium`, and does not require the configured entitlement. The local function derives the customer id from authenticated Supabase identity and fails closed on the exact configured entitlement; not deployed.
- Deployed `revenuecat-webhook` correctly unwraps `body.event`, but has no event idempotency or ordering, maps cancellation/billing issue immediately to free, and upserts transaction history on `(user_id,product_id)`. Local code uses a service-only transactional RPC for idempotency/order and distinguishes grace/cancellation; not deployed.
- Deployed `delete-account` validates identity, but table deletion result errors are ignored and the function never removes Storage objects. Local deletion handles owned Storage objects and checks data deletion results; not deployed.
- Deployed interactive AI functions do not call `consume_ai_quota`; request billing can be bypassed independently of the local client fixes.

## Required reconciled rollout (not applied)

1. Keep current public bucket visibility while shipping and verifying client support for stable bucket/object references, exact-origin legacy URL canonicalization, authenticated on-demand URL resolution, PDF in-memory image embedding, and CSV omission of image URLs. This client work is present locally but untested.
2. Before migration, take a provider-managed backup and inventory bucket objects/paths and only the reference columns needed for conversion. Confirm existing folder names map to Supabase user ids and identify any shared/provider images. Convert only exact project Storage URL paths to stable `bucket/path`; preserve genuine external provider URLs and never copy signed tokens.
3. Apply reviewed owner-folder Storage SELECT/INSERT/UPDATE/DELETE policies for both buckets and remove all public-read policies. Set both existing bucket rows private in the same reviewed, forward-only release operation only after client rollout and access checks are ready. Add file-size and image MIME restrictions after confirming existing legitimate formats.
4. Verify anonymous denial and user A/user B own/cross-user read, list, insert, replace, delete, avatar, and expired signed-link behavior. Confirm current authenticated image views and PDF export for legacy and stable references before proceeding.
5. Purge or account for public-CDN/browser caches and old public URLs. Treat copied public URLs as compromised until cache expiry/invalidation is confirmed; private bucket toggling alone must not be claimed to retract already cached bytes.
6. Privacy-preserving rollback: keep buckets private and retain restrictive owner policies. If client delivery fails, roll back application release to a compatibility build that authenticates and resolves authorized image objects, or disable image display/export with clear unavailable placeholders. Do not restore public buckets/policies as rollback. If conversion is wrong, repair references back to stable private paths from the migration audit, not to public URLs.

The existing `20261111090000_reconstruct_and_secure_backend.sql` is not reconciled and must not be applied to this recovered project. It assumes mismatching columns, types and table definitions (for example `subscription_transactions.event_id`, `style_challenges.challenge_type`, `learning_modules.content`, and feedback `category`), and contains an unconditional `REVOKE` for `reset_monthly_suggestions()` although that function is absent from the inspected public function list. A replacement forward migration must target these exact recovered shapes, preserve rows and catalog ids, and be validated against a schema-only clone before any production proposal is considered.
