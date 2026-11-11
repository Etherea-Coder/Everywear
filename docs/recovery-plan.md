# Android v1 recovery plan

Last updated: 2026-11-11

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

1. **Reproducible Flutter/Android build** — code complete, validation deferred
   - Pin Flutter 3.35.7 (Dart 3.9-compatible) in `.fvmrc`.
   - Track `pubspec.lock`; add the Flutter SDK `integration_test` dependency.
   - Resolve the duplicate Gradle DSL configuration without changing the active package identity (`com.stylewise.app`) until Play and RevenueCat registrations are confirmed.
   - Stale test sources and the generated Android registrant issue were repaired; reruns are deferred by the code-only recovery pass.
2. **Complete, secure Supabase backend** — implementation proposed; recovered-backend reconciliation required
   - Inventory the app's tables, RPCs, Storage, Realtime and Edge Function contract.
   - Add forward-only migrations and local security fixtures.
   - Do not deploy `20261111090000_reconstruct_and_secure_backend.sql` blindly. Compare it read-only with the recovered original project, then split/adjust it into forward-only changes that preserve hosted data and Storage.
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

- Read-only access or a schema-only dump from the recovered original Supabase project. The project must not be reset or replaced.
- Recovered project URL and publishable/anon key for the app build; service role and function secrets must stay server-side.
- RevenueCat public Android SDK key, exact paid entitlement identifier, and webhook authorization secret.
- Confirmation of the registered Android application ID in Play Console and RevenueCat.
- Private Android upload keystore and its passwords supplied outside Git.
- Docker installation/daemon access for a clean local Supabase stack.
