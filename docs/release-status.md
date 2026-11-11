# Android release status

Last updated: 2026-11-12

## Current classification

Recovery is in progress on `recovery/android-v1`. Flutter tests and partial Deno
checks passed locally. A fresh analyzer run found no errors but returned a
warning exit; its reported warnings were then corrected. One unsigned AAB now
packages successfully, but it is not installable/uploadable as a signed Play
release and has not been run on a device. Clean-database validation,
private-image runtime behavior, provider setup, and Play eligibility remain
unverified. This is not yet a Play release candidate.

## Local checkpoints

- `395255ba2937c31fd2d486e0ec823c3b0273f125` — recovered-schema-aligned
  security proposal, local-only pgTAP fixture, private image cutover review,
  and protected Edge Function cleanup.
- `5ba8204203c24e98e50e57188ed5d13d614e89db` — expiry-aware entitlement
  decisions, client/offline and notification fixes, release-only shim, removal
  of obsolete placeholder screens/services, and focused tests.
- `fe0a5c5fc0b3463a8014a869f74927b6aaf71bef` — setup/release documentation,
  reconciliation updates, resumable goal status, and sequential Flutter/Deno CI.
- `ae02ee0359ef46f8e344fdd27579ee14f345e415` — recorded the recovery checkpoint
  IDs in the release status.
- `ed2f491f071ee823f5e87823b1893a91614dbf7c` — subscription expiry parsing
  now fails closed for malformed server values, with focused unit cases.
- `1f9261f7035488e388b2f29b814c70591fbd1d5e` — removes replaced/deleted
  owner-scoped wardrobe image objects and cleans new uploads after failed saves.
- `5f2bef06cddcf7f4f7948a4d152a28faa5bf17b2` — removes unreachable ad
  placeholder startup/layout/action code and the blank home banner.
- `5b12e53897c9a8180e269e6f1952404b0f053cd2` — serializes RevenueCat identity
  changes with purchase/restore verification, centralizes session cleanup, and
  paginates/checks account-deletion outfit links.
- `1b7dcc3dfc4dd22d4f2b6f98fbe04d0fc8a0f8d3` — keys private image cache by
  stable owner-scoped references and clears it during account cleanup.
- `d70bb6d6984c436239043757c4ef66b0df155054` — recognizes authenticated
  Supabase Storage URLs and evicts private image bytes from both cache layers.
- `c8cff417c982015871e0f70fb9d35753c255f081` — adds disposable-local Storage
  isolation coverage for anonymous access, private bucket state, both account
  owners, uploads, and deletion; records fresh read-only production metadata.
- `281efa2a5c49f1a7dcc9d5e646e42bebefe0eb66` — pages in-app full-reset outfit
  links, bounds delete batches, clears private image cache before partial remote
  cleanup, and adds three passing pure helper tests.
- This work pass also built and inspected an unsigned AAB after the release shim
  and cheaper Flutter checks passed; the artifact is ignored under `build/`.

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
  and no longer opens Settings unexpectedly. Next 08:00 occurrences are
  calculated by local calendar date so daylight-saving transitions do not shift
  the reminder hour.
- Removed the unused AdMob placeholder path: there was no ad SDK, production
  unit IDs were fake literals, and the home screen reserved blank banner space.
  No ads are claimed/configured for this release.
- Private image client flow stores stable owner-scoped Storage references in
  existing database columns, resolves authorized URLs at display time, refreshes
  a failed signed URL, preserves external/provider URLs and provides unavailable
  placeholders. Avatar replacement/removal, account isolation, wardrobe
  consumers and PDF embedding are covered by focused tests. Wardrobe replacement
  and deletion remove prior owned Storage objects after the row change; failed
  initial saves clean up newly uploaded objects. Cleanup is best effort because
  Postgres row changes and Storage deletion are separate operations. CSV omits
  image URLs; unavailable images do not fail an export. Private image cache keys
  use stable owner paths, are indexed without signed URLs, and are evicted on
  account cleanup and object deletion.
- RevenueCat UI stays unavailable without the Android SDK key and exact
  entitlement. Purchase/restore are single-flight, bind to the authenticated
  Supabase UUID, reject account changes, require store entitlement and backend
  verification, and only report success after verification. Entitlement display
  and client limits also require active server status and an unexpired period;
  delayed expiry events no longer leave stale premium flags trusted. Webhook
  state uses wrapped `event` data and a server-only ordered/idempotent RPC.
  RevenueCat identity changes are serialized against the full purchase/restore
  and verification flow; app logout now signs Supabase out before RevenueCat
  logout so it cannot re-bind the account being exited.
- Local AI Edge Functions validate Supabase identity before protected work and
  consume AI quotas atomically. The suggestion preflight is read-only so it
  cannot spend a second quota. Removed `@ts-nocheck` from the protected local
  functions; backend errors return generic client messages.
- Account deletion checks outfit-log query errors and pages all outfit IDs in
  bounded batches before deleting their junction rows; the previous single-page
  query could miss links on large accounts.
- The in-app full reset now uses stable outfit-log pagination and bounded
  junction-delete batches as well. It evicts owner-scoped private image caches
  before remote reset steps can partially succeed. Added focused unit tests for
  multi-page cleanup, bounded batches, and listing failure propagation; these
  tests passed locally without a Supabase connection.
- `20261111090000_reconstruct_and_secure_backend.sql` was revised against
  recovered metadata: protected profile fields/counters, bilateral outfit/item
  ownership, atomic quotas, pinned/restricted helper functions, preserved
  subscription history, missing app tables/catalog content and Realtime
  membership. It is an unexecuted proposal, not an approved deployment.
- `supabase/review/private-image-cutover.sql` is review-only and preserves
  private rollback. No hosted storage configuration or record was changed.
- Added `supabase/tests/database_security.test.sql`, a local-only pgTAP fixture
  for profile separation/protected tier, bilateral outfit-item ownership and
  quota behavior. Added `supabase/tests/storage_security.test.sql`, a separate
  disposable-local pgTAP fixture for private bucket visibility and anonymous,
  user A, and user B read/upload/delete isolation after applying the review-only
  private-image cutover. Neither SQL fixture has been executed. Concurrent
  quota behavior still needs a two-session local database proof.
- Added pinned tool/setup guidance and CI for Flutter tests/analyzer and Deno
  checks. CI has not run.

## 2. Checks actually performed

| Check | Actual result |
|---|---|
| Checkout/resources | `recovery/android-v1`; no `AGENTS.md`; 14 GiB RAM, 8.4 GiB available, 398 GiB free at start; Linux/macOS generated changes preserved |
| Toolchain | project Flutter 3.35.7 / Dart 3.9.2; Java 21; Node 22.23; installed ignored project-local Deno 2.9.6; Supabase CLI 3.1.0 |
| Dependency resolution | `flutter pub get` completed; lockfile updated for the direct image test dependency |
| Full Flutter tests | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` — **42 passed**, no failures after the final ad, billing/session, and image-cache/parser changes. |
| Flutter analyzer | `.tooling/flutter/bin/flutter analyze --no-pub` — 0 errors, 9 warnings, 281 info; exit 1. All 9 reported warning sites were cleaned up afterward; no analyzer rerun was made |
| Deno formatting | `deno fmt --check` passed on the updated `delete-account` source; earlier formatting passed on `check-and-request-suggestion`, `revenuecat-webhook`, and `verify-purchase` |
| Deno type checks | Earlier checks passed `check-and-request-suggestion`, `delete-account`, `today-suggestion`, `style-coach`, `analyze-clothing`, `revenuecat-webhook`, and `verify-purchase`. The deletion function was later changed to check and paginate outfit-link cleanup and has not been rechecked. `generate-ai-insights` exposed nullable query results and was patched with `?? []`; it was not rechecked. `ai-suggestions` was not reached. Two check attempts were used; further type-checking is deferred |
| Read-only recovered schema | Production identity reverified. Read-only metadata query confirmed `revenue_cat_id text`, `suggestions_reset_at date`, nullable integer counters and nullable timestamptz expiry. Follow-up Storage metadata query confirmed `storage.objects.owner uuid`, `owner_id text`, nullable `bucket_id`/`name`, `metadata jsonb`, and `id` defaulting to `gen_random_uuid()`. The two image buckets remain public with no MIME/size restrictions; `anon` and `authenticated` have table CRUD grants on `storage.objects`, so row isolation depends on RLS and public bucket visibility currently permits public reads. Read-only policy catalog confirms two public SELECT policies (one `PUBLIC`, one `anon`) plus authenticated owner policies; no customer rows, Storage contents or secrets queried |
| Hosted operations | Read-only only. No migrations/history repair, settings, buckets/policies, records, functions or provider configuration changed |
| SQL parser | Project-local `pglast` parsed the outer PostgreSQL statements in the migration, review cutover and pgTAP fixture. This does not validate PL/pgSQL function bodies, schema compatibility or runtime behavior |
| SQL/database | No local Supabase, Docker or clean database chain was available/run; pgTAP fixture is prepared but unexecuted |
| Reset cleanup source | Targeted Dart formatting and `git diff --check` passed. `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/paginated_outfit_link_cleanup_test.dart` — **3 passed**; the test uses a pure callback helper and did not connect to Supabase |
| Notification scheduler | First test attempt failed because the IANA location was resolved before timezone initialization; setup was corrected. The rerun of `local_notification_schedule_test.dart` passed **4/4**, covering spring-forward, before-08:00, exact-08:00 and invalid-hour cases. `app_import_smoke_test.dart` passed **1/1** after the notification/reset changes |
| Android AAB | Two initial attempts failed at `compileReleaseJavaWithJavac` because Flutter 3.35.7's generated main registrant contains dev-only `IntegrationTestPlugin`, excluded from release dependencies. After adding the release-only no-op shim and completing independent code work/tests, one release build succeeded in 237.6 seconds with one Gradle worker and a 2 GiB heap. It produced `build/app/outputs/bundle/release/app-release.aab` (76,514,565 bytes). `unzip -tq` passed; `jarsigner -verify` reported `jar is unsigned`. SHA-256: `c257964750ac8cea02b579b1b944a47a76b6ccd4977e1170c290659b0f911feb`. No provider values or signing inputs were supplied; no install/device/runtime verification was done. |
| Device | No emulator/device used |
| Formatting/diff | Targeted Dart formatting, `deno fmt --check` on three changed functions, `git diff --check` and `git diff --cached --check` passed |

Latest verification: the full serial Flutter suite passed 42/42 after current
Dart changes; the targeted image routing/private consumer/app-import selection
passed 12/12. Targeted Dart formatting and `git diff --check` passed. The app
import smoke test compiles the app entry point and transitive screens. The
release bundle built and passed archive integrity inspection, but is unsigned
and has no provider configuration. The paginated reset helper test passed 3/3,
the local-time notification test passed 4/4 after correcting test setup, and
the app import smoke test passed 1/1. None connected to a backend. A
project-local `pglast` parse accepted all 30 outer SQL statements in the new
Storage fixture; this is syntax parsing only
and does not execute policies or prove isolation. Read-only metadata queries
confirmed public buckets and broad Storage table grants. No analyzer rerun or
device check was made.

## 3. Deferred or incomplete verification

- The full Flutter suite passed 42/42 after the final local Dart changes.
  Analyzer result is not green; do not treat formatting as analysis. The nine
  reported warnings were removed but not rechecked.
- Deno check has two failed attempts: first found `today-suggestion` unknown
  catch typing (fixed with generic client error), second found nullable data in
  `generate-ai-insights` (fixed with `?? []`). Do not claim those final fixes
  verified. `ai-suggestions` type check and full CI remain pending.
- Run the new pgTAP fixture and migration chain against a clean non-production
  schema, then run `storage_security.test.sql` after the reviewed cutover. Add a
  two-session concurrent quota proof; the current quota fixture only proves
  sequential calls in one session.
- The locally built AAB has been rechecked: SHA-256 and archive integrity still
  match the recorded artifact, and it remains unsigned without the private
  upload key. Device/network behavior,
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
- `delete-account` changed after its earlier passing Deno check to paginate and
  verify outfit-link deletion. `generate-ai-insights` and `ai-suggestions` final
  Deno checks are also outstanding; Deno check stopped after the second attempt
  as required by resource limits.
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
- [x] Run the full Flutter suite sequentially: 42 passed after the final Dart changes; the affected image/app-import selection separately passed 12/12.
- [x] Prepare local pgTAP fixture for protected tier, profile/outfit ownership
  and single-session AI quota behavior.
- [x] Add a separate local-only Storage pgTAP fixture for anonymous denial,
  private bucket state, and user A/user B read/upload/delete owner isolation;
  the fixture assumes private cutover policies are installed only in the
  disposable test database and remains unexecuted.
- [ ] Finish Deno verification after the two-attempt deferral; resolve any
  remaining type errors without `@ts-nocheck`.
- [x] Targeted Dart/Deno formatting and `git diff --check` passed. Full suite: 42/42; final focused image/app import tests: 12/12.
- [x] Build the release AAB after the shim and cheaper checks passed; archive
  integrity passed. It is unsigned and has no Supabase/RevenueCat build values.
- [ ] Validate migration on non-production schema and prepare isolated security
  fixtures; production stays read-only.
- [x] Update CI/setup/status. Source commits are recorded above; documentation
  and CI changes are committed separately.
- [x] Clean up replaced/deleted owner-scoped wardrobe images, avoid deleting
  external/avatar/other-account objects, and remove a newly uploaded file when
  the initial wardrobe save fails.
- [x] Remove unconfigured ad placeholder startup and banner reservation. No SDK
  or provider credentials were available, so this release does not show ads.
- [x] Serialize RevenueCat customer operations, centralize sign-out cleanup,
  paginate account deletion, and protect private image cache state.
- [x] Verify the paginated in-app reset cleanup helper: 3 focused tests passed;
  the Supabase-backed reset flow remains unverified without a disposable DB.

**Exact next step:** start an explicitly disposable local Supabase database
when the no-Docker restriction is lifted and run the migration chain, then run
the Storage fixture after the review cutover plus a two-session concurrent
quota proof. Before any signed or interactive
Android release validation, supply public app configuration and private upload
signing inputs through the private build environment, complete RevenueCat/Play
dashboard setup, and run the AAB on a physical device/internal tester track.
Final Deno type checks remain deferred after the two-attempt limit.
