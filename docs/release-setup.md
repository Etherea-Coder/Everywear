# Local and Android release setup

## Pinned local toolchain

- Flutter `3.35.7` (`.fvmrc`), Dart `3.9.2`
- Java 21
- Android SDK/API 36 with the Android build tools required by Flutter
- Supabase CLI `3.1.0` for read-only production metadata inspection
- Deno `2.9.6` for local Edge Function type checks

Resolve dependencies with `flutter pub get`, then use
`flutter analyze --no-pub --no-fatal-infos --fatal-warnings` and
`flutter test --concurrency=1`. The analyzer gate keeps errors and warnings
fatal while allowing the current informational lint backlog. The repository CI
runs those checks and type-checks the protected Edge Functions. CI does not
need provider credentials.

## App configuration

Builds receive public app configuration through Dart defines. Supply actual
values privately through the release environment; never commit an env file or
put server credentials in Dart defines.

```sh
flutter build appbundle --release --no-pub \
  --dart-define=SUPABASE_URL=<recovered-project-url> \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key> \
  --dart-define=APP_DISTRIBUTION=uptodown \
  --dart-define=REVENUECAT_BILLING_ENVIRONMENT=production \
  --dart-define=REVENUECAT_WEB_PURCHASE_LINK_PRODUCTION=https://pay.rev.cat/<production-link-token> \
  --dart-define=REVENUECAT_ANDROID_API_KEY=<public-android-sdk-key> \
  --dart-define=REVENUECAT_ENTITLEMENT_ID=<exact-paid-entitlement> \
  --dart-define=SENTRY_DSN=<optional-client-dsn>
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, RevenueCat public SDK keys, the exact
entitlement identifier, and optional Sentry DSN are app configuration. The
Supabase service-role key, RevenueCat secret API key, webhook bearer secret,
and Gemini/OpenRouter keys belong only in the Edge Function environment.
Purchases remain unavailable in app builds without both the Android public
SDK key and exact entitlement ID.

Android release direction is Uptodown. `APP_DISTRIBUTION=uptodown`, the
production billing environment, and the production RevenueCat Web Purchase
Link are mandatory. The app accepts only an HTTPS `pay.rev.cat` link with a
single token path and appends the authenticated Supabase UUID. Do not put the
sandbox link in a release build. Non-release sandbox builds must use the
separate `REVENUECAT_WEB_PURCHASE_LINK_SANDBOX` define and
`REVENUECAT_BILLING_ENVIRONMENT=sandbox`; production builds reject sandbox.
Configure RevenueCat's success redirect as
`io.supabase.everywear://billing-return`. The callback only causes the app to
call the server verifier; it never grants entitlement. See
[`billing-readiness.md`](billing-readiness.md) for the catalog, webhook and
staging setup checklist.

## Android upload signing

The Android package identity remains `com.stylewise.app`. The build uses an
upload signing configuration only when the private, ignored file
`android/key.properties` exists:

```properties
storeFile=/absolute/private/path/upload-keystore.jks
keyAlias=<private-alias>
keyPassword=<private-password>
storePassword=<private-password>
```

Keep the keystore and passwords outside Git and secure backups. Without them,
the Android release output is unsigned and cannot be uploaded to Play.

Flutter 3.35.7 generates the dev-only integration-test plugin into the main
Android registrant, while its Gradle loader excludes that plugin from release
dependencies. A release source-set no-op shim bridges the generated reference
without bundling Android test libraries. A release AAB built successfully with
the shim and passed ZIP archive integrity inspection. The artifact is unsigned,
contains no Supabase/RevenueCat public build values, and has not been installed
or run on a device.

## Recovered Supabase and private images

The recovered production reference is `qxsdwwdrxoyxmnapuqqv`. Production stays
read-only during this recovery. The proposed migration and
`supabase/review/private-image-cutover.sql` are review material only. Before a
hosted rollout, reconcile them against a current metadata snapshot, back up the
project, validate against a non-production clone, convert exact legacy object
URLs to stable `bucket/path` references, and run anonymous/user-A/user-B and
concurrent-quota proofs. Ship and verify the compatible client first; change
the existing buckets to private only in an approved follow-on step. Rollback
must keep buckets private and owner policies in place. See
`recovered-supabase-reconciliation.md`.

The additive entitlement/quota migration must precede its dependent Edge
Function and app releases. Until then, client tier checks fail closed and show
the free tier. Keep the private-image cutover in a later rollout after the new
client is ready to resolve stable references.

## Edge Function environment and rollout

Required server-only values include Supabase's project URL, anon key and
service-role key; `GOOGLE_AI_API_KEY`; `OPENROUTER_API_KEY` for
`ai-suggestions`; and RevenueCat's `REVENUECAT_SECRET_KEY`,
`REVENUECAT_WEBHOOK_SECRET`, exact `REVENUECAT_ENTITLEMENT_ID`, and
`REVENUECAT_EXPECTED_ENVIRONMENT=production`. Use the
provider's secret manager, never source files or client build arguments.
Check `supabase/functions/*/index.ts` before applying any deployment. A
deployment changes production and is outside this code-only recovery checkpoint.

## RevenueCat Billing / Uptodown verification still required

1. Confirm Stripe activation and use RevenueCat Billing with Stripe as the
   payment gateway; Stripe Billing is a different integration.
2. Configure the RevenueCat Billing products, prices/currency, offering,
   production/sandbox links, success redirect and customer management. Set the
   exact paid entitlement and Android public SDK key.
3. Deploy the reviewed `verify-purchase` and RevenueCat webhook changes with
   `REVENUECAT_EXPECTED_ENVIRONMENT=production` only after the corresponding
   database migration is approved. Use a separate staging project/environment
   for sandbox validation.
4. Test purchase, browser cancellation/return, management portal, account
   switch, expiry/grace/refund, and duplicate/out-of-order webhook delivery
   with authorized Uptodown-distribution testers. Confirm the server records
   the exact entitlement. No live purchase has been performed.

Google Play publication and Play Billing verification are deferred.

Store release also needs reviewed privacy and account-deletion URLs, listing
artwork/screenshots, age/content/data-safety declarations, Play eligibility,
and valid private upload-signing inputs. None is inferred to be complete.
