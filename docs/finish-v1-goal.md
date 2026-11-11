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
- [ ] Validate the migration and fixtures on a non-production schema before any deployment; include anonymous/user-A/user-B and Storage isolation plus concurrent quota behavior.
- [x] Implement local backend security/functionality changes for protected fields/counters, bilateral outfit-item ownership, atomic quotas, per-function identity validation, account deletion including Storage, account-scoped state, reporting opt-out, onboarding persistence, safe outage/error behavior, and expiry-aware premium decisions. Database isolation proof remains pending.
- [x] Implement RevenueCat code changes for UUID binding, exact entitlement, fail-closed verification, webhook ordering/idempotency/grace, purchase/restore/account races, localized prices and honest unconfigured/error states. Provider setup and Play tester steps are documented; no purchases were made.
- [x] Implement image refresh/export, stable owner-scoped image caching/eviction, timezone-aware reminders, system text scaling, offline/error handling, and remove unused ad/payment placeholders; document remaining provider/release inputs.
- [x] Full Flutter suite passed 52 tests sequentially after the AI local-image request change. Focused reset cleanup (3), local notification schedule (4), AI payload (3), and app import smoke (1) tests also passed. Five Deno request-validation tests passed with remote imports disabled. Targeted Dart analysis of changed files reports no issues; project-wide analyzer previously returned 0 errors/9 warnings/281 info, and its edited warnings remain unverified. Final `delete-account`, `generate-ai-insights`, and `ai-suggestions` function type checks remain incomplete after the two-attempt limit.
- [x] Two initial AAB attempts failed on the generated test-only integration plugin reference. After adding the release-only shim and completing code/tests, the final source built an AAB that passed archive integrity inspection. It is unsigned, built without public provider values, and was not installed or run. No emulator or live-purchase claim is made.
- [x] Commit documentation/CI and source checkpoints: `395255b`, `5ba8204`, `fe0a5c5`, `ae02ee0`, `ed2f491`, `1f9261f`, `5f2bef0`, `5b12e53`, `1b7dcc3`, `d70bb6d`, `c8cff41`, `0bd15b4`, `281efa2`, `b8f8372`, `2d7d9f3`, `52d13c8`, `84d2923`, `192a8f2`, `9f1a54a`, `6ca5700`.
- [x] On wardrobe replacement or deletion, clean up the prior owner-scoped Storage object; clean newly uploaded images when the initial row save fails. Cleanup failure can leave an orphan because Postgres and Storage operations are not transactional.

## Current known boundaries

- Recovered Supabase project is production and strictly read-only. Read-only metadata/API inspection is authorized; query only schema/catalog metadata, not customer records, secrets, or uploaded content.
- Existing hosted `wardrobe-images` and `avatars` buckets are public. Client changes alone do not make them private. Keep current visibility until a reconciled migration, compatibility conversion, security validation, and privacy-preserving rollback plan are approved.
- RevenueCat remains incompletely configured. Keep purchase unavailable until the exact public Android key and entitlement are supplied and verification path is ready.
- Signing inputs, Play/RevenueCat dashboard configuration, privacy/deletion URLs, store materials, and tester evidence are not presumed to exist.
- The Deno-check two-attempt limit was reached before final verification. The local AAB exists, but it is unsigned and lacks Supabase/RevenueCat public app values; no upload-signing inputs are present.
- The recovered account-deletion function now paginates outfit links and reports listing failures, but that final TypeScript revision remains untypechecked under the exhausted Deno-check budget.
