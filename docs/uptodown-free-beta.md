# Uptodown free beta preparation

## Current gate

**Not ready to build or distribute.** The authenticated Supabase CLI lists the
Everywear production project (`qxsdwwdrxoyxmnapuqqv`) and an unrelated inactive
Clameo project in organization `ioohmyibnlzfltqcsnkg`. The CLI exposes project
identity but no billing plan, credit, or project-capacity metadata; its project
creation command has no zero-cost preview. This is not evidence that another
project is free. No new project has been created and no plan, add-on, or
billing setting has been changed. The exact blocker is owner access to
read-only organization billing/capacity metadata or an already-approved
isolated staging project. Until one is available, do not create a project or
connect a beta build.

The production app is not a safe beta backend: it still has the vulnerable
profile grants and old Edge Function versions documented in
[`recovered-supabase-reconciliation.md`](recovered-supabase-reconciliation.md).
Its buckets are public, quotas are not installed, and production is strictly
read-only in this recovery. Do not put production URL/keys into the beta or
copy production records. A staging project must receive the reviewed migration
chain and Edge Functions before a connected beta can be built.

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
the URL hostname matches the explicit staging ref, compiles a **debug-signed
APK**, and writes a project-labelled copy under ignored `build/beta-artifacts/`.
It performs no `supabase link`, hosted write, deployment, purchase, or ad call.
A debug APK is for controlled test devices only, not an Uptodown publication
artifact or signing-continuity proof. The helper has not been run because a
zero-cost staging project and config are not confirmed.

## Android identity, version and signing

- Keep Android application ID/namespace `com.stylewise.app`; do not change the
  identity without confirming existing store/provider registrations.
- The prior inspected AAB is unsigned, predates current source, and is not a
  release candidate. Do not reuse it as this beta.
- `android/key.properties` and an upload keystore are absent. Do not generate a
  replacement that could break signing continuity. The owner must privately
  locate and validate the existing signing key before a store-quality signed
  artifact can be produced.
- A staging debug APK is signed with the local Android debug key and cannot
  upgrade an Uptodown-signed install. Keep it on controlled test devices.
- Proposed beta version: `1.0.0-beta.1`, Android version code `2` (the previous
  local AAB used version code `1`). Increment the numeric code for each new
  artifact. Confirm no external release used this identity/version before
  distributing.

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

1. Owner provides read-only confirmation from Supabase organization billing
   metadata that an isolated project adds no cost, or an already-approved
   isolated staging project reference and private anon-key config. The
   authenticated CLI available here cannot expose billing/capacity fields.
2. If staging exists, use a separate working directory linked explicitly to
   its project ref; deploy the reviewed migrations/functions only there and run
   the two-user Auth/PostgREST/Storage/Realtime/quota checklist before building.
3. Supply the exact staging URL and anon key through a private mode-0600 JSON
   file outside the repository. Run the beta helper, review APK hash, then test
   it on a physical device. No test APK has been built yet.
4. Owner supplies existing upload-signing key access, privacy/deletion/support
   URLs, and approved listing artwork before public distribution.
