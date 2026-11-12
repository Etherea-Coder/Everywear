# Advertising readiness

Last checked: 2026-11-12

## Direction and implementation state

Initial Android distribution is Uptodown. Monetag is the intended first ad
provider; RevenueCat Billing with Stripe remains the subscription path. There
is no Monetag or AdMob SDK/dependency, adapter, placement ID, test unit, or ad
traffic in the app. Ads are disabled by default and remain unavailable without
a matching configured adapter. Advertising revenue is modeled as zero.

`lib/services/ads/ad_service.dart` contains a provider-neutral selection
boundary for `disabled`, `monetag`, and future `admob`. AdMob is a future
selection only, not a working adapter. The coordinator requires explicit
granted consent, the authenticated account, a resumed lifecycle, a safe
content-break context, a server-profile entitlement result, a successful-
display frequency allowance, and no overlapping request. Verified premium or
future promotional access suppresses ads; unknown entitlement/account changes
fail closed. Only a displayed result consumes frequency. The injectable
default interstitial policy permits three successful displays per account in
24 hours, at least 15 minutes apart. Push, rewarded, banner, and app-open
formats are unsupported; rewarded AI allowance is not implemented.

No consent UI/provider or SDK lifecycle is wired into the app because no
verified SDK is available. Do not pass `granted` by default or enable an ad
provider until applicable consent disclosures/collection are wired and
reviewed.

## Official Monetag documentation

Monetag's [Android SDK article](https://monetag.com/blog/app-monetization-with-sdk-for-android-apps-apk/)
(updated 2024-11-03) says its Android SDK supports APK/Google Play distribution
and Flutter, and describes push notifications/interstitials plus an
account-generated integration flow. It does not establish public Flutter API
signatures, Android artifact coordinates/version, initialization/disposal,
callbacks, consent handling, or test-mode procedures.

The article's linked technical documentation at https://docs.inappi.co/
returned HTTP 502 on 2026-11-12. Accessible
[Monetag SDK docs](https://docs.monetag.com/docs/sdk-reference/) cover a
JavaScript SDK for Telegram Mini Apps; those instructions/packages are not
applicable to this native Flutter Android app and were not used. No unrelated
community package or guessed API was added.

## Owner/provider inputs before implementation

1. Monetag publisher approval for the app with **APK/Uptodown** distribution
   selected.
2. The account-generated supported Flutter/Android integration guide and
   artifact/version, including lifecycle, callbacks, consent/privacy behavior,
   and documented test facilities.
3. Approved placement/tag identifiers for the selected supported format, if
   required. Do not embed server secrets in the app.
4. Owner-approved consent handling and privacy disclosures for the SDK.
5. Staging/device verification for consent, premium suppression, account
   changes, frequency, and load/cancel/error paths.

Until those inputs are available, keep ads disabled. Do not infer revenue from
provider marketing claims or use unverified ad revenue to offset AI costs.

## Verification

Focused local tests cover provider selection/missing configuration, entitlement
classification and premium suppression, account-scoped frequency history,
consent and unsafe contexts, paused lifecycle, account switching during
entitlement lookup, failed/unavailable loads, frequency caps/cooldown,
overlapping requests, and adapter disposal. They do not verify a real SDK,
consent provider, Android device behavior, approval, test ads, or revenue.
