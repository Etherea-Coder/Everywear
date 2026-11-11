# Android release status

Last updated: 2026-11-11

## Current classification

Not yet a release candidate. A substantial source recovery checkpoint exists on `recovery/android-v1`; heavy validation is intentionally deferred during the current code-only pass.

## 1. Completed code changes

- Preserved package identity `com.stylewise.app`, removed conflicting Kotlin-DSL Android files, pinned Flutter 3.35.7 in `.fvmrc`, made `pubspec.lock` trackable, added `integration_test`, and configured release signing to require private `android/key.properties` rather than debug signing.
- Repaired stale test sources and lazy Supabase initialization in `AIIntelligenceService`.
- Added the review-only backend reconstruction/security migration and backend contract inventory.
- Removed the authenticated self-upgrade RPC; restricted profile entitlement/counter columns; hardened ownership checks for both outfit and linked wardrobe item; added atomic AI and outfit-log quota enforcement; added missing application tables/catalog seed proposals, RLS, Storage, and Realtime proposals.
- Added JWT validation to interactive AI functions and moved quota consumption into protected backend operations. Background notification scheduling no longer consumes interactive AI quota.
- Reworked RevenueCat to require a build-time public SDK key plus exact entitlement ID, bind login to the Supabase UUID, fail closed, verify server-side, parse wrapped webhook events, and handle duplicate/stale/cancelled/expired/grace events. The upgrade UI uses store-localized prices, is disabled when unconfigured, and reports purchase/restore outcomes honestly. Fabricated testimonials were removed from the upgrade screen.
- Account deletion now validates every deletion, removes user Storage objects, deletes the profile with the correct key, and only reports success after auth deletion. Reset also removes uploads and resets onboarding/profile data.
- Scoped Hive wardrobe cache, onboarding preferences, AI cache, and notification state by authenticated user; full remote wardrobe sync reconciles remote deletions; logout/reset/deletion clears only account-owned state while retaining global locale/theme/reporting consent.
- Sentry `beforeSend` and manual captures now honor the stored reporting opt-out.
- Image routing now distinguishes stable `wardrobe-images/{user}/...` and `avatars/{user}/...` references, recognized Storage object URLs on the exact configured Supabase origin, ordinary external HTTP(S) URLs, assets, and local files. Wardrobe reads retain `image_ref` and resolve authorized display URLs at read time; new wardrobe uploads return stable object references instead of public URLs.

## 2. Checks actually performed

Before the code-only restriction and computer freeze:

| Check | Actual result |
|---|---|
| Git baseline | Started clean at `5433f6d`; branch `recovery/android-v1` created |
| Repository instructions | No `AGENTS.md` found |
| Toolchain inventory | Java/Javac 21.0.13 and Android SDK found; Docker and Supabase CLI absent |
| Pinned Flutter | Project-local Flutter 3.35.7 / Dart 3.9.2 installed |
| Dependency resolution | Completed and produced `pubspec.lock`; a compatible `image`/`archive` pair is pinned |
| Analyzer (earlier checkpoint) | Reached 284 warnings/info with no reported analyzer errors before the latest code edits |
| Tests (earlier checkpoint) | Reached three stale AI widget assertions; those tests were edited afterward but not rerun |
| Android release build (earlier attempt) | Reached Java compilation, then failed because a generated registrant included test-only `integration_test`; the generated file was removed but no build was rerun |
| Current lightweight checks | Targeted Dart formatting and `git diff --check` only; no project-wide validation |
| Hosted backend | No CLI or authenticated environment is available in this shell; no hosted read/write operation was attempted |

## 3. Builds/tests deferred

- Flutter build/run, Gradle, APK/AAB packaging, emulator/device checks, test suites, and project-wide analyzer.
- Dependency re-resolution after any later dependency edit.
- Local Supabase/Docker migration reset and anonymous/user-A/user-B/concurrency fixtures.
- Edge Function type-check/deploy and real RevenueCat tester purchase/restore/webhook evidence.
- Focused image reference routing regression tests are prepared but have not been executed.

## 4. Remaining provider setup and blockers

- The original Supabase project is recovered, but this checkout lacks authenticated read-only access or a schema dump. `20261111090000_reconstruct_and_secure_backend.sql` must not be deployed until reconciled against that project.
- Supply the recovered project URL and public anon/publishable key through build configuration. Keep service role, Gemini key, RevenueCat secret API key, and webhook secret server-side.
- Supply the RevenueCat public Android SDK key and exact entitlement identifier as Dart defines; configure the same entitlement, Android package, products/offerings, Play service credentials, and webhook secrets in the dashboards.
- Confirm `com.stylewise.app` is the registered Play/RevenueCat application ID.
- Private upload keystore/passwords remain absent. They must be supplied outside Git before a signed AAB can exist.
- Private Storage delivery still needs a client contract (stored object path plus authenticated/signed URL) before any recovered public bucket is made private.
- Device timezone identification remains unresolved; the current scheduler initializes timezone data but cannot reliably select the device IANA zone without an additional platform timezone source.
- Privacy policy URL, account-deletion URL, store listing assets/declarations, Play eligibility, and real tester evidence remain external release inputs.

## 5. Exact next step

Latest source checkpoint: purchase/restore explicitly establishes the current Supabase UUID in RevenueCat and rejects account changes during the store operation. Plan selection requires the exact offered billing period; uncalculated savings claims were removed. Webhook event deduplication, ordering, and profile changes now use one service-role-only database transaction (`apply_subscription_event`); absent entitlement IDs fail closed. Targeted Dart formatting and whitespace checks passed; execution remains deferred.

**Image routing checkpoint (2026-11-11):** Classification uses structured URI parsing and exact Supabase origin plus Storage path checks. External and lookalike URLs stay on ordinary network-image handling; stable references and recognized project Storage URLs use the signed-URL resolver. Focused routing tests were added; targeted formatting and whitespace checks passed, but tests were not run.

Private rollout remains blocked on recovered schema and bucket-policy reconciliation. Existing public URLs/objects must be inventoried and migrated to stable references, avatar/export consumers must be converted, and private read/upload/delete policies must be reviewed before changing bucket visibility. Source changes do not make existing hosted images private. Preserve public compatibility until this rollout is complete.

Other release blockers remain: reconcile the proposed migration with the recovered hosted schema, provide provider configuration and signing inputs, obtain privacy/deletion URLs and store materials, and perform the deferred validation and real tester purchase checks. Billing race correctness also remains unproven pending canonical RevenueCat snapshot reconciliation and execution of focused tests.
