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

1. **Reproducible Flutter/Android build** — toolchain pinned, tests passed, analyzer attempted; bundle still blocked
   - Pin Flutter 3.35.7 (Dart 3.9-compatible) in `.fvmrc`.
   - Track `pubspec.lock`; add the Flutter SDK `integration_test` dependency.
   - Resolve the duplicate Gradle DSL configuration without changing the active package identity (`com.stylewise.app`) until Play and RevenueCat registrations are confirmed.
   - Stale test sources were repaired; current sequential suite passed 36 tests. Analyzer reported no errors but warned; reported warnings were corrected afterward without a repeat analyzer run. Two bundle attempts failed on the generated dev-only integration plugin reference; its release-only no-op shim compiled independently, but a retry remains deferred.
2. **Complete, secure Supabase backend** — local proposal reconciled to available metadata; execution/security proof pending
   - Inventory the app's tables, RPCs, Storage, Realtime and Edge Function contract.
   - Add forward-only migrations and local security fixtures.
   - Do not deploy `20261111090000_reconstruct_and_secure_backend.sql` yet: it is a local proposal revised against the recovered schema but still needs clean-chain SQL validation, fixture proofs and human review. Do not mutate the production project or its absent migration history.
3. **Functional application flows** — in progress
   - Authentication callbacks and onboarding.
   - User-scoped cache/state and correct offline/outage behavior.
   - Wardrobe, outfits, spending, insights, learning/challenges and export/deletion.
   - Account deletion/reset now removes Storage objects and checks failures; persistent wardrobe, onboarding, AI, and notification state is user-scoped.
4. **RevenueCat repair** — code complete; provider setup and live verification pending
   - Fail closed until a public Android SDK key and exact entitlement ID are supplied.
   - Bind purchases to the Supabase UUID and harden server verification/webhooks.
5. **Android release candidate** — pending validation and external inputs
   - Accessibility, notifications/timezone, reporting opt-out and signing configuration.
   - Signed AAB remains blocked until private upload-signing inputs are supplied.

## External inputs (only when dependent work reaches them)

- Recovered Supabase access is available for read-only metadata/source inspection. Do not reset, replace, or mutate the production project; use a schema-only clone/local harness for validation.
- Recovered project URL and publishable/anon key for the app build; service role and function secrets must stay server-side.
- RevenueCat public Android SDK key, exact paid entitlement identifier, and webhook authorization secret.
- Confirmation of the registered Android application ID in Play Console and RevenueCat.
- Private Android upload keystore and its passwords supplied outside Git.
- A non-production PostgreSQL/Supabase environment for clean-chain migration and identity/quota/Storage proofs. Docker is intentionally not started during this pass.
