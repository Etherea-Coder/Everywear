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
- [x] Implement image refresh/export, timezone-aware reminders, system text scaling, offline/error handling, and remove the unused payment placeholder; document remaining provider/release inputs.
- [x] Full Flutter suite passed 38 tests sequentially. Analyzer returned 0 errors/9 warnings/281 info; reported warnings were edited without rechecking. Deno checks passed seven functions; final `generate-ai-insights` and `ai-suggestions` checks remain incomplete after the two-attempt limit.
- [ ] Two Android AAB attempts failed on the generated test-only integration plugin reference. A release-only no-op shim was added and independently compiled with Java; no bundle retry after the two-attempt limit. No signing, emulator, or live-purchase claim is made.
- [x] Commit documentation/CI and source checkpoints: `395255b`, `5ba8204`, `fe0a5c5`, `ae02ee0`, `ed2f491`, `1f9261f`.
- [x] On wardrobe replacement or deletion, clean up the prior owner-scoped Storage object; clean newly uploaded images when the initial row save fails. Cleanup failure can leave an orphan because Postgres and Storage operations are not transactional.

## Current known boundaries

- Recovered Supabase project is production and strictly read-only. Read-only metadata/API inspection is authorized; query only schema/catalog metadata, not customer records, secrets, or uploaded content.
- Existing hosted `wardrobe-images` and `avatars` buckets are public. Client changes alone do not make them private. Keep current visibility until a reconciled migration, compatibility conversion, security validation, and privacy-preserving rollback plan are approved.
- RevenueCat remains incompletely configured. Keep purchase unavailable until the exact public Android key and entitlement are supplied and verification path is ready.
- Signing inputs, Play/RevenueCat dashboard configuration, privacy/deletion URLs, store materials, and tester evidence are not presumed to exist.
- The two-attempt limits for Deno checks and Android packaging were reached before final verification; neither an Android bundle nor signed artifact exists. Defer those retries to a later validation pass after these independent code changes; no signing inputs are present.
