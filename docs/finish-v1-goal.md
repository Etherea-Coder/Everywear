# Everywear Android v1 finish contract

This document records the authorized finish scope. Work began on
`recovery/android-v1` and now continues on `main`; the current branch and
checkpoint are recorded in the dated addendum below. It supersedes earlier
restrictions that prohibited tests, analysis, and builds. Work continues until
each item is verified or specifically blocked.

## Safety and operating contract

- Preserve current source and generated Linux/macOS platform changes. Do not reset, clean, reclone, overwrite working source with downloaded source, or rewrite history.
- Production Supabase project `qxsdwwdrxoyxmnapuqqv` is read-only for this effort. Do not mutate hosted data, schema, buckets, policies, settings, migration history, Edge Functions, RevenueCat, Play services, or publish artifacts.
- Do not rewrite history, push, or publish without current explicit
  authorization; do not claim unexecuted validation, provider configuration,
  or purchases.
- Tests must not touch production or spend live AI/billing quota. Use local fakes/mocks or pure tests. No emulator, Docker, or local Supabase stack.
- Inspect resources first. Run expensive checks sequentially with single-worker/conservative memory settings. After two failures of one expensive check, or observed resource pressure, defer it and continue independent work. Never kill unrelated processes or change system settings.
- Stage explicit paths, checkpoint coherent changes locally, and keep this document and `docs/release-status.md` resumable.

## Completion checklist (historical baseline 2026-11-13; see current addendum)

- [x] Establish current checkout, repository instructions, resources, and reproducible toolchain state.
- [x] Reconcile the recovered Supabase schema read-only: relations/columns/types, constraints, indexes, FKs, RLS, grants, triggers, counters, privileged function definitions, Storage buckets/policies, Realtime, and deployed Edge Function source. Compare deployed code separately; do not replace local source.
- [x] Prepare a forward-only schema/security proposal and ordered private-image rollout with stable-reference conversion, owner restrictions, policy replacement, verification, and privacy-preserving rollback.
- [x] Validate SQL migrations and fixtures on a disposable PostgreSQL 17.6 minimal platform harness: 48/48 pgTAP security/quota assertions, migration/legacy transition/rollback checks, and concurrent free/premium reservation checks passed. A Storage catalog/RLS stub passed 11/11 policy assertions. The subsequent isolated staging project received all nine reviewed migrations and eight JWT-gateway-protected functions. Synthetic hosted checks passed separately: security/Auth/PostgREST/quota 52/52, filtered Realtime 5/5, private Storage/account deletion 31/31. This is integration evidence for the exercised staging paths, not production validation or a full product/device test.
- [x] Implement local backend security/functionality changes for protected fields/counters, bilateral outfit-item ownership, atomic quotas, per-function identity validation, account deletion including Storage, account-scoped state, reporting opt-out, onboarding persistence, safe outage/error behavior, and expiry-aware premium decisions. Staging verified profile privilege boundaries, self-upgrade denial, cross-user isolation, concurrent reservations, private object access, and deletion. Device behavior and production enforcement remain unverified.
- [x] Implement RevenueCat code changes for UUID binding, exact entitlement, fail-closed verification, webhook ordering/idempotency/grace, purchase/restore/account races, localized prices and honest unconfigured/error states. Provider setup and Play tester steps are documented; no purchases were made.
- [x] Implement image refresh/export, stable owner-scoped image caching/eviction, timezone-aware reminders, system text scaling, offline/error handling, and remove unused ad/payment placeholders; document remaining provider/release inputs.
- [x] A sequential full Flutter suite passed 94/94 on a prior app checkpoint. Two changed provider tests then passed 6/6 in isolation; the whole suite was not rerun afterward. The latest code checkpoint's staging-banner test passed 2/2. Full project analysis at the earlier checkpoint completed with 248 infos and no warnings/errors. Deno 2.9.6 checks previously passed 32 pure tests, lint across 33 files, and cached type-checking of nine protected handlers.
- [x] Source `ca800ea` produced an earlier Android release AAB using one Gradle worker and a 2 GiB heap. That historical bundle passed archive integrity and had SHA-256 `ac2409f9eed9a6b9f5cf89f3fde6fb9e7a90439b327499889b56cb8e34c02243`; it was unsigned because `android/key.properties` was absent. `aapt dump badging` confirms the existing debug APK has SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`, package `com.stylewise.app`, version `1.0.0`, and version code `1`; it uses the debug certificate. Neither artifact is a current free-beta build. `adb` is present at `/home/theanarchitect/Android/Sdk/platform-tools/adb`, but `adb devices -l` reports no attached devices.
- [x] CI is configured to install Temurin 21, select it explicitly for Flutter, and compile an unsigned release AAB after tests. Local Flutter had selected Android Studio JBR 25.0.3 and failed before compilation; pinning Java 21 locally produced the refreshed AAB above. Commit `2a3dedd`; the hosted CI workflow has not run.
- [x] Commit documentation/CI and source checkpoints: `395255b`, `5ba8204`, `fe0a5c5`, `ae02ee0`, `ed2f491`, `1f9261f`, `5f2bef0`, `5b12e53`, `1b7dcc3`, `d70bb6d`, `c8cff41`, `0bd15b4`, `281efa2`, `b8f8372`, `2d7d9f3`, `52d13c8`, `84d2923`, `192a8f2`, `9f1a54a`, `6ca5700`, `7abb46d`, `1a088cf`, `b9f4ddc`, `42512f6`, `317e22e`, `e2085cb`, `ec4e018`, `36a0f22`, `43db178`, `d8fc87b`, `0a95323`, `5d8433c`, `099cec7`, `4a205cf`, `505c573`, `8140241`, `5055140`, `04a57bc`, `917665d`, `3ff72ea`, `ff170eb`, `c8fb48f`, `2a3dedd`, `645ff8b`, `ca800ea`.
- [x] Subsequent staging/release checkpoints: `fa16245` (private staging image migration), `f71efd8` (staging deployment evidence and visible APK marker/helper), `73e20b3`, `b9d4371`, `e904fcc`, `573b5b9`, and `aeda62a` (status, credential cleanup, documentation reconciliation, analyzer evidence, and exact staging-ref APK guard).
- [x] On wardrobe replacement or deletion, clean up the prior owner-scoped Storage object; clean newly uploaded images when the initial row save fails. Cleanup failure can leave an orphan because Postgres and Storage operations are not transactional.
- [x] Prepare Uptodown free-beta configuration: `EVERYWEAR_FREE_BETA` disables RevenueCat and ads, version is `1.0.0-beta.1+2`, package identity remains `com.stylewise.app`, and a staging-only debug APK helper accepts only the approved project ref and validates private config. Focused billing/ads/localization tests passed 26/26; `bash -n`, helper guards, targeted formatting, and `git diff --check` passed.
- [x] Receive owner approval for the isolated Free Everywear staging project; verify exact identity through authenticated CLI before writes; deploy the reviewed nine-migration chain and eight required functions only there. Keep production read-only and Clameo untouched.
- [x] Build and verify the connected staging debug APK. The helper used only approved ref `aftdbphdobfrshienple`; archive integrity, package/version, v2 debug signature, size, and SHA-256 are recorded in `uptodown-free-beta.md`. Full swap usage did not prevent the build with 6.6 GiB RAM available.
- [ ] Complete the remaining connected-device smoke checks using the latest
  source build. The A065 is now connected and an earlier staging build has
  received partial manual and automated checks; see the current addendum for
  exact passes and failures. Public distribution remains gated on upload
  signing and owner release materials.

## Current known boundaries

- Recovered Supabase project is production and strictly read-only. Read-only metadata/API inspection is authorized; query only schema/catalog metadata, not customer records, secrets, or uploaded content.
- Recovered production `wardrobe-images` and `avatars` buckets remain public; staging has private buckets and owner-folder policies. Do not apply the cutover to production until legacy references are converted/reconciled, the compatible client is ready, and a reviewed privacy-preserving rollout is approved.
- RevenueCat remains incompletely configured. Keep purchase unavailable until the exact public Android key and entitlement are supplied and verification path is ready.
- Signing inputs, Play/RevenueCat dashboard configuration, privacy/deletion URLs, store materials, and tester evidence are not presumed to exist.
- Edge Function source checks and earlier Deno tests/type checks are recorded in release status. Staging exercised JWT rejection and no-provider fail-closed responses, but did not exercise successful AI inference, RevenueCat verification/webhooks, or provider quality. Remote CI has not run.
- The historical AAB and pre-beta APK are not the current free-beta source. A
  staging debug build is installed as `com.stylewise.app`, but it predates
  source commit `71e1dc9`; its install does not verify that commit. The helper
  uses the private mode-0600 URL/anon-key config outside the checkout.
  `android/key.properties` and an upload keystore are absent, so a public
  release-signed artifact is not available.
- The owner confirmed the approved Everywear staging project is on the existing Free organization. It has already been used for synthetic checks. Do not create additional projects or request a paid upgrade.
- The account-deletion function paginates outfit links and reports listing failures. Synthetic account deletion and Storage cleanup passed on isolated staging. Production deletion remains unverified and production was not mutated.

## Current status addendum (2026-11-16; `main` at `71e1dc9`)

- The A065 (`21471b75`) is connected. Read-only ADB confirms normal package
  `com.stylewise.app` is installed at version code 3; its first-install and
  last-update times are `2026-11-15 22:31:24`. The isolated test package
  `com.stylewise.app.stagingtest` is absent after expected Flutter test
  cleanup. At the latest check, the launcher was foregrounded, so the normal
  app's authenticated session is **not verified**. No app was launched and no
  local or hosted data was changed by that check.
- The owner previously reported manual staging checks for email sign-in,
  onboarding, Today/Wardrobe navigation, synthetic wardrobe image display,
  outfit logging, profile navigation, and sign-out. Those checks used an older
  installed APK; they do not validate the latest source commit. Same-phone
  email confirmation succeeded on an earlier build. Google sign-in,
  cross-device confirmation, a fresh confirmation flow on the latest source,
  and the signup-name display fix remain unverified on-device.
- The isolated automated run reached an authenticated staging session and
  passed synthetic wardrobe upload/display and Storage image rendering. It
  found the newly created outfit row for the current user/date but failed its
  Today-card assertion (`cardsBefore=0`, `cardsNow=0`). That run did not prove
  an app refresh defect because its baseline was captured while Today was
  offstage and it did not establish that Today was visible after route return.
  Commit `48324a9` strengthens the check with a visible Today key and a
  row-specific outfit-card key. This assertion has not been rerun.
- Commit `71e1dc9` persists a non-empty signup `full_name` into the user's
  profile during onboarding and checks profile-row agreement in the smoke test.
  Focused name/signup/onboarding tests passed 9/9 and targeted analysis had no
  errors. This code has not been built or installed on the phone.
- A build was deferred after inspection found 1.7–1.8 GiB available RAM,
  fully used 511 MiB swap, an existing Gradle daemon at about 2.3 GiB RSS, and
  low-but-nonzero memory pressure. Do not start another build until resource
  conditions are rechecked. Do not kill the existing daemon as a shortcut.
- **Next action:** the owner brings the normal app to the foreground; inspect
  only whether its authenticated screen is present. After that, wait for safer
  memory conditions, build the current staging source with the approved helper
  and gates, install over the normal app without clearing data, and resume the
  isolated smoke only after proving package isolation and allowing a fresh
  private sign-in to `.stagingtest`. Keep the staging backend and production
  separate; no production mutations, push, or publication are authorized.

## Checkpoint after authenticated install (2026-11-16)

- The previous “Next action” is superseded: the normal staging app was already
  foregrounded and authenticated, then updated in place to version code 4.
  Session restoration was visibly confirmed afterward on the Today screen.
- The newly built staging APK and its hash, signature, install evidence, and
  limits are recorded in `release-status.md` and `uptodown-free-beta.md`.
- The prior Today assertion is still inconclusive until the revised visible-tab
  and row-specific assertion is run on the isolated test package. Do not claim
  it as an app fix or successful device check. Before any full run, obtain the
  owner's private sign-in to `com.stylewise.app.stagingtest`, keep the normal
  package out of runner install/cleanup operations, and preserve its session.
