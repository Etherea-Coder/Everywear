# Android v1 recovery plan

Last updated: 2026-11-13

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

1. **Reproducible Flutter/Android build** — toolchain pinned; historical unsigned bundle and current staging debug APK built. The staging APK passed archive, manifest, signature and SHA-256 checks. Physical-device validation and upload signing remain pending. Flutter selected Android Studio JBR 25.0.3 ahead of `JAVA_HOME`; configuring Flutter's JDK directory to Java 21 resolved the plugin-loader failure. The later one-worker staging build succeeded in 52.3 seconds with about 6.6 GiB available RAM while swap was full.
   - Pin Flutter 3.35.7 (Dart 3.9-compatible) in `.fvmrc`.
   - Track `pubspec.lock`; add the Flutter SDK `integration_test` dependency.
   - Resolve the duplicate Gradle DSL configuration without changing the active package identity (`com.stylewise.app`) until Play and RevenueCat registrations are confirmed.
   - Stale test sources were repaired; the complete sequential Flutter suite now passes 63 tests on current source commit `ca800ea`, including learning, challenge, and splash/auth recovery coverage. An earlier full-suite retry was interrupted under memory pressure, then later completed after pressure returned to zero. Focused image/billing/serialization/reminder tests passed 19/19; splash/auth/localization tests passed 5/5. Latest targeted Dart analysis reports no issues. The current-source project CI analyzer gate exited 0 with 244 informational diagnostics, no warnings or errors. Deno 2.9.6 CI-equivalent checks passed: 29 no-remote tests, lint over 25 files, and cached type-checks of all nine protected handlers. A Flutter CLI release AAB build succeeded after selecting JDK 21; without that selection Flutter chose Android Studio JBR 25.0.3 and Gradle failed before compilation. Current AAB from source commit `ca800ea`: `build/app/outputs/bundle/release/app-release.aab`, 76,421,600 bytes, SHA-256 `ac2409f9eed9a6b9f5cf89f3fde6fb9e7a90439b327499889b56cb8e34c02243`; archive integrity passed and `jarsigner` reports unsigned. CI commit `2a3dedd` installs Temurin 21, selects it for Flutter, then builds the AAB; remote CI has not run. Gradle is capped at one worker and 2 GiB heap. A debug APK is a prior artifact; it passed APK signature/archive checks, uses the debug key, reports package `com.stylewise.app`, and has SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`. D8 emitted Kotlin metadata/Appstore SDK warnings but both builds completed. Neither artifact was installed or run; SDK `adb` exists but reports no attached devices.
2. **Complete, secure Supabase backend** — schema proposal reconciled to read-only production metadata and deployed to the approved isolated staging project; exercised staging security/integration paths pass, production remains untouched
   - Inventory the app's tables, RPCs, Storage, Realtime and Edge Function contract.
   - Add forward-only migrations and local security fixtures.
   - All nine local migrations were applied in order to `aftdbphdobfrshienple`; eight JWT-protected functions are active there. Hosted synthetic Auth/PostgREST/quota checks passed 52/52, filtered Realtime 5/5, and private Storage/account-deletion checks 31/31. These do not validate production or all app/device flows. Never mutate production migration history.
3. **Functional application flows** — local implementation complete; selected service behaviors verified against staging; device/UI runtime proof pending
   - Authentication callbacks and onboarding.
   - User-scoped cache/state and correct offline/outage behavior.
   - Wardrobe, outfits, spending, insights, learning/challenges and export/deletion.
   - Account deletion/reset now removes Storage objects, checks failures, and paginates outfit-link cleanup; persistent wardrobe, onboarding, AI, and notification state is user-scoped. Outfit suggestions now send compressed local-image bytes instead of an inaccessible device path; the Edge Function validates payloads and no longer fetches arbitrary caller URLs. Reset pagination, image payload, and DST-safe reminder behavior have focused passing tests. The app/function image contract requires a coordinated future deploy.
4. **Uptodown RevenueCat Billing** — source is implemented, but payments are disabled for the free beta; provider setup and live paid verification remain pending
   - Release builds require the production hosted link, public Android SDK key, exact entitlement ID and production server environment. Google Play publishing is deferred. See `billing-readiness.md` for the exact historical/current price and quota findings.
   - Bind purchases to the Supabase UUID and harden server verification/webhooks.
5. **Android free-beta candidate** — staging backend is verified for tested flows and the connected debug APK is built. Physical-device validation is pending. Public signed distribution is not ready.
   - Accessibility, notifications/timezone, reporting opt-out and signing configuration.
   - Current AAB: `build/app/outputs/bundle/release/app-release.aab`, 76,959,486 bytes, SHA-256 `3797fdf52ccd8509a2d8a4ecec9bd35c7970553efdc2fdfe3d3078b1616ebb99`; archive integrity passed. It is unsigned and not device-tested. Private upload-signing inputs and app/provider configuration are also required.

## External inputs (only when dependent work reaches them)

- Recovered Supabase production access is available for read-only metadata/source inspection. Approved staging ref is `aftdbphdobfrshienple`; use explicit refs/worktrees for any further staging writes. Do not reset, replace, or mutate production.
- Recovered project URL and publishable/anon key for the app build; service role and function secrets must stay server-side.
- RevenueCat public Android SDK key, exact paid entitlement identifier, and webhook authorization secret.
- Confirmation of the registered Android application ID in Play Console and RevenueCat.
- Private Android upload keystore and its passwords supplied outside Git.
- A connected Android device and stable build-machine memory headroom for the remaining APK install/smoke check. Private upload-signing inputs and privacy/deletion/support URLs are needed only for public distribution.
