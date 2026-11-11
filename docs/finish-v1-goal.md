# Everywear Android v1 finish contract

This document records the authorized finish scope for branch `recovery/android-v1`. It supersedes earlier restrictions that prohibited tests, analysis, and builds. Work continues through local implementation and checkpoints until each item is verified or specifically blocked.

## Safety and operating contract

- Preserve current source and generated Linux/macOS platform changes. Do not reset, clean, reclone, overwrite working source with downloaded source, or rewrite history.
- Production Supabase project `qxsdwwdrxoyxmnapuqqv` is read-only for this effort. Do not mutate hosted data, schema, buckets, policies, settings, migration history, Edge Functions, RevenueCat, Play services, or publish artifacts.
- Do not push, merge `main`, publish, or claim unexecuted validation, provider configuration, or purchases.
- Tests must not touch production or spend live AI/billing quota. Use local fakes/mocks or pure tests. No emulator, Docker, or local Supabase stack.
- Inspect resources first. Run expensive checks sequentially with single-worker/conservative memory settings. After two failures of one expensive check, or observed resource pressure, defer it and continue independent work. Never kill unrelated processes or change system settings.
- Stage explicit paths, checkpoint coherent changes locally, and keep this document and `docs/release-status.md` resumable.

## Completion checklist

- [ ] Establish current checkout, repository instructions, resources, and reproducible toolchain state.
- [ ] Reconcile the recovered Supabase schema read-only: relations/columns/types, constraints, indexes, FKs, RLS, grants, triggers, counters, privileged function definitions, Storage buckets/policies, Realtime, and deployed Edge Function source. Compare deployed code separately; do not replace local source.
- [ ] Prepare minimal forward-only schema/security changes and an ordered private-image rollout with conversion, owner restrictions, policy replacement, verification, and privacy-preserving rollback. Do not apply to production.
- [ ] Close and test local backend security/functionality gaps: protected entitlement/counters, ownership on both sides of joins, atomic quotas, per-function delegated identity validation, account deletion including Storage, account-scoped state, reporting opt-out, auth/onboarding persistence, and safe outage/error behavior.
- [ ] Complete RevenueCat code review/fixes for authenticated UUID binding, exact entitlement, fail-closed server verification, webhook parsing/order/idempotency/grace, concurrent purchase/restore and account changes, localized prices, and honest unconfigured/error states. Document provider setup and real Play tester steps without making purchases.
- [ ] Complete documented v1 local gaps: image refresh/export, reminders/timezones/permissions, large text, offline and error states, and obsolete placeholders; document unresolved product decisions.
- [ ] Run focused tests sequentially, fix failures, then run the project analyzer and appropriate suite as resources allow. Check Dart and TypeScript with compatible tools. Do not weaken checks/security to pass.
- [ ] Attempt Android packaging only after cheaper checks. Produce signed AAB only with valid existing private signing input; otherwise produce a clearly labeled local artifact if feasible. No emulator or live-purchase claims without execution.
- [ ] Update CI/setup/deployment instructions, release status, and this checklist. Commit coherent changes with explicit file paths.

## Current known boundaries

- Recovered Supabase project is production and strictly read-only. Read-only metadata/API inspection is authorized; query only schema/catalog metadata, not customer records, secrets, or uploaded content.
- Existing hosted `wardrobe-images` and `avatars` buckets are public. Client changes alone do not make them private. Keep current visibility until a reconciled migration, compatibility conversion, security validation, and privacy-preserving rollback plan are approved.
- RevenueCat remains incompletely configured. Keep purchase unavailable until the exact public Android key and entitlement are supplied and verification path is ready.
- Signing inputs, Play/RevenueCat dashboard configuration, privacy/deletion URLs, store materials, and tester evidence are not presumed to exist.
