# Uptodown free beta preparation

## Current gate

**Staging backend and APK archive are verified; device beta check remains.** The owner
approved the isolated `Everywear-staging` project
(`aftdbphdobfrshienple`) in the existing Everywear organization; authenticated
CLI identity confirmed North EU/Stockholm and the owner confirmed Free-plan
status. All nine reviewed migrations and eight JWT-protected Edge Functions
are deployed there. Synthetic Auth/PostgREST, quota, private Storage, account
deletion, and filtered Realtime checks passed; exact counts and limits are in
[`staging-verification-checklist.md`](staging-verification-checklist.md).
Production Everywear remains read-only and unchanged. Use only the explicit
staging ref for beta configuration.

The owner has approved staging on the existing Free organization. The staging
backend now has the reviewed migration chain and relevant functions. Production
still has the recovered schema, public image buckets and older function
versions described in [`recovered-supabase-reconciliation.md`](recovered-supabase-reconciliation.md);
it remains read-only and must not be used by this beta. No production data,
keys or configuration were copied.

## Beta behavior and provider gates

- Uptodown is the distribution target. The beta has no offer or purchase flow.
  Compile with `EVERYWEAR_FREE_BETA=true`; this forces RevenueCat initialization
  and hosted checkout off even if someone supplies provider keys/links by
  mistake.
- Ads remain disabled (`EVERYWEAR_ADS_ENABLED=false`,
  `EVERYWEAR_AD_PROVIDER=disabled`). Monetag has no adapter and is not enabled.
  Future AdMob remains only an interchangeable provider selection.
- The free tier retains manual wardrobe entry, wardrobe browsing, deterministic
  outfit planning, outfit history and account features. AI remains subject to
  the authenticated server quota (currently proposed local defaults are 20
  actions/month, 3/day, one per UTC minute). A staging project without a
  configured provider must return the existing unavailable response; it must
  not fabricate analysis or block manual entry.
- The free beta must not include RevenueCat SDK keys/links, Stripe settings,
  creator/referral settings, ad IDs, Sentry DSN, or provider server secrets.
  Only the staging Supabase URL and anon key are read from a private config file.

The beta build helper is
[`scripts/build_uptodown_free_beta.sh`](../scripts/build_uptodown_free_beta.sh).
It refuses the recovered production project ref, requires a private JSON config
outside the checkout with exactly `SUPABASE_URL` and `SUPABASE_ANON_KEY`, checks
that the project ref is exactly the approved `aftdbphdobfrshienple` staging
ref and that the URL hostname matches it, compiles a **debug-signed APK**, and
writes a project-labelled copy under ignored `build/beta-artifacts/`.
It performs no `supabase link`, hosted write, deployment, purchase, or ad call.
A debug APK is for controlled test devices only, not an Uptodown publication
artifact or signing-continuity proof. The app now shows a visible `STAGING`
banner when the helper's compile define is set. A private mode-0600 staging
app config exists outside the checkout. The helper was run successfully after
selecting JDK 21 through Flutter's `jdk-dir` setting; that temporary setting
was cleared after the build.

## Built staging test APK

- Path:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`
- Rebuilt from `main` after the first-frame startup fix in commit `0cbf2ff` on
  2026-11-13 using the approved staging-only helper, project ref
  `aftdbphdobfrshienple`, purchases/ads disabled, and staging banner enabled.
- Build used Java 21, one Gradle worker and a 2 GiB Gradle heap. Flutter's
  temporary Java override was cleared afterward; default Android Studio JDK
  selection was restored.
- Size: **197,317,047 bytes**
- SHA-256: `91a61c5226695a1a99def3de69350c7aed3292698f5de9c1adfb93453028dbaa`
- Identity: `com.stylewise.app`, version `1.0.0-beta.1`, code 2, target SDK 36
- Signing: Android Debug certificate, SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`;
  APK Signature Scheme v2 verified
- Archive check: `unzip -t` passed; `aapt dump badging` confirmed manifest;
  `apksigner verify --verbose --print-certs` passed.
- The superseded APK was preserved outside Git at ignored
  `.tooling/recovery/Everywear-staging-before-startup-fix.apk`.

This is a staging test APK for controlled installation only. It is not suitable
for public distribution and does not establish signing continuity. No physical
device is attached; install, cold-start, account isolation and core-flow
verification remain pending. The source fix has not been verified on-device.

## Startup diagnostic APK

- Artifact:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-STARTUP-DIAGNOSTIC-debug.apk`
- Built once from current source using the same staging-only helper and staging
  configuration. The diagnostic define is opt-in with
  `EVERYWEAR_STARTUP_DIAGNOSTICS=true`; this diagnostic artifact keeps the
  Uptodown staging banner and has purchases/ads disabled.
- Size: **235,132,619 bytes**; SHA-256:
  `7817112fc1f1d7380f04b4e5fa6be86b9b9063df4e639cfb773bbcb70d2b0451`.
  ZIP integrity and APK Signature Scheme v2 verification passed. Package is
  `com.stylewise.app`, version `1.0.0-beta.1` (code 2), target SDK 36, signed
  with the Android Debug certificate whose SHA-256 is recorded above.
- The app UI uses a dark navy panel with an orange `EVERYWEAR • STAGING
  DIAGNOSTIC` badge. While starting it shows the current safe stage. Failures
  show only fixed stage names and exception class names; no exception message,
  configuration, token, or personal data is displayed. A 30-second startup
  timeout produces a visible timeout panel. Flutter framework and uncaught
  asynchronous errors are captured into the same sanitized state when possible.
- If the badge/panel appears, Flutter has drawn its first frame. If Android's
  launch logo is followed by black without the diagnostic badge, the failure is
  before the diagnostic widget was painted; this alone cannot distinguish
  Activity/plugin startup, Flutter engine/Dart entrypoint, or first-frame
  rendering. Do not interpret this build as proof the startup defect is fixed.
- Open the transfer folder from the repository root with
  `xdg-open build/beta-artifacts`.

## Engine-isolation APK

- Path:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-ENGINE-ISOLATION-debug.apk`
- This test target bypasses the normal app `main.dart`, service initialization,
  providers, Sentry, Supabase, and startup diagnostic wrappers. It directly
  renders a blue screen with **EVERYWEAR ENGINE TEST**. Its Android app label is
  **Everywear Engine Test (STAGING)**, making the APK identifiable in Android
  app info and the launcher. It retains package `com.stylewise.app` and the same
  debug certificate so installing it as an update should preserve app data.
- Size: **197,317,047 bytes**; SHA-256:
  `5a51428a8f8793adfdd7afde71f54ec269dbbbccfccd5441f68180f80e4a119e`.
  Archive and signature checks passed. It is a staging-only debug test, not a
  release artifact.
- If the blue screen appears, the platform can launch Flutter and draw a Dart
  first frame; investigate the regular `main.dart` entrypoint and its startup
  path next. If the label is installed but opening it still shows the native
  logo/white screen, the failure is below the application services, though the
  exact native/engine/first-frame cause still needs device logs. This test does
  not exercise sign-in, staging backend access, or application features.

## Controlled startup-stage probe

The owner reports that the engine-isolation APK displays its blue screen on the
phone. That establishes that the minimal target reaches a Flutter first frame
on this device. It does not establish which omitted normal-app component fails.
The normal source calls `runApp` before awaiting service futures and keeps
binding setup and `runApp` in the same guarded zone, so the exact cause remains
unknown.

The new diagnostic target paints its own orange shell before it loads the
deferred application library. The app label is **Everywear Startup Probe
(STAGING)**. Its button advances through: load app library; initialize
reporting; initialize staging Supabase; initialize Hive; construct the
ProviderScope/MyApp root; mount it and draw its first frame; observe the app
startup stage for 30 seconds. The orange shell remains around the application
while it loads. Any displayed failure is limited to an exception class and a
safe `package:`/`dart:` source location; no raw exception, config or account
data is shown. The final observation stage lets MyApp's preference loading,
optional settings and initial AuthGate routing proceed while the probe shell
continues to show the current internal startup stage.

Install this artifact as an update over Everywear; do not uninstall or clear
app data. It keeps package `com.stylewise.app` and the Android Debug certificate
used by the engine-isolation APK. First confirm the Android app label says
**Everywear Startup Probe (STAGING)**. On launch, the orange shell should
appear before any stage runs. Tap `Run next stage` for each stage and record
the last visible stage and any sanitized failure. If the shell does not appear,
first verify that this labelled APK was installed and launched; without device
logs, that result still does not identify the native/engine/entrypoint failure.

- APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-STARTUP-STAGE-PROBE-debug.apk`
- Size: **235,145,437 bytes**; SHA-256:
  `984b69066534a3c852a0efd9b204ff4424bc8bbc9bf16d3c7ede0aba2424a6b1`
- ZIP integrity and APK Signature Scheme v2 passed. Package/version are
  `com.stylewise.app`, `1.0.0-beta.1` (code 2), target SDK 36. The app label is
  verified as above. Debug certificate SHA-256:
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
- Built once with the approved staging helper/ref, staging banner enabled,
  purchases and ads disabled, Java 21, one Gradle worker and a 2 GiB heap.
  Build archive/signature checks do not prove runtime behavior. This is a
  diagnostic staging APK, not suitable for public distribution.

A separate local-only compile was attempted with free-beta gates enabled and
Supabase/provider defines explicitly empty. Flutter first selected Android
Studio JBR 25.0.3 and stopped before compilation. A second attempt temporarily
selected Java 21 and an isolated build directory, then was interrupted after
available memory fell to about 4.4 GiB and swap filled. The temporary Flutter
settings were restored, the build-owned Gradle daemon was stopped, and the old
APK was preserved under ignored `build/beta-artifacts/`. No new APK was
produced in those earlier attempts and no runtime behavior was tested then. A
later staging-configured build succeeded after selecting Java 21 through
Flutter's `jdk-dir` setting; its verified artifact is listed above. The
temporary JDK setting was cleared after the successful build. Flutter selects
Android Studio's JDK ahead of `JAVA_HOME` on this machine, so `JAVA_HOME` alone
does not override its JDK selection.

## Android identity, version and signing

- Keep Android application ID/namespace `com.stylewise.app`; do not change the
  identity without confirming existing store/provider registrations.
- The prior inspected AAB is unsigned, predates current source, and is not a
  release candidate. Do not reuse it as this beta.
- The existing `build/app/outputs/flutter-apk/app-debug.apk` was inspected with
  Android `aapt`: it is `com.stylewise.app`, version `1.0.0`, version code `1`,
  SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`.
  This is the older pre-beta APK, not a staging artifact; do not distribute it.
- `android/key.properties` and an upload keystore are absent. Do not generate a
  replacement that could break signing continuity. The owner must privately
  locate and validate the existing signing key before a store-quality signed
  artifact can be produced.
- A staging debug APK is signed with the local Android debug key and cannot
  upgrade an Uptodown-signed install. Keep it on controlled test devices.
- Proposed beta version: `1.0.0-beta.1`, Android version code `2` (the previous
  local AAB and existing debug APK use version code `1`). Increment the numeric
  code for each new artifact. Confirm no external release used this
  identity/version before distributing.

## Draft listing copy

**Short description**

> Organize your wardrobe, save outfit ideas, and track what you wear.

**Long description**

> Everywear helps you keep a digital wardrobe, record outfits, and review your
> clothing and purchases in one place. Add items manually, browse your saved
> pieces, plan outfits, and track wear history. This early beta is free to use.
> AI-assisted features may be unavailable or limited while the beta is being
> prepared. Paid subscriptions and advertising are not included in this beta.

Do not claim automatic image analysis, unlimited AI, private image storage,
verified subscription recovery, offline synchronization, or secure deletion
until those behaviors have passed staging/device verification. Provide the
actual privacy, account-deletion, support, and data-retention URLs before public
listing; they remain owner inputs.

## Draft release notes

> First controlled free beta for Uptodown testing. Organize wardrobe items,
save outfits, and track outfit history. AI features may be temporarily
unavailable. Purchases and ads are disabled. Please report crashes and data
sync issues to the test coordinator.

## Physical-device smoke test

Run only against the verified staging project with synthetic accounts and
objects. Record device model, Android version, APK hash, project ref, and tester
account label (never passwords/tokens).

1. Install, cold-start, background/resume, rotate text scaling, and confirm no
   purchase/ad SDK starts or blocks startup.
2. Create and confirm user A, restore a session after force-stop, edit profile
   and onboarding preferences, sign out, then repeat with user B.
3. Add wardrobe items manually, upload/display/replace/delete a photo, save and
   edit an outfit, browse history, export, and verify unavailable AI leaves
   manual entry usable.
4. Verify user B cannot see user A's rows/images. Test a failed network request
   and retry; errors must not appear as empty data or successful saves.
5. Request account deletion and verify profile, user rows, and Storage objects
   disappear; a simulated cleanup failure must not report success.
6. Confirm AI quota remaining/exhausted/unavailable states match server
   responses, and no checkout, ads, paid inference, or production endpoint is
   contacted.

## Exact next actions

1. Install the built APK on an owner-provided physical Android device and run
   the smoke checklist above. Record device model, OS version, tester label,
   APK hash and staging ref. Do not use production accounts or data.
2. The outside-repository service-role test config was removed after hosted
   checks. Keep only the mode-0600 staging URL/anon-key config for the helper;
   never commit it.
3. Owner supplies existing upload-signing key access, privacy/deletion/support
   URLs, and approved listing artwork before public distribution. Keep the
   existing application ID and signing continuity intact.
