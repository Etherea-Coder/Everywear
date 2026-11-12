# Android release status

Last updated: 2026-11-12

## Current classification

Recovery is in progress on `recovery/android-v1`. Focused Flutter tests and
partial earlier Deno checks passed locally. The latest project-wide Flutter
analyzer run exited 1 with 249 informational diagnostics and no warnings or
errors; the revised local CI gate succeeds while retaining fatal warnings and
errors. The unsigned AAB predates `e2085cb`, so it is not a bundle of current
HEAD or uploadable as a signed Play release; it has not been run on a device.
Clean-database validation,
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
- `2d7d9f3f928311bcdbe2b0e1d93db1bb63e6d9a0` — schedules the next reminder by
  IANA-zone calendar date across DST and adds four passing time-boundary tests.
- `84d2923504c82d616f82329167ffc8120d9a9bd6` — records the unavailable
  `adb`/physical-device verification prerequisite.
- `192a8f2275a043ef11b7b78e8197b3d5e6c9015a` — records 49 passing current
  Flutter tests, clean targeted analysis, and the rebuilt final-source unsigned
  AAB with archive/hash verification.
- `9f1a54a9d669a5c8114ebf99f4dc547c980b434f` — records the prior verification
  checkpoint and preserves the full resumable goal checklist.
- `9c4ade3e88f1d19d5e0c6009b2874052f16be52f` — reconciles the recovery plan
  with current test, analyzer, database, and AAB evidence.
- `6ca57003c881ddc15aa3c2a9ad19dc8ce2e1d1c0` — replaces the local-path and
  caller-URL outfit AI flow with bounded compressed image bytes, authenticated
  validation, and focused Dart/Deno tests; errors returned to clients are
  generic.
- `7abb46d841e0210cc11cc319b75736c76ae88cf3` — records the coordinated AI
  image-flow checkpoint and deferred production rollout.
- `1a088cf12a5c120037cafd97a57c5aa08381ec75` — records the latest project-wide
  analyzer result and its unresolved diagnostics.
- `b9f4ddc3ca64ce0977b28746d4ac75d929080cc3` — localizes the password-recovery
  action and adds a three-locale regression test.
- `42512f64b50813c17d473cf775d0a1e45024c379` — fixes challenge history's
  nested relation mapping, preserves backend failures for a retry state, and
  adds focused merge/localization tests.
- `317e22e10e40a441b8768d0a98ec9a2630007704` — surfaces learning outages,
  replaces the “coming soon” action with explicit saved completion of the
  existing module summary, and adds failure/success widget coverage.
- `e2085cb` — promotes the PDF image decoder to a direct runtime dependency,
  updates the RevenueCat purchase call to the current SDK API, and records
  focused image/billing tests plus clean targeted analysis.
- `ec4e018` — records resumed focused test, analysis and Deno availability
  results.
- `36a0f22` — configures CI to keep warnings fatal while treating the current
  info-level analyzer backlog as advisory; the exact gate passed locally.
- `43db178f01d51fbddfd89d3c7855c68ad0f37823` — clarifies that the inspected
  unsigned AAB predates current HEAD and defers its rebuild under full swap.
- `d8fc87b3d1baa5309531168aaaace28e23e390ad` — prepares a loopback-only,
  two-session regression for concurrent suggestion and coach quotas.
- `0a95323d748d6cc1a93499e09fa21949b6fcd117` — removes explicit `any` from
  insights aggregation, bounds untrusted Gemini output, adds pure tests, and
  verifies targeted Deno lint plus no-remote tests.
- `5d8433cf77b03b5d352778c8dd0247bc657f30b9` — makes purchase entitlement
  selection exact and date evaluation fail closed; four no-remote regression
  cases cover lifetime, active, grace, expired and malformed values.
- `099cec7932dedad970b08fd975ab026ee0cb7d7e` — requires the configured
  RevenueCat entitlement to be an own property and guards prototype-name edge
  cases in the same focused test.
- `483742c738165636367fcb9f3cee8d9aba1d37ec` — sends Gemini API keys in the
  `x-goog-api-key` header for all four model-backed functions instead of URL
  query parameters; adds a no-network request-construction regression test.
- `621457a0015639682fe0959f42dac9a56bb36613` — runs the pure Deno Edge
  Function regression tests with `--no-remote` in CI; this workflow change has
  not yet run in CI.
- `8100a292df13ff070163fb9915b534db10cffba1` — removes explicit `any` and
  inline JSR imports from the Gemini handlers identified by targeted lint,
  using typed prompt data and the configured Supabase import alias.
- `487ed3e5537366a6c0098f7456ab01aacc6d7922` — switches the final two Edge
  Functions to the configured Supabase import alias; the full Edge Function
  lint check now passes.
- `3d725306c96eff2a521965d965e83f0b19090572` — orders isolated Deno tests
  before protected-function type-checking so a type-check failure does not
  suppress their independent CI result.
- `03aef89503c9b7dfd1a6cc81381c0c6e4122ccc3` — validates and bounds style
  coach model output by mode, prevents model fields from overriding response
  status, returns a gateway error for unusable responses, and adds pure tests.
- `2714408822692e0ee8ba921c7b08e634dffcc9d3` — loads the daily suggestion's
  canonical wardrobe through the authenticated user's RLS-protected query,
  validates generated item IDs/slots, returns database image references, and
  adds offline response-validation tests.
- `a1a7e1e8fce9be613359afa6b99549c7d5b696d7` — validates clothing-image
  request bodies and bounds allowed Gemini analysis fields; adds no-network
  regression tests and includes them in CI.
- `a37a4fad31c06aea5a107988ef1d810f1d1c664b` — validates coach mode/body
  and checks Gemini configuration before quota consumption; daily suggestions
  also reject malformed request bodies and check configuration before querying
  wardrobe or consuming quota.
- `aa756517c50d5f1dff100c053179bd19a1416f24` — adds full Edge Function lint
  as a CI gate before protected-function type-checking; the workflow has not run.
- `28a3bfd3f288010d167bd259e6408ccebaaf6a80` — rejects `anchor` as a slot on
  supporting daily-suggestion items; only the separate anchor field can use it.
- `4a205cf3a5d496da7302914f2d416d466a53054b` — removes the unreachable
  `/outfit-rating` demo route, fake outfit image/date, and widgets used only by
  that screen; daily-log and outfit-history rating flows remain available.
- `505c5730dcbd4ea6dba65938e0eeb4b9fbfcbf64` — records the rating-demo
  removal and its focused route/import checks in this status document.
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
- The splash-screen password recovery action now uses the existing translated
  string in English, French, and Spanish rather than hard-coded English.
- System text scaling is preserved. Sentry event and transaction reporting
  respect the opt-out. Android/iOS now supply IANA timezone identifiers;
  reminder scheduling stays disabled if a valid device timezone is unavailable
  and no longer opens Settings unexpectedly. Next 08:00 occurrences are
  calculated by local calendar date so daylight-saving transitions do not shift
  the reminder hour.
- Removed the unused AdMob placeholder path: there was no ad SDK, production
  unit IDs were fake literals, and the home screen reserved blank banner space.
  No ads are claimed/configured for this release.
- Removed the unreferenced `/outfit-rating` demo screen, which displayed a
  fixed stock outfit and stale date. Source search found no callers of its route;
  the real inline rating flows in daily-log and outfit-history remain.
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
- The PDF image normalizer's `image` package is now a production dependency,
  matching its runtime import. Subscription purchases use RevenueCat's current
  `PurchaseParams.package` API rather than deprecated `purchasePackage`.
- `generate-ai-insights` uses explicit wardrobe/outfit row types and validates
  and bounds Gemini response fields before returning them. Malformed model
  output falls back safely without logging the response body. The affected
  functions use the project import-map alias and native `Deno.serve`.
- `style-coach` now accepts only bounded fields for passive, active, and event
  modes. It ignores model-supplied control fields, requires the active answer
  and event intro/outfit content, and returns HTTP 502 when output is malformed
  or incomplete. Existing client fields remain (`tip`, `answer`, `next_step`,
  and event outfit fields); unneeded raw model text is no longer returned.
  Invalid JSON/unsupported modes fail before quota use, and missing Gemini
  configuration no longer consumes the atomic coach quota.
- `today-suggestion` loads its canonical wardrobe through the authenticated
  user's RLS-protected `wardrobe_items` query, using recovered table columns.
  It merges only rating hints tied to those database IDs, omits image paths from
  the Gemini prompt, and returns canonical names/categories/image references.
  Unknown IDs and invalid slots are removed; output without a real wardrobe
  anchor fails closed. Unusable model output receives HTTP 502. This remote
  database path has not been integration-tested against a disposable project.
  Invalid JSON and missing provider configuration fail before quota consumption;
  the atomic suggestion quota is consumed only after an owned wardrobe exists.
- `analyze-clothing` rejects malformed/oversized base64 payloads before
  consuming the atomic suggestion quota, checks provider configuration first,
  validates and bounds Gemini output to the expected category/color/material/
  confidence/vibe fields, and fails with a generic 502 for unusable output.
  Error responses include CORS headers and logs omit provider response bodies.
- All four Gemini-backed functions now construct requests through a shared
  helper that keeps the server API key in `x-goog-api-key`, avoiding key
  exposure in request URLs and URL-oriented logs. A pure test verifies the
  request method, body, content type, empty query, and header placement without
  contacting Google. This local source change still needs a separately reviewed
  Edge Function deployment.
- `verify-purchase` now selects only the exact configured entitlement and
  rejects malformed date fields before producing a verified snapshot. Valid
  active, grace-period and no-expiry lifetime cases are covered by pure tests.
- Challenge history now reads the `style_challenges` relation actually selected
  by the service (instead of the nonexistent `challenges` key), safely skips
  dangling relationships and deduplicates the featured challenge. Read errors
  and missing authentication propagate to a localized retry state rather than
  being presented as an empty challenge catalog.
- Learning catalog/stat failures now remain errors with a localized retry
  state. Modules use existing descriptions and `key_learnings` as the learning
  summary; users can explicitly mark that summary complete, and the app reports
  success only after the progress write succeeds. Completion is self-attested;
  the recovered `learning_modules` schema has no lesson-content or quiz field,
  so this does not claim a structured course or assessment.
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
  functions; backend errors return generic client messages. Outfit suggestions
  now compress device-local images and send bounded base64 bytes. The function
  validates the authenticated request and no longer fetches caller-provided
  URLs, fixing the local-path failure and removing the URL-fetch SSRF path.
  The app and Edge Function contract must be deployed together; production
  still uses the old `imageUrl` contract and was not changed.
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
| Checkout/resources | `recovery/android-v1`; no `AGENTS.md`; 14 GiB RAM, 7.3 GiB available, 511/511 MiB swap used, memory PSI avg10/avg60/avg300 at 0.00; an idle 4 GiB Gradle daemon from this checkout remains; Linux/macOS generated changes preserved |
| Toolchain | project Flutter 3.35.7 / Dart 3.9.2; Java 21; Node 22.23; Supabase CLI 3.1.0; Deno 2.9.6 exists at `.tooling/deno/node_modules/.bin/deno` but is not on PATH |
| Dependency resolution | `flutter pub get` completed; the latest offline resolution records `image` as a direct runtime dependency |
| Full Flutter tests | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` — **59 passed**, including learning and challenge recovery coverage. |
| Flutter analyzer | Latest `.tooling/flutter/bin/flutter analyze --no-pub` completed in 6.4 seconds and exited 1 with **249 info, 0 warnings, 0 errors**. Project-wide analysis is not green. Targeted analysis of image/export/storage/billing source and focused tests exited 0 with **No issues found** |
| CI analyzer severity gate (2026-11-12) | `.tooling/flutter/bin/flutter analyze --no-pub --no-fatal-infos --fatal-warnings` exited 0; output still reports 249 informational lints, with no warnings/errors. CI workflow now uses this gate; the remote workflow itself has not run |
| Targeted Dart analysis | `.tooling/flutter/bin/dart analyze` on the changed reset, notification, helper, and focused test files — initially reported four infos in `notification_service.dart`; after cleanup, rerun exited 0 with **No issues found!** |
| Deno formatting | `.tooling/deno/node_modules/.bin/deno fmt --check supabase/functions/delete-account/index.ts` passed. A combined default-format check of `delete-account`, `generate-ai-insights` and `ai-suggestions` reports the latter two files not formatted; legacy single-quote/no-semicolon options also report formatting differences. No mass formatting churn was applied |
| Deno type checks | Earlier checks passed `check-and-request-suggestion`, `delete-account`, `today-suggestion`, `style-coach`, `analyze-clothing`, `revenuecat-webhook`, and `verify-purchase`. The deletion function was later changed to check and paginate outfit-link cleanup and has not been rechecked. `generate-ai-insights` exposed nullable query results and was patched with `?? []`; it was not rechecked. `ai-suggestions` was not reached. Two check attempts were used; further type-checking is deferred |
| AI request validation | Dart payload tests passed **3/3**; Deno validation tests passed **5/5** with `--no-remote`; `deno fmt --check` passed on the new pure validator and test. `ai-suggestions/index.ts` keeps the repository's existing style and remains un-typechecked after the earlier check deferral |
| Edge Function lint/tests (2026-11-12) | Initial targeted lint found 24 explicit `any` annotations and five inline dependency imports. After replacing those patterns, project-local Deno 2.9.6 lint passed on `delete-account`, `generate-ai-insights`, `ai-suggestions`, `verify-purchase` and pure helper tests. Combined no-remote request, insight and entitlement tests passed **13/13**. Pure helper formatting checks passed; `delete-account` formatting check passed |
| Read-only recovered schema | Production identity reverified. Read-only metadata query confirmed `revenue_cat_id text`, `suggestions_reset_at date`, nullable integer counters and nullable timestamptz expiry. Follow-up Storage metadata query confirmed `storage.objects.owner uuid`, `owner_id text`, nullable `bucket_id`/`name`, `metadata jsonb`, and `id` defaulting to `gen_random_uuid()`. The two image buckets remain public with no MIME/size restrictions; `anon` and `authenticated` have table CRUD grants on `storage.objects`, so row isolation depends on RLS and public bucket visibility currently permits public reads. Read-only policy catalog confirms two public SELECT policies (one `PUBLIC`, one `anon`) plus authenticated owner policies; no customer rows, Storage contents or secrets queried |
| Hosted operations | Read-only only. No migrations/history repair, settings, buckets/policies, records, functions or provider configuration changed |
| SQL parser | Project-local `pglast` parsed the outer PostgreSQL statements in the migration, review cutover and pgTAP fixture. This does not validate PL/pgSQL function bodies, schema compatibility or runtime behavior |
| SQL/database | No local Supabase, Docker or clean database chain was available/run; pgTAP fixture is prepared but unexecuted |
| Reset cleanup source | Targeted Dart formatting and `git diff --check` passed. `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/paginated_outfit_link_cleanup_test.dart` — **3 passed**; the test uses a pure callback helper and did not connect to Supabase |
| Challenge and localization | Pure challenge-history merge tests passed **3/3**; localization regression passed as part of the 59-test suite. Targeted Dart analysis of challenge service/screen/data and locale files reported no issues |
| Learning path | Widget tests passed **3/3** for load outage retry, failed progress persistence, and successful completion; targeted analysis of learning service/screen, badge, translations, and tests reported no issues |
| Notification scheduler | First test attempt failed because the IANA location was resolved before timezone initialization; setup was corrected. The rerun of `local_notification_schedule_test.dart` passed **4/4**, covering spring-forward, before-08:00, exact-08:00 and invalid-hour cases. `app_import_smoke_test.dart` passed **1/1** after the notification/reset changes |
| Android AAB | Two initial attempts failed at `compileReleaseJavaWithJavac` because Flutter 3.35.7's generated main registrant contains dev-only `IntegrationTestPlugin`, excluded from release dependencies. After adding the release-only no-op shim, the then-current source built successfully in 64.8 seconds with one Gradle worker and a 2 GiB heap. `build/app/outputs/bundle/release/app-release.aab` is 76,532,620 bytes; `unzip -tq` passed; `jarsigner -verify` reports `jar is unsigned`. SHA-256: `31c4b88da33b03d06d69935502816daa6f55589461231be20a4a8098fd5d14d5`. The artifact predates `e2085cb` and does not include its dependency/API changes. No provider values or signing inputs were supplied; no install/device/runtime verification was done. |
| Debug APK | A local debug APK build was attempted after the AAB. It was stopped after 4m19s when swap reached 511/511 MiB; the build-owned Kotlin daemon was terminated, and no APK was produced. No unrelated processes were stopped. Retry only after resource pressure clears. |
| Current-source AAB attempt (2026-11-12) | `.tooling/flutter/bin/flutter build appbundle --release --no-pub` ran with one Gradle worker and a 2 GiB heap. Memory PSI rose from zero to 0.18 average over 10 seconds and swap reached 511/511 MiB; the build-owned Flutter process and newly started 2 GiB Gradle daemon were stopped. No new AAB was produced. Existing artifact timestamp remains 2026-11-12 02:14:45 +0200, size 76,532,620 bytes, SHA-256 `31c4b88da33b03d06d69935502816daa6f55589461231be20a4a8098fd5d14d5`; it predates `e2085cb`. No unrelated process was stopped |
| Focused image tests (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/private_image_consumers_test.dart test/services/image_reference_routing_test.dart` — **11 passed**. This uses test doubles; it did not contact production |
| Focused billing tests (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/subscription_service_test.dart test/services/serial_operation_queue_test.dart` — **4 passed**. This validates local identity/verification acceptance and serialization helpers; it is not a store purchase test |
| Deno tests (2026-11-12) | `.tooling/deno/node_modules/.bin/deno test --no-remote supabase/functions/ai-suggestions/request_validation_test.ts supabase/functions/generate-ai-insights/ai_response_test.ts supabase/functions/verify-purchase/entitlement_test.ts` — **13 passed**, no remote imports or provider calls |
| Edge Function lint and tests (2026-11-12) | `.tooling/deno lint supabase/functions` passed across **17 files**. `.tooling/deno test --no-remote` over request validation, insight parsing, entitlement evaluation, and Gemini request construction passed **14/14** with no provider calls. `deno fmt --check` passed for the new Gemini helper/test and `git diff --check` passed. Protected-function type-check and CI workflow execution remain deferred; no provider call was made |
| Style coach response validation (2026-11-12) | After adding the pure mode-aware response parser and tests, full Deno lint passed across **19 files** and the no-remote pure test set passed **18/18**. Targeted `deno fmt --check` passed on the new parser/test; `git diff --check` passed. No provider/network call was made. Protected-function type-check and CI execution remain deferred |
| Today suggestion ownership/output validation (2026-11-12) | Full Deno lint passed across **21 files**; the no-remote pure test set passed **22/22**. `deno check --no-remote` and `deno fmt --check` passed for the four pure style/daily response helper/test files; `git diff --check` passed. The handler's authenticated Supabase query and quota ordering were not integration-tested; no Supabase or Gemini function was invoked |
| Clothing analysis input/output validation (2026-11-12) | Full Deno lint passed across **23 files**; the no-remote pure test set passed **26/26**. `deno check --no-remote` and `deno fmt --check` passed for the pure validator/test files; `git diff --check` passed. The handler was not type-checked or invoked; no provider call was made |
| Current Edge Function CI steps (2026-11-12) | Reran the exact CI pure-test file list after the anchor-slot fix: **26 passed**. `deno lint supabase/functions` passed across **23 files**; `deno check --no-remote` and `deno fmt --check` passed on all six pure validation helpers/tests; `git diff --check` passed. No remote database/provider call was made. Protected handler type-check and CI workflow execution remain deferred |
| Outfit rating placeholder removal (2026-11-12) | `.tooling/flutter/bin/dart analyze lib/routes/app_routes.dart` reported **No issues found**. `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/app_import_smoke_test.dart` passed **1/1**, verifying app entry and transitively imported screens compile. This does not test device behavior |
| Current-HEAD Flutter regression and CI analyzer rerun (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` passed **59/59**. `.tooling/flutter/bin/flutter analyze --no-pub --no-fatal-infos --fatal-warnings` exited **0** with **245 info** diagnostics and no warning/error diagnostics. No build, device, database, provider, or purchase behavior was tested |
| Current-HEAD Edge Function pure checks (2026-11-12) | Project-local Deno **2.9.6** ran the exact CI no-remote pure test list: **26 passed, 0 failed**; `deno lint supabase/functions` passed across **23 files**. No function handler type-check, network call, database operation, or provider request was performed |
| AI request/quota ordering (2026-11-12) | Full Deno lint passed across **23 files** and the no-remote tests passed **26/26** after request validation was moved ahead of quota use. `deno check --no-remote` passed for pure response helpers/tests; no network or database call was made. Edge Function handler type-check remains deferred |
| Recovered wardrobe schema (2026-11-12) | `.tooling/supabase/node_modules/.bin/supabase db query --remote=qxsdwwdrxoyxmnapuqqv --read-only` against `information_schema.columns` confirmed `wardrobe_items` includes `semantic_label`, `wear_count`, `image_url`, and `last_worn`, but not `color` or `times_worn`. Only metadata was queried; no account rows or Storage content were read and no hosted changes were made |
| Runtime dependency/API correction (2026-11-12) | `.tooling/flutter/bin/flutter pub get --offline` succeeded and updated the lockfile for direct runtime `image` usage; targeted Dart analysis of image/storage/export/subscription code and regression tests reported **No issues found** after migrating to `Purchases.purchase(PurchaseParams.package(package))` |
| Device | No emulator/device used; `adb` is unavailable in the current environment, so no physical-device installation or runtime check was possible |
| Formatting/diff | Targeted Dart formatting; `deno fmt --check` on the new AI validator/test and three earlier functions; `git diff --check` and `git diff --cached --check` passed |

Latest verification: after the dependency/API correction, the focused image
consumer/routing tests passed **11/11** and the subscription/operation-queue
tests passed **4/4** on 2026-11-12. Targeted Dart analysis of these source and
test files reported **No issues found**. The
latest full serial Flutter suite passed **59/59** after the
learning recovery change. Learning widget tests passed 3/3 for outage retry,
failed save, and confirmed success. Pure challenge merge tests passed 3/3; the
three-locale password-recovery/challenge/learning localization test passed 1/1.
The targeted image routing/private consumer/app-import selection passed 12/12;
reset cleanup 3/3; reminder scheduling 4/4; AI payload encoding 3/3; Deno
request validation 5/5; and app import smoke passed 1/1. Targeted analysis of
learning service/screen/badge, challenge/localization files, splash screen/test,
and reset, notification, AI payload/client and helper files reported no issues.
Targeted formatting and `git diff --check` passed. The default project-wide
analyzer invocation exits 1 with 249 informational diagnostics and no warnings
or errors. The configured CI severity gate was also run locally and exits 0
with the same info backlog. Focused image and billing analysis is clean. The
previous AAB was rebuilt from the learning-recovery source and archive-checked,
but it predates `e2085cb` and does not represent current HEAD. A current-source
rebuild was attempted with one worker and a 2 GiB heap, then stopped when swap
filled and memory PSI rose. The existing artifact was unchanged. It remains
unsigned and has no provider configuration. Tests did not connect to a backend
or call AI
providers. A project-local `pglast` parse accepted all 30 outer SQL statements
in the Storage fixture; this does not execute policies or prove isolation.
Read-only metadata queries confirmed public buckets and broad Storage table
grants. No device check was possible because `adb` is absent.

## 3. Deferred or incomplete verification

- The full Flutter suite passed 59/59 after the final local Dart changes. The
  default project-wide analyzer invocation exits 1 with 249 informational
  diagnostics, 0 warnings and 0 errors. CI now allows info-level lints while
  keeping warnings fatal; that configured gate passed locally. The remote CI
  workflow itself has not run.
- Deno check has two failed attempts: first found `today-suggestion` unknown
  catch typing (fixed with generic client error), second found nullable data in
  `generate-ai-insights` (fixed with `?? []`). Do not claim those final fixes
  verified. `ai-suggestions` type check and full CI remain pending. Its five
  pure request validation tests pass without remote imports.
- The local `ai-suggestions` client contract now sends `imageBase64`; recovered
  production still uses `imageUrl`. Keep those client/function versions
  coordinated in any future rollout. The local function now returns generic
  client errors while retaining detailed server logs. Nothing was deployed.
- Run the new pgTAP fixture and migration chain against a clean non-production
  schema, then run `storage_security.test.sql` after the reviewed cutover. A
  two-session harness at `supabase/tests/concurrent_quota.sh` is prepared for
  simultaneous free-tier suggestion and coach calls; it refuses non-loopback
  database hosts and remains unexecuted. Both calls should yield one success
  and one denial per quota kind.
- The locally built AAB has been rechecked: SHA-256 `31c4b88da33b03d06d69935502816daa6f55589461231be20a4a8098fd5d14d5` and archive integrity match the recorded artifact. It predates `e2085cb`, is unsigned, and lacks the private upload key. Device/network behavior,
  timezone/permission behavior, accessibility and export runtime checks remain
  pending. The optional local debug APK build was deferred when swap filled; no
  debug APK exists, and `adb` is not installed for local device validation.
- No purchase, restore, RevenueCat webhook, production deployment, Play tester
  transaction, database migration or private bucket cutover was executed.
- Deno 2.9.6 is available at the project-local ignored path. The pure request
  request, insight-parser and entitlement tests pass 13/13, and targeted Deno
  lint passes on the affected functions. Final type-checking remains deferred
  after the earlier two attempts; no type-check success is claimed for the last
  edits to `delete-account`, `generate-ai-insights`, `ai-suggestions` or
  `verify-purchase`.

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
- Physical-device verification needs Android Platform Tools (`adb`) and a
  connected Android device. Neither was available in this environment; no
  emulator was started.
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
- [x] Fix outfit AI suggestions to send a compressed bounded image payload and
  remove server-side fetches of caller URLs; authenticate before quota use,
  return generic client errors, and prepare pure Dart and Deno tests. Committed
  as `6ca5700`.
- [x] Use the existing localized password-recovery label in the splash screen;
  the focused three-locale regression test passed 1/1. Committed as `b9f4ddc`.
- [x] Repair challenge history relation parsing and distinguish backend errors
  from an empty catalog with a localized retry action; pure merge tests passed
  3/3. Committed as `42512f6`.
- [x] Restore useful learning summary/completion behavior using existing catalog
  fields; distinguish read failures from empty data and report progress writes
  honestly. Three focused widget tests passed. Completion remains self-attested
  because no quiz/content schema exists. Committed as `317e22e`.
- [x] Run the full Flutter suite sequentially: 59 passed after learning,
  challenge and localization changes; the affected image/app-import selection
  passed 12/12.
- [x] Prepare local pgTAP fixture for protected tier, profile/outfit ownership
  and single-session AI quota behavior.
- [x] Add a separate local-only Storage pgTAP fixture for anonymous denial,
  private bucket state, and user A/user B read/upload/delete owner isolation;
  the fixture assumes private cutover policies are installed only in the
  disposable test database and remains unexecuted.
- [ ] Finish Deno verification after the two-attempt deferral; resolve any
  remaining type errors without `@ts-nocheck`.
- [x] Rerun project-wide Flutter analysis after the earlier warning cleanup;
  latest run exited 1 with 249 infos, 0 warnings and 0 errors. Targeted
  analysis for image/export/storage/billing sources and focused tests passed.
  The configured CI analyzer severity gate then exited 0 locally, with info
  diagnostics non-fatal and warnings fatal.
- [x] Targeted Dart/Deno formatting and `git diff --check` passed. Full suite:
  59/59; learning path: 3/3; challenge merge: 3/3; reset helper: 3/3;
  notification scheduling: 4/4; AI payload: 3/3;
  Deno request validation: 5/5; app import: 1/1; image/app import selection:
  12/12.
- [x] Rebuild the release AAB after the learning recovery source change; that
  bundle passed archive integrity and is unsigned with no Supabase/RevenueCat
  build values. It predates `e2085cb`; rebuilding current HEAD remains pending
  until swap pressure clears. A current-source attempt stopped when swap filled
  and created no new bundle.
- [ ] Validate migration on non-production schema and prepare isolated security
  fixtures; production stays read-only.
- [x] Prepare concurrent two-session quota regression harness for disposable
  loopback database; syntax checked only, execution deferred until a local
  database is permitted and available.
- [x] Replace insight aggregation's explicit `any` types, bound untrusted Gemini
  response fields, and add pure parser tests. Deno lint and 9 no-remote tests
  passed; function type-check remains deferred.
- [x] Extract RevenueCat exact-entitlement/date evaluation into a pure helper;
  malformed date data fails closed. Four focused tests pass. The final Edge
  Function source remains un-typechecked after the two-attempt deferral.
- [x] Keep Gemini API keys out of URL query strings in analyze-clothing,
  today-suggestion, style-coach, and generate-ai-insights; the shared request
  helper regression test passed 1/1 without network access. Full-function lint
  passed across the helper and four Gemini handlers after a follow-up cleanup;
  type-check/deployment remain deferred.
- [x] Add the pure no-remote Edge Function test set to CI, including Gemini
  request construction. The focused Gemini test passed locally; the workflow
  itself has not run.
- [x] Clear Deno lint across all 17 Edge Function files by replacing the last
  two inline Supabase imports with the existing import-map alias; full lint and
  all 14 no-remote pure tests passed after the change.
- [x] Add full `deno lint supabase/functions` to CI. The same command passes
  locally across the current 23 function/helper/test files; CI has not run.
- [x] Order the CI no-remote Deno test step before protected-function type
  checks so both results remain independently visible when type-checking fails.
- [x] Validate style-coach's model responses against the existing passive,
  active, and event client contracts; bound output and ignore untrusted control
  fields. Four pure regression cases pass without network access.
- [x] Validate daily-suggestion item IDs against the authenticated user's
  database-backed wardrobe, canonicalize image data from those rows, omit image
  references from Gemini prompts, bound response fields, and restrict support
  item slots separately from the anchor slot. The focused four pure cases pass;
  the RLS query still needs disposable-database integration validation.
- [x] Validate analyze-clothing image inputs and Gemini output; reject malformed
  or oversized input before quota use, verify provider configuration before
  quota use, and return bounded contract fields with generic errors. Four pure
  regression cases pass; handler type-check/runtime validation remains deferred.
- [x] Validate style-coach modes and JSON before quota use; check Gemini
  configuration before consuming coach quota. Today-suggestion similarly checks
  request/provider configuration and confirms the authenticated wardrobe before
  consuming its atomic quota. Runtime quota-ordering integration remains unrun.
- [x] Remove the unreachable rating demo route and stale fake outfit preview;
  the existing daily-log and outfit-history rating flows remain. Targeted route
  analysis and app-import smoke test passed.
- [x] Re-run the complete Flutter tests sequentially and the configured
  CI-equivalent analyzer on current HEAD after removing the dead route: **59/59**
  tests passed; analyzer exited 0 with **245 infos**, no warnings or errors.
- [x] Re-run the exact CI no-remote Deno pure test set and full Edge Function
  lint on current HEAD: **26/26** tests passed; lint checked **23 files**.
  Protected handler type-checking remains deferred after its earlier attempts.
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

**Exact next step:** the Flutter suite/analyzer and Edge Function pure tests/lint
now pass on current HEAD. Do not retry the AAB while swap remains nearly full.
After memory pressure clears, rebuild the unsigned AAB from current HEAD with
one Gradle worker and a conservative heap, then verify its archive/hash; the
existing bundle predates `e2085cb`. Separately, request an explicitly disposable
non-production Supabase environment for applying the migration chain and
running Storage/concurrent quota fixtures; no local stack or production mutation
is authorized. Before a signed or interactive Android release check, provide
public app configuration and private upload-signing inputs through the private
build environment, complete RevenueCat/Play dashboard setup, and run the AAB on
a physical device/internal tester track. Final protected-function type checks
remain deferred after the prior two-attempt limit; invoke Deno by its
project-local ignored path.
