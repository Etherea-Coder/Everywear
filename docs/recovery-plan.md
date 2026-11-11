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

1. **Reproducible Flutter/Android build** — toolchain pinned and current-source unsigned bundle built; signing, provider configuration, device validation, and a clean project-wide analyzer remain pending
   - Pin Flutter 3.35.7 (Dart 3.9-compatible) in `.fvmrc`.
   - Track `pubspec.lock`; add the Flutter SDK `integration_test` dependency.
   - Resolve the duplicate Gradle DSL configuration without changing the active package identity (`com.stylewise.app`) until Play and RevenueCat registrations are confirmed.
   - Stale test sources were repaired; the current sequential suite passed 52 tests, and the password-recovery localization regression test passed 1/1. Targeted analysis of changed reset, notification, AI payload/client and splash screen/test code reports no issues. After the earlier 0 errors/9 warnings/281 info, project-wide analysis was rerun after warning-site edits and exited 1 with 273 diagnostics; output truncation prevents a full severity breakdown, so project-wide analysis is not green. Two bundle attempts failed on the generated dev-only integration plugin reference; after adding the release-only no-op shim, the latest source built an unsigned AAB and passed archive integrity inspection. It lacks public provider values and upload signing, and was not installed or run.
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
   - Current AAB: `build/app/outputs/bundle/release/app-release.aab`, 76,521,004 bytes, SHA-256 `846ecb268be353a012d63eaa2d90cf63ad6f477c105ca71276f36ee5dac1af04`; archive integrity passed. It is unsigned until private upload-signing inputs are supplied.

## External inputs (only when dependent work reaches them)

- Recovered Supabase access is available for read-only metadata/source inspection. Do not reset, replace, or mutate the production project; use a schema-only clone/local harness for validation.
- Recovered project URL and publishable/anon key for the app build; service role and function secrets must stay server-side.
- RevenueCat public Android SDK key, exact paid entitlement identifier, and webhook authorization secret.
- Confirmation of the registered Android application ID in Play Console and RevenueCat.
- Private Android upload keystore and its passwords supplied outside Git.
- A non-production PostgreSQL/Supabase environment for clean-chain migration and identity/quota/Storage proofs. Docker is intentionally not started during this pass.
