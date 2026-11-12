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
   - Stale test sources were repaired; the complete sequential Flutter suite now passes 63 tests on current source commit `ca800ea`, including learning, challenge, and splash/auth recovery coverage. An earlier full-suite retry was interrupted under memory pressure, then later completed after pressure returned to zero. Focused image/billing/serialization/reminder tests passed 19/19; splash/auth/localization tests passed 5/5. Latest targeted Dart analysis reports no issues. The current-source project CI analyzer gate exited 0 with 244 informational diagnostics, no warnings or errors. Deno 2.9.6 CI-equivalent checks passed: 29 no-remote tests, lint over 25 files, and cached type-checks of all nine protected handlers. A Flutter CLI release AAB build succeeded after selecting JDK 21; without that selection Flutter chose Android Studio JBR 25.0.3 and Gradle failed before compilation. Current AAB from source commit `ca800ea`: `build/app/outputs/bundle/release/app-release.aab`, 76,421,600 bytes, SHA-256 `ac2409f9eed9a6b9f5cf89f3fde6fb9e7a90439b327499889b56cb8e34c02243`; archive integrity passed and `jarsigner` reports unsigned. CI commit `2a3dedd` installs Temurin 21, selects it for Flutter, then builds the AAB; remote CI has not run. Gradle is capped at one worker and 2 GiB heap. A debug APK is a prior artifact; it passed APK signature/archive checks, uses the debug key, reports package `com.stylewise.app`, and has SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`. D8 emitted Kotlin metadata/Appstore SDK warnings but both builds completed. Neither artifact was installed or run; SDK `adb` exists but reports no attached devices.
2. **Complete, secure Supabase backend** — schema proposal reconciled to read-only production metadata; execution/security proof pending
   - Inventory the app's tables, RPCs, Storage, Realtime and Edge Function contract.
   - Add forward-only migrations and local security fixtures.
   - Do not deploy `20261111090000_reconstruct_and_secure_backend.sql` yet: it is a local proposal revised against the recovered schema but still needs clean-chain SQL validation, fixture proofs and human review. Do not mutate the production project or its absent migration history.
3. **Functional application flows** — local code implementation complete; backend/device runtime proof pending
   - Authentication callbacks and onboarding.
   - User-scoped cache/state and correct offline/outage behavior.
   - Wardrobe, outfits, spending, insights, learning/challenges and export/deletion.
   - Account deletion/reset now removes Storage objects, checks failures, and paginates outfit-link cleanup; persistent wardrobe, onboarding, AI, and notification state is user-scoped. Outfit suggestions now send compressed local-image bytes instead of an inaccessible device path; the Edge Function validates payloads and no longer fetches arbitrary caller URLs. Reset pagination, image payload, and DST-safe reminder behavior have focused passing tests. The app/function image contract requires a coordinated future deploy.
4. **Uptodown RevenueCat Billing** — hosted-checkout source and sandbox isolation are implemented locally; provider setup, compatible backend deployment, and live verification remain pending
   - Release builds require the production hosted link, public Android SDK key, exact entitlement ID and production server environment. Google Play publishing is deferred. See `billing-readiness.md` for the exact historical/current price and quota findings.
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
