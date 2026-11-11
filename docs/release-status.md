# Android release status

Last updated: 2026-11-12

## Current classification

Recovery is in progress on `recovery/android-v1`. Flutter tests and partial Deno
checks passed locally. A fresh analyzer run found no errors but returned a
warning exit; its reported warnings were then corrected. Android packaging,
clean-database validation, private-image runtime behavior, provider setup, and
Play eligibility are not verified. This is not yet a Play release candidate.

## Local checkpoints

- `395255ba2937c31fd2d486e0ec823c3b0273f125` — recovered-schema-aligned
  security proposal, local-only pgTAP fixture, private image cutover review,
  and protected Edge Function cleanup.
- `5ba8204203c24e98e50e57188ed5d13d614e89db` — expiry-aware entitlement
  decisions, client/offline and notification fixes, release-only shim, removal
  of obsolete placeholder screens/services, and focused tests.
- Documentation/CI checkpoint is being committed separately.

## 1. Completed local code changes

- Flutter 3.35.7/Dart 3.9.2 are pinned; dependencies resolve; `pubspec.lock` is
  tracked; Android identity remains `com.stylewise.app`; release signing no
  longer uses debug credentials.
- Removed the unused Stripe `PaymentService`, its unreferenced UI imports/helpers,
  and the uncalled local Stripe Edge Function source. The recovered production
  Stripe Edge Function remains a separate retirement/deployment item.
- Supabase client failures are surfaced as retryable/unavailable states instead
  of silently becoming empty data. Onboarding reports success only after the
  authenticated profile write succeeds. Signed-out AI suggestions render a
  retry state.
- System text scaling is preserved. Sentry event and transaction reporting
  respect the opt-out. Android/iOS now supply IANA timezone identifiers;
  reminder scheduling stays disabled if a valid device timezone is unavailable
  and no longer opens Settings unexpectedly.
- Private image client flow stores stable owner-scoped Storage references in
  existing database columns, resolves authorized URLs at display time, refreshes
  a failed signed URL, preserves external/provider URLs and provides unavailable
  placeholders. Avatar replacement/removal, account isolation, wardrobe
  consumers and PDF embedding are covered by focused tests. CSV omits image
  URLs; unavailable images do not fail an export.
- RevenueCat UI stays unavailable without the Android SDK key and exact
  entitlement. Purchase/restore are single-flight, bind to the authenticated
  Supabase UUID, reject account changes, require store entitlement and backend
  verification, and only report success after verification. Entitlement display
  and client limits also require active server status and an unexpired period;
  delayed expiry events no longer leave stale premium flags trusted. Webhook
  state uses wrapped `event` data and a server-only ordered/idempotent RPC.
- Local AI Edge Functions validate Supabase identity before protected work and
  consume AI quotas atomically. The suggestion preflight is read-only so it
  cannot spend a second quota. Removed `@ts-nocheck` from the protected local
  functions; backend errors return generic client messages.
- `20261111090000_reconstruct_and_secure_backend.sql` was revised against
  recovered metadata: protected profile fields/counters, bilateral outfit/item
  ownership, atomic quotas, pinned/restricted helper functions, preserved
  subscription history, missing app tables/catalog content and Realtime
  membership. It is an unexecuted proposal, not an approved deployment.
- `supabase/review/private-image-cutover.sql` is review-only and preserves
  private rollback. No hosted storage configuration or record was changed.
- Added `supabase/tests/database_security.test.sql`, a local-only pgTAP fixture
  for profile separation/protected tier, bilateral outfit-item ownership and
  quota behavior. It is not run and covers neither concurrent sessions nor
  Storage objects yet.
- Added pinned tool/setup guidance and CI for Flutter tests/analyzer and Deno
  checks. CI has not run.

## 2. Checks actually performed

| Check | Actual result |
|---|---|
| Checkout/resources | `recovery/android-v1`; no `AGENTS.md`; 14 GiB RAM, 8.4 GiB available, 398 GiB free at start; Linux/macOS generated changes preserved |
| Toolchain | project Flutter 3.35.7 / Dart 3.9.2; Java 21; Node 22.23; installed ignored project-local Deno 2.9.6; Supabase CLI 3.1.0 |
| Dependency resolution | `flutter pub get` completed; lockfile updated for the direct image test dependency |
| Full Flutter tests | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` — **36 passed**, no failures |
| Flutter analyzer | `.tooling/flutter/bin/flutter analyze --no-pub` — 0 errors, 9 warnings, 281 info; exit 1. All 9 reported warning sites were cleaned up afterward; no analyzer rerun was made |
| Deno formatting | `deno fmt` passed on `check-and-request-suggestion`, `revenuecat-webhook`, and `verify-purchase` |
| Deno type checks | Passed: `check-and-request-suggestion`, `delete-account`, `today-suggestion`, `style-coach`, `analyze-clothing`, `revenuecat-webhook`, `verify-purchase`. `generate-ai-insights` exposed nullable query results; changed to explicit empty-list fallback, but was not rechecked. `ai-suggestions` was not reached. Two check attempts were used; further type-checking is deferred |
| Read-only recovered schema | Production identity reverified. Read-only metadata query confirmed `revenue_cat_id text`, `suggestions_reset_at date`, nullable integer counters and nullable timestamptz expiry. No customer rows, Storage contents or secrets queried |
| Hosted operations | Read-only only. No migrations/history repair, settings, buckets/policies, records, functions or provider configuration changed |
| SQL parser | Project-local `pglast` parsed the outer PostgreSQL statements in the migration, review cutover and pgTAP fixture. This does not validate PL/pgSQL function bodies, schema compatibility or runtime behavior |
| SQL/database | No local Supabase, Docker or clean database chain was available/run; pgTAP fixture is prepared but unexecuted |
| Android AAB | Two release attempts failed at `compileReleaseJavaWithJavac`: Flutter 3.35.7's generated main registrant contains `IntegrationTestPlugin`, but Gradle excludes this dev-only plugin in release. A release-only no-op shim was added after those attempts and successfully compiled with Java 21 against the installed Flutter embedding jar and Android 36 API. No package build was started after the shim because the two-attempt build limit was reached. No AAB was produced by the attempts. |
| Device | No emulator/device used |
| Formatting/diff | Targeted Dart formatting, `deno fmt --check` on three changed functions, `git diff --check` and `git diff --cached --check` passed |

## 3. Deferred or incomplete verification

- Flutter tests passed after final Dart cleanup and expiry tests: 36/36. Analyzer result is not
  green; do not treat formatting as analysis. The nine reported warnings were
  removed but not rechecked.
- Deno check has two failed attempts: first found `today-suggestion` unknown
  catch typing (fixed with generic client error), second found nullable data in
  `generate-ai-insights` (fixed with `?? []`). Do not claim those final fixes
  verified. `ai-suggestions` type check and full CI remain pending.
- Run the new pgTAP fixture and migration chain against a clean non-production
  schema; extend it with anonymous/user-A/user-B Storage and concurrent quota
  proofs.
- Retry Android release AAB after the release-only plugin shim is reviewed.
  It remains unsigned without the private upload key. Device/network behavior,
  timezone/permission behavior, accessibility and export runtime checks remain
  pending.
- No purchase, restore, RevenueCat webhook, production deployment, Play tester
  transaction, database migration or private bucket cutover was executed.

## 4. Provider setup, risks and blockers

- Recovered production project: `qxsdwwdrxoyxmnapuqqv`, confirmed as Everywear,
  production, West EU (Ireland). Existing schema/data/Storage are preserved.
  Confirmed live risks and exact policy/function inventory are in
  `recovered-supabase-reconciliation.md`.
- The local migration is still unvalidated and unapplied. Remote migration
  history was absent. Do not run `db push`, repair history, or deploy it. First
  validate on a clean non-production schema and prepare an explicit existing
  project delta that preserves existing accounts, audit rows and objects.
- The app's premium resolver now requires `subscription_status`; if that
  reviewed schema delta is not present, the app fails closed to Essential tier
  while profile/onboarding access still works. The approved additive schema
  change must precede Edge Function and app rollout.
- Both hosted image buckets remain public with public read policies. Client
  code does not make existing images private. Inventory/convert exact legacy
  object URLs in existing `image_url`/`avatar_url` fields, review the cutover
  SQL, validate private behavior, then execute the separately approved
  production rollout. Rollback must keep buckets private and owner policies in
  place.
- `generate-ai-insights` and `ai-suggestions` final Deno checks are outstanding;
  Deno check stopped after the second attempt as required by resource limits.
- App build needs the recovered Supabase URL and public anon key. Keep service
  role, Gemini/OpenRouter, RevenueCat secret and webhook secrets server-side.
- RevenueCat remains incomplete: supply public Android SDK key and exact paid
  entitlement, confirm package id, configure products/offerings, Play service
  credentials and webhook. Then perform real Play internal tester purchase,
  cancellation, restore, expiry/grace, duplicate/out-of-order and account-switch
  verification. No successful purchase is claimed.
- No private upload keystore or `android/key.properties` was found. A signed AAB
  cannot be produced without valid private upload-signing inputs.
- Store privacy/deletion URLs, listing artwork/screenshots, required Play
  declarations and eligibility are still owner-provided release inputs.
- The recovered `create-subscription-payment` Stripe Edge Function is still
  deployed, while the local app uses RevenueCat and has no call site for it.
  Its local source was removed. Retiring the remote function requires a
  separately reviewed deployment.

## 5. Resumable checklist and exact next step

- [x] Preserve checkout, prior commits, Linux/macOS generated files, and the
  ignored deployed-source snapshots.
- [x] Reconcile recovered schema metadata and deployed function source using
  read-only access; preserve exact production identity.
- [x] Revise local schema proposal and prepare privacy-preserving Storage
  cutover SQL without hosted changes.
- [x] Implement client auth/offline, timezone, reporting, image and billing
  race changes; prepare regression coverage.
- [x] Run sequential Flutter suite after expiry-aware tier changes: 36 passed.
- [x] Prepare local pgTAP fixture for protected tier, profile/outfit ownership
  and single-session AI quota behavior.
- [ ] Finish Deno verification after the two-attempt deferral; resolve any
  remaining type errors without `@ts-nocheck`.
- [x] Targeted Dart/Deno formatting and final staged/unstaged `git diff --check` passed; sequential Flutter tests passed 36/36 after final Dart changes.
- [ ] Retry a conservative Android AAB build after release-only integration
  plugin shim review; it will be unsigned without private signing inputs.
- [ ] Validate migration on non-production schema and prepare isolated security
  fixtures; production stays read-only.
- [x] Update CI/setup/status. Source commits are recorded above; documentation
  and CI changes are committed separately.

**Exact next step:** on the next authorized validation pass, run Deno checks for
`generate-ai-insights` and `ai-suggestions`, then make one conservative Android
bundle attempt with the release-only shim. Do not report a bundle or signing
until it exists and is inspected.
