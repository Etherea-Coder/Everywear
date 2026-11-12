# Server-side AI quota proposal

**Status:** local implementation and migration prepared; not applied to any hosted database.

**Policy status:** provisional configurable defaults, not a customer promise.
**Time basis:** UTC.

## What consumes an action

One action is reserved atomically immediately before each provider request by
any of these authenticated Edge Functions:

- `analyze-clothing`
- `ai-suggestions` (outfit-photo advice)
- `today-suggestion`
- `style-coach` (passive, active, and event modes)
- `generate-ai-insights`

They share one account-level allowance. Manual clothing entry, browsing saved
wardrobe/outfits, deterministic local outfit features, exports, and ordinary
CRUD do not consume AI actions. The passive coach currently remains an AI
request when invoked by the screen; it therefore consumes the same allowance.

## Provisional limits

| Server-derived tier | Month (UTC calendar month) | Day (UTC calendar day) | Burst (fixed UTC minute) | In-flight |
|---|---:|---:|---:|---:|
| Free | 20 actions | 3 actions | 1 action | 1 request |
| Premium | 200 actions | 20 actions | 5 actions | 3 requests |

Premium monthly and annual subscriptions receive the same UTC calendar
allowances while the server profile has an authoritative, currently valid
subscription state. Active, grace-period, and cancelled states retain premium
limits only while a non-null recorded expiry is in the future. Missing expiry,
expired, missing, or downgraded entitlements use free limits. Confirm that the
deployed RevenueCat webhook always records the correct status and expiry before
rollout. Clients do not submit a tier, counter, or reset date.

Windows reset at their next UTC boundary: the first UTC day of the next month,
00:00 UTC for the daily allowance, and the next UTC minute for burst control.
In-flight reservations older than 30 seconds stop counting toward concurrency;
the provider request itself times out after 20 seconds. Counters are reserved
before making a provider request and are never refunded. Thus provider errors,
invalid responses, timeouts, and interrupted requests count, since provider
billing may already have occurred. There are no application retries or model
fallbacks. The OpenRouter request also sets `allow_fallbacks: false` and a
maximum accepted per-token price, but OpenRouter's general routing docs mention
retrying failed provider attempts. Its precise retry/billing behavior for these
requests remains unverified; action quotas do not prove a hard invoice cap.
Repeating an operation with the same user-scoped UUID is rejected;
a new logical action needs a fresh UUID but remains inside all shared limits.
The uniqueness key is user plus UUID (stricter across endpoints than
user-plus-operation), preventing endpoint switching from replaying the same
identifier. The idempotency ledger is retained for 90 days, after which a
random UUID can technically be reused.

## Implementation and migration

The prepared migration is
`supabase/migrations/20261112100000_server_ai_action_quotas.sql`. It creates
private usage buckets, a reservation/idempotency ledger, and the
`ai_quota_policies` table seeded with the provisional limits above. Policy rows
are configurable only through reviewed privileged database access, are not
readable or writable by app users, and are inserted without overwriting an
existing operator-tuned row. Database constraints prevent configuration from
exceeding 200 monthly, 20 daily, 5/minute, or 3 concurrent actions per user;
lower values can be selected during rollout. The migration enables RLS, revokes client table
access, and defines `get_ai_allowance`,
`reserve_ai_action`, and `finalize_ai_action` as SECURITY DEFINER functions
with pinned search paths and explicit authenticated-only grants. A per-user
profile row lock serializes entitlement evaluation, duplicate detection,
concurrency checks, and monthly/daily/burst increments. It derives access from
`user_profiles`; no caller-provided tier or counter is accepted. Active,
grace-period, and cancelled profiles require a non-null future expiry to obtain
premium limits; missing expiry fails closed to free. Legacy client-callable AI
quota functions are revoked. This migration depends on the
reviewed subscription fields in the preceding recovery migration and has not
been reconciled against or applied to production.

All five model-backed handlers authenticate with Supabase Auth before reading
protected data or invoking providers. They reserve only after request parsing,
configuration checks, and required authenticated data checks. Failures after
reservation finalize the attempt where possible; the reservation remains
consumed if finalization itself fails. Provider timeouts, response byte limits,
request body bounds, JPEG validation, prompt byte caps, and output-token caps
are shared or explicit in source. See `docs/ai-cost-review.md` for the per
feature input/output ceilings and modeled costs.

## Rollout and rollback

1. Reconcile the full migration chain against the recovered database, including
   exact `user_profiles` subscription column names/status semantics, existing
   quota RPC consumers, and privileges. Do not rewrite or reset history.
2. Apply the migration to an isolated disposable staging database, then run
   `supabase/tests/database_security.test.sql` and
   `supabase/tests/concurrent_quota.sh` there. The SQL fixture currently has
   29 assertions, including missing-expiry downgrade, and the shell fixture
   refuses non-loopback database hosts. Both fixtures passed in the minimal
   local PostgreSQL 17.6 harness documented below. They still need to run in a
   disposable full Supabase staging environment because the local harness does
   not implement the complete Auth, PostgREST, Storage, or Realtime services.
3. Deploy all five handler revisions and the migration to a staging project
   together. A handler without the RPC fails closed (AI unavailable), which
   preserves cost safety but interrupts AI.
4. Verify anonymous denial, A/B isolation, forged tier/counter rejection,
   active/expired/grace/downgrade behavior, monthly/day/minute reset boundaries,
   replay across endpoints, and simultaneous reservations. Inspect only
   aggregate usage/error/latency/token metrics; do not log prompts or photos.
5. Review measured per-feature token use and provider invoices before changing
   provisional defaults or promising limits.
6. Only after explicit approval, schedule production migration and function
   rollout as one coordinated change. Production is currently read-only.

`supabase/review/ai-quota-rollback.sql` is a fail-closed rollback template. It
revokes execute on the new RPCs but deliberately does not drop counters,
reservations, or re-enable the old quota RPC. That means AI stays unavailable
until code/schema are reconciled. Do not roll back by restoring a client-callable
legacy quota function or weakening RLS. Preserve records for forensic review.

## Recovered project metadata reconciliation (read-only)

The recovered project was verified as `qxsdwwdrxoyxmnapuqqv`; hosted
inspection used the Supabase CLI's `db query --remote=... --read-only` route
and metadata-only catalog queries. No customer records, object contents, or
secret values were queried. The recovered profile schema already contains
`subscription_expires_at` but does not contain `subscription_status`; the
reconstruction migration adds the latter. The original local fresh chain had
no migration creating `subscription_expires_at`, even though the later
reconstruction functions read it. The additive prerequisite
`20261110090000_add_subscription_expiry_prerequisite.sql` now ensures this
column exists before those functions are defined; it is a no-op on the
recovered schema.

No `ai_usage_buckets`, `ai_action_reservations`, `ai_quota_policies`, or new
quota RPCs were present in recovered metadata. The recovered profile table
has RLS enabled but is not forced. Its own-row `ALL` policy is permissive and
ORs with a same-tier update policy, so the latter does not block updates.
Metadata showed `anon` SELECT privilege and authenticated UPDATE privilege,
including `tier`, `subscription_expires_at`, and
`monthly_suggestions_used`. The recovered `upgrade_user_to_premium(uuid)` is
SECURITY DEFINER, has no pinned `search_path`, and is executable by anon and
authenticated; its `auth.uid()` self-check does not prevent users from
upgrading themselves. `can_request_suggestion(user_uuid uuid)` also accepts a
caller-selected UUID and is executable by anon/authenticated. The local
security migration removes/revokes those paths and restricts profile columns;
none of those changes have been applied remotely.

The remote migration-list command showed no applied versions for the six
then-local migrations, and direct metadata lookup did not expose
`supabase_migrations.schema_migrations`. This is a baseline/history
reconciliation blocker, not permission to repair hosted history. No history
repair or production write was attempted. Recovered constraints, indexes,
RLS, and grants must continue to be compared before any reviewed rollout.

## Local database validation (2026-11-12)

PostgreSQL 17.6 was built from official source into ignored
`.tooling/local-postgres/`, initialized as a disposable cluster, and bound only
to `127.0.0.1:55432` (Unix socket under `/tmp/everywear-pg-sock`). pgTAP 1.3.3
was installed into that local toolchain. No system packages/root, shared
PostgreSQL service, Docker, or production project were changed.

The clean disposable `everywear_security` database applied the complete local
migration chain with only the Supabase platform prerequisites represented:
roles `anon`/`authenticated`/`service_role`, a minimal `auth.users` table,
`auth.uid()` backed by the test JWT claim setting, Supabase-like default table
grants, and a `supabase_realtime` publication. This is a **minimal test
harness**, not a complete Supabase Auth, PostgREST, Storage, or Realtime
installation. PostgreSQL warned that `wal_level` is insufficient for logical
replication; publication membership SQL applied, but actual Realtime delivery
was not tested.

Results:

- All 29 pgTAP assertions passed, including two-user RLS isolation, protected
  tier writes, cross-account outfit/item link rejection, grants, request replay
  across endpoints, server-derived entitlement, expiry/downgrade/missing-expiry
  behavior, UTC resets, and limits.
- The corrected concurrent reservation fixture passed: two simultaneous free
  requests yielded one success and one denial; four simultaneous premium
  requests yielded three successes and one concurrency denial.
- The privacy-safe rollback SQL was exercised inside a transaction: it revoked
  quota RPC access, and transaction rollback restored the pre-test grants.
- Initial execution exposed and fixed an ambiguous `burst_limit` reference in
  `get_ai_allowance()`, corrected pgTAP exception-message arguments, fixed the
  concurrency script to parse psql's boolean output, and added the missing
  local expiry-column prerequisite.

These results verify migration/RPC behavior in this representative local
PostgreSQL harness only. They do not prove compatibility with every recovered
production object, that production privileges match the local baseline, or
that hosted quotas are enforced. Do not deploy until the recovered schema,
migration history, Supabase platform behavior, and staging rollout are
reviewed.
