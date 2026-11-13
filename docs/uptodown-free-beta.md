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
- Size: **197,317,047 bytes**
- SHA-256: `63e279122694cea641dace7bb963e642b9ebb777d03fdc97e0ee402ec7f2f73e`
- Identity: `com.stylewise.app`, version `1.0.0-beta.1`, code 2, target SDK 36
- Signing: Android Debug certificate, SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`;
  APK Signature Scheme v2 verified
- Archive check: `unzip -t` passed; `aapt dump badging` confirmed manifest;
  `apksigner verify --verbose --print-certs` passed.

This is a staging test APK for controlled installation only. It is not suitable
for public distribution and does not establish signing continuity. No physical
device is attached; install, cold-start, account isolation and core-flow
verification remain pending.

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
