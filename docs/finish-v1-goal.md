# Everywear Android v1 finish contract

This document records the authorized finish scope for branch `recovery/android-v1`. It supersedes earlier restrictions that prohibited tests, analysis, and builds. Work continues through local implementation and checkpoints until each item is verified or specifically blocked.

## Safety and operating contract

- Preserve current source and generated Linux/macOS platform changes. Do not reset, clean, reclone, overwrite working source with downloaded source, or rewrite history.
- Production Supabase project `qxsdwwdrxoyxmnapuqqv` is read-only for this effort. Do not mutate hosted data, schema, buckets, policies, settings, migration history, Edge Functions, RevenueCat, Play services, or publish artifacts.
- Do not push, merge `main`, publish, or claim unexecuted validation, provider configuration, or purchases.
- Tests must not touch production or spend live AI/billing quota. Use local fakes/mocks or pure tests. No emulator, Docker, or local Supabase stack.
- Inspect resources first. Run expensive checks sequentially with single-worker/conservative memory settings. After two failures of one expensive check, or observed resource pressure, defer it and continue independent work. Never kill unrelated processes or change system settings.
- Stage explicit paths, checkpoint coherent changes locally, and keep this document and `docs/release-status.md` resumable.

## Completion checklist (updated 2026-11-12)

- [x] Establish current checkout, repository instructions, resources, and reproducible toolchain state.
- [x] Reconcile the recovered Supabase schema read-only: relations/columns/types, constraints, indexes, FKs, RLS, grants, triggers, counters, privileged function definitions, Storage buckets/policies, Realtime, and deployed Edge Function source. Compare deployed code separately; do not replace local source.
- [x] Prepare a forward-only schema/security proposal and ordered private-image rollout with stable-reference conversion, owner restrictions, policy replacement, verification, and privacy-preserving rollback.
- [ ] Validate the migration and fixtures on a non-production schema before any deployment; include anonymous/user-A/user-B and Storage isolation plus concurrent quota behavior. A loopback-only two-session suggestion/coach quota harness is prepared and syntax checked but unexecuted.
- [x] Implement local backend security/functionality changes for protected fields/counters, bilateral outfit-item ownership, atomic quotas, per-function identity validation, account deletion including Storage, account-scoped state, reporting opt-out, onboarding persistence, safe outage/error behavior, and expiry-aware premium decisions. Database isolation proof remains pending.
- [x] Implement RevenueCat code changes for UUID binding, exact entitlement, fail-closed verification, webhook ordering/idempotency/grace, purchase/restore/account races, localized prices and honest unconfigured/error states. Provider setup and Play tester steps are documented; no purchases were made.
- [x] Implement image refresh/export, stable owner-scoped image caching/eviction, timezone-aware reminders, system text scaling, offline/error handling, and remove unused ad/payment placeholders; document remaining provider/release inputs.
- [x] Full Flutter suite passed 59 tests sequentially on the current Dart sources; the CI analyzer gate exited 0 with 245 infos, no warnings/errors. Later commits changed only Edge Function TypeScript, CI, and documentation. Current Deno 2.9.6 CI-equivalent checks pass: 29 pure tests, lint across 25 files, and type-checking of all nine protected handlers with `supabase/functions/deno.json` explicitly selected. The handler check revealed and fixed nullable rating data in `generate-ai-insights`/`today-suggestion`, unsafe rating filtering in `style-coach`, a storage-only client parameter type in deletion, and the missing CI config selection.
- [x] Current source commit `04a57bc` built an Android release AAB using one Gradle worker and a 2 GiB heap. `:app:bundleRelease` succeeded; archive integrity passed. The artifact is 76,959,486 bytes with SHA-256 `3797fdf52ccd8509a2d8a4ecec9bd35c7970553efdc2fdfe3d3078b1616ebb99`. Gradle reported signing disabled because `android/key.properties` is absent; `jarsigner` confirms the AAB is unsigned. It was not installed or run, and no public provider build defines or live purchase were used.
- [x] Commit documentation/CI and source checkpoints: `395255b`, `5ba8204`, `fe0a5c5`, `ae02ee0`, `ed2f491`, `1f9261f`, `5f2bef0`, `5b12e53`, `1b7dcc3`, `d70bb6d`, `c8cff41`, `0bd15b4`, `281efa2`, `b8f8372`, `2d7d9f3`, `52d13c8`, `84d2923`, `192a8f2`, `9f1a54a`, `6ca5700`, `7abb46d`, `1a088cf`, `b9f4ddc`, `42512f6`, `317e22e`, `e2085cb`, `ec4e018`, `36a0f22`, `43db178`, `d8fc87b`, `0a95323`, `5d8433c`, `099cec7`, `4a205cf`, `505c573`, `8140241`, `5055140`, `04a57bc`.
- [x] On wardrobe replacement or deletion, clean up the prior owner-scoped Storage object; clean newly uploaded images when the initial row save fails. Cleanup failure can leave an orphan because Postgres and Storage operations are not transactional.

## Current known boundaries

- Recovered Supabase project is production and strictly read-only. Read-only metadata/API inspection is authorized; query only schema/catalog metadata, not customer records, secrets, or uploaded content.
- Existing hosted `wardrobe-images` and `avatars` buckets are public. Client changes alone do not make them private. Keep current visibility until a reconciled migration, compatibility conversion, security validation, and privacy-preserving rollback plan are approved.
- RevenueCat remains incompletely configured. Keep purchase unavailable until the exact public Android key and entitlement are supplied and verification path is ready.
- Signing inputs, Play/RevenueCat dashboard configuration, privacy/deletion URLs, store materials, and tester evidence are not presumed to exist.
- All nine protected Edge Function handlers currently pass the configured Deno type-check. This verifies TypeScript types, not runtime authentication, quota, database, or provider behavior; remote CI has not run.
- The current-source AAB is built and archive/hash verified, but unsigned, without public app defines, and not installed or run; private upload-signing inputs are absent.
- The recovered account-deletion function paginates outfit links, reports listing failures, and passes the current Deno type-check. Actual deletion and Storage behavior still require an isolated non-production environment.
