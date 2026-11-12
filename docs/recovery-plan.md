# Android v1 recovery plan

Last updated: 2026-11-12

## Baseline

- Recovery branch: `recovery/android-v1`
- Starting commit: `5433f6d74b4382604b6fc3a10caccc2a10719c1e`
- Working tree at start: clean
- No repository `AGENTS.md` was present.
- Java/Javac 21.0.13 are installed.
- Android SDK exists at `~/Android/Sdk`; `sdkmanager` is available at `cmdline-tools/latest/bin/sdkmanager` but is not on `PATH`.
- Flutter/Dart, Docker and Supabase CLI were not on `PATH` at baseline.
- `analyze_output.txt` is historical evidence only. Fresh results are recorded in `release-status.md`.

## Milestones

1. **Reproducible Flutter/Android build** — toolchain pinned and current-source unsigned bundle built; signing, provider configuration and device validation remain pending. The default analyzer reports informational lints; the CI gate permits infos while keeping warnings fatal and passed locally.
   - Pin Flutter 3.35.7 (Dart 3.9-compatible) in `.fvmrc`.
   - Track `pubspec.lock`; add the Flutter SDK `integration_test` dependency.
   - Resolve the duplicate Gradle DSL configuration without changing the active package identity (`com.stylewise.app`) until Play and RevenueCat registrations are confirmed.
   - Stale test sources were repaired; the current sequential suite passed 59 tests, including learning outage/save, challenge relation, and localization coverage. Targeted analysis of changed reset, notification, AI payload/client, splash screen, challenge, learning, image/export/storage and billing files reports no issues. The CI analyzer gate passed with 245 informational diagnostics, 0 warnings and 0 errors. An unsigned AAB from current source commit `04a57bc` built successfully with one Gradle worker and a 2 GiB heap; ZIP integrity passed and SHA-256 is `3797fdf52ccd8509a2d8a4ecec9bd35c7970553efdc2fdfe3d3078b1616ebb99`. It has no upload signing or public app defines and was not installed or run. An earlier debug APK attempt was deferred under swap pressure; `adb` remains unavailable.
2. **Complete, secure Supabase backend** — schema proposal reconciled to read-only production metadata; execution/security proof pending
   - Inventory the app's tables, RPCs, Storage, Realtime and Edge Function contract.
   - Add forward-only migrations and local security fixtures.
   - Do not deploy `20261111090000_reconstruct_and_secure_backend.sql` yet: it is a local proposal revised against the recovered schema but still needs clean-chain SQL validation, fixture proofs and human review. Do not mutate the production project or its absent migration history.
3. **Functional application flows** — local code implementation complete; backend/device runtime proof pending
   - Authentication callbacks and onboarding.
   - User-scoped cache/state and correct offline/outage behavior.
   - Wardrobe, outfits, spending, insights, learning/challenges and export/deletion.
   - Account deletion/reset now removes Storage objects, checks failures, and paginates outfit-link cleanup; persistent wardrobe, onboarding, AI, and notification state is user-scoped. Outfit suggestions now send compressed local-image bytes instead of an inaccessible device path; the Edge Function validates payloads and no longer fetches arbitrary caller URLs. Reset pagination, image payload, and DST-safe reminder behavior have focused passing tests. The app/function image contract requires a coordinated future deploy.
4. **RevenueCat repair** — code complete; provider setup and live verification pending
   - Fail closed until a public Android SDK key and exact entitlement ID are supplied.
   - Bind purchases to the Supabase UUID and harden server verification/webhooks.
5. **Android release candidate** — unsigned local AAB available; signed/provider-configured release and runtime validation pending
   - Accessibility, notifications/timezone, reporting opt-out and signing configuration.
   - Current AAB: `build/app/outputs/bundle/release/app-release.aab`, 76,959,486 bytes, SHA-256 `3797fdf52ccd8509a2d8a4ecec9bd35c7970553efdc2fdfe3d3078b1616ebb99`; archive integrity passed. It is unsigned and not device-tested. Private upload-signing inputs and app/provider configuration are also required.

## External inputs (only when dependent work reaches them)

- Recovered Supabase access is available for read-only metadata/source inspection. Do not reset, replace, or mutate the production project; use a schema-only clone/local harness for validation.
- Recovered project URL and publishable/anon key for the app build; service role and function secrets must stay server-side.
- RevenueCat public Android SDK key, exact paid entitlement identifier, and webhook authorization secret.
- Confirmation of the registered Android application ID in Play Console and RevenueCat.
- Private Android upload keystore and its passwords supplied outside Git.
- A non-production PostgreSQL/Supabase environment for clean-chain migration and identity/quota/Storage proofs. Docker is intentionally not started during this pass.
