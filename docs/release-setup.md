# Local and Android release setup

## Pinned local toolchain

- Flutter `3.35.7` (`.fvmrc`), Dart `3.9.2`
- Java 21
- Android SDK/API 36 with the Android build tools required by Flutter
- Supabase CLI `3.1.0` for read-only production metadata inspection
- Deno `2.9.6` for local Edge Function type checks

Resolve dependencies with `flutter pub get`, then use `flutter analyze --no-pub`
and `flutter test --concurrency=1`. The repository CI runs those checks and
type-checks the protected Edge Functions. CI does not need provider credentials.

## App configuration

Builds receive public app configuration through Dart defines. Supply actual
values privately through the release environment; never commit an env file or
put server credentials in Dart defines.

```sh
flutter build appbundle --release --no-pub \
  --dart-define=SUPABASE_URL=<recovered-project-url> \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key> \
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
`REVENUECAT_WEBHOOK_SECRET`, and exact `REVENUECAT_ENTITLEMENT_ID`. Use the
provider's secret manager, never source files or client build arguments.
Check `supabase/functions/*/index.ts` before applying any deployment. A
deployment changes production and is outside this code-only recovery checkpoint.

## RevenueCat / Play verification still required

1. Confirm the Play application id is `com.stylewise.app` and register the same
   Android app in RevenueCat.
2. Configure the Play service account connection, subscription products,
   entitlement, offering/packages and webhook endpoint/authorization secret.
3. Add approved internal-track testers and license testers; install the app
   from the Play testing opt-in link rather than sideloading for purchase tests.
4. Test purchase, cancellation, restore, account switch, expiry/grace and
   duplicate/out-of-order webhook delivery with a tester account. Confirm the
   localized price shown in app matches Play and the backend records the exact
   entitlement. Do not claim success until the server verification and webhook
   outcome are confirmed.

Store release also needs reviewed privacy and account-deletion URLs, listing
artwork/screenshots, age/content/data-safety declarations, Play eligibility,
and valid private upload-signing inputs. None is inferred to be complete.
