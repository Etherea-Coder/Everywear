# Billing readiness — Uptodown / RevenueCat Billing

Last updated: 2026-11-12

## Current commercial model found in this branch

| Item | Current source evidence | Status |
|---|---|---|
| Monthly price | The Play/native UI reads `Package.storeProduct.priceString` for `PackageType.monthly` in `lib/presentation/premium_upgrade/premium_upgrade.dart`; no amount is hardcoded on this branch. | Provider supplied; no RevenueCat/Play catalog was verified here. |
| Annual price | The Play/native UI reads `priceString` for `PackageType.annual` in the same file. | Provider supplied; no RevenueCat/Play catalog was verified here. |
| Historical €7.49 / €69.90 | Those values existed as hardcoded display strings in `f9c562f` (`premium_upgrade.dart`, lines 123 and 141). The later subscription repair replaced them with store-localized prices. Current `HEAD` contains neither amount. | Historical display text only, not evidence of current provider prices or approved commercial terms. |
| Currency | Native display uses RevenueCat's localized `priceString`. Hosted RevenueCat Billing displays the configured product price/currency. The `EUR` defaults in `purchase_service.dart` and `purchase_tracking.dart` apply to wardrobe spending budgets, not subscriptions. | No subscription currency is hardcoded or provider-verified. |
| Billing periods | UI labels monthly and yearly; native package selection uses `PackageType.monthly` and `PackageType.annual`. | The actual recurring interval and renewal terms come from the RevenueCat product configuration. |
| Product/package IDs | No Android product IDs, RevenueCat product IDs, or `$rc_monthly`/`$rc_annual` identifiers are hardcoded in current client code. Native product selection uses RevenueCat package types. Web Purchase Links use the configured offering; this client does not pass a `package_id`. | Exact IDs and linked offering are dashboard inputs and remain unknown. |
| Entitlement | Client reads `REVENUECAT_ENTITLEMENT_ID` in `lib/services/revenuecat_service.dart`; `verify-purchase` and `revenuecat-webhook` require the same server-side value. | Exact entitlement identifier is intentionally unset/unknown; purchasing stays disabled without it. |
| Trials / introductory offers | There is no client trial duration or introductory-price display logic. | Trial configuration is provider-owned and unverified; no trial is promised by this app source. |
| Tiers and limits | `lib/core/tier_limits.dart`: Essential = 30 saved outfit logs, 1 suggestion/day, 1 coach/week; Signature = 100 logs, 999 suggestions/day, 50 coach/month. Wardrobe item count is unlimited in both tiers (`itemsLimit` returns 999999). `supabase/migrations/20261111090000_reconstruct_and_secure_backend.sql` proposes row-locked outfit caps of 30/100 and atomic AI limits of 1/999 suggestions per day and 1/50 coaching turns per week/month. | These are local app/proposed-backend values, not proof that production currently enforces them. |
| Premium features shown | `lib/presentation/premium_upgrade/widgets/feature_comparison_widget.dart` advertises outfit history, daily suggestions, outfit swaps, AI coach, insights, cost-per-wear, unused-item detection and event styling. Some copy is hardcoded English and descriptive rather than a numeric allowance. | Keep review of feature copy and server enforcement in the release checklist. |

The recovered production metadata recorded in `docs/recovered-supabase-reconciliation.md` showed an `outfit_logs_count` counter but no outfit-log quota trigger. The local proposal corrects this with a row-locked 30/100 trigger and counter maintenance. The migration remains unvalidated and unapplied, so production does not yet have verified enforcement. The deployed suggestion RPC's live limit was not re-read during this pass. Do not infer production subscription prices, products, trial, entitlement or enforcement from source strings.

## Distribution and checkout implementation

- `lib/services/revenuecat_web_checkout.dart` supports only explicit `APP_DISTRIBUTION=uptodown` for hosted checkout. It selects a production URL only in a release build and a sandbox URL only in a non-release build.
- The configured base must be a single-path `https://pay.rev.cat/<token>` URL with no user info, port, query or fragment. The app appends the currently authenticated Supabase UUID as RevenueCat's App User ID. Checkout links or redirect destinations cannot be supplied dynamically.
- Android and iOS register `io.supabase.everywear://billing-return`. The RevenueCat dashboard success redirect must be set to that exact scheme; RevenueCat appends `app_user_id`. A matching return or application resume invokes the authenticated `verify-purchase` function and refreshes profile/tier providers. The app never trusts the callback as proof of payment.
- On each restored initial auth session and explicit sign-in, the app now quietly invokes the same server verifier and invalidates tier/profile state only for the still-current account. This supports fail-closed migration of existing profiles whose new `subscription_status` starts inactive. Token refresh does not trigger another provider request. This local client path still depends on deploying the protected verifier; current production function is not safe for this client behavior.
- Production and sandbox URL defines are separate. Release builds reject the sandbox selector. The server also requires `REVENUECAT_EXPECTED_ENVIRONMENT` and verifies RevenueCat's `is_sandbox` subscription field; webhook events with a different or missing environment do not change production entitlements. Use a separate non-production Supabase project and RevenueCat project for end-to-end sandbox verification.
- Subscription management reads the SDK's RevenueCat `managementURL` while identity is bound to the Supabase UUID and opens only recognized RevenueCat-hosted management origins. If the provider returns no supported URL, the UI reports it unavailable. RevenueCat Billing's customer portal is also linked from provider emails.
- Uptodown builds show provider-hosted subscription options instead of fabricated monthly/yearly prices. Missing app keys, entitlement, selected link, or unsupported distribution leaves checkout unavailable.

This matches RevenueCat's current documentation: RevenueCat Billing hosts checkout and uses Stripe as its payment gateway, while Stripe Billing is a separate billing engine. Web Purchase Links require the App User ID, offer distinct Production and Sandbox URLs, and can redirect to a registered custom app scheme. See [RevenueCat Billing configuration](https://www.revenuecat.com/docs/web/web-billing/configuring-overview), [Web Purchase Links](https://www.revenuecat.com/docs/web/web-billing/web-purchase-links), [subscription management URL](https://www.revenuecat.com/docs/subscription-guidance/managing-subscriptions), and [Customer Portal](https://www.revenuecat.com/docs/web/web-billing/customer-portal).

## Required public app configuration

Supply privately to the release build; values below are names, not credentials:

- `APP_DISTRIBUTION=uptodown`
- `REVENUECAT_BILLING_ENVIRONMENT=production`
- `REVENUECAT_WEB_PURCHASE_LINK_PRODUCTION=https://pay.rev.cat/<production-link-token>`
- `REVENUECAT_ANDROID_API_KEY=<public Android SDK key>`
- `REVENUECAT_ENTITLEMENT_ID=<exact configured paid entitlement>`
- Existing recovered-project `SUPABASE_URL` and `SUPABASE_ANON_KEY`

For a non-release sandbox build only, use `REVENUECAT_BILLING_ENVIRONMENT=sandbox` and `REVENUECAT_WEB_PURCHASE_LINK_SANDBOX=https://pay.rev.cat/<sandbox-link-token>`. Do not put that sandbox link in any release build. Use the provider's sandbox/test-mode controls and a staging backend for testing.

## Required provider/backend setup still pending

1. Confirm Stripe activation with the owner. In the existing RevenueCat project, enable **RevenueCat Billing** and connect Stripe as its payment gateway (do not select Stripe Billing unless intentionally changing the billing model).
2. Configure monthly/yearly RevenueCat Billing products, terms, localized pricing/currency, tax behavior, offering, and production/sandbox Web Purchase Links. Preserve any commercial terms the owner approves; the historical static euro values are not provider evidence.
3. Set the Web Purchase Link success behavior to `io.supabase.everywear://billing-return`, verify `app_user_id` is retained, and set the returning-customer behavior.
4. Supply the public Android SDK key and exact entitlement ID. Configure server secrets `REVENUECAT_SECRET_KEY`, `REVENUECAT_WEBHOOK_SECRET`, `REVENUECAT_ENTITLEMENT_ID`, and `REVENUECAT_EXPECTED_ENVIRONMENT=production` in the production Edge Function environment. The `verify-purchase` and webhook changes in this branch are not deployed.
5. Review and deploy the compatible additive database migration and Edge Functions only in the separately approved backend rollout. Production Supabase remains read-only in this work.
6. Configure RevenueCat Billing notifications/customer management, then test real Uptodown distribution with authorized testers. Verify purchase, restore/status refresh, cancellation through expiry, grace/billing issue, expiration, refund, account switch, and duplicate/out-of-order webhooks. No charge or purchase evidence exists yet.

## Current implementation limits

- Hosted web product prices are rendered by the RevenueCat page, not fetched into the app before browser launch. This avoids mismatching currency/localization and avoids claiming unconfigured prices; the app does not preselect a product/package.
- Web purchase launch is prepared, but it remains unavailable until public SDK/entitlement and a correct production link are built in. The backend expected-environment configuration and compatible Edge Function deployment are also required before any live transaction should be attempted.
- Current local production environment cannot be used to accept sandbox entitlements. Sandbox purchase verification requires an isolated staging backend/project; local sandbox UI alone is not a security boundary.

## Existing-account entitlement migration note

The recovered production profile has `subscription_expires_at` and
`revenue_cat_id`, but no `subscription_status`. The reviewed additive schema
sequence creates the missing status as `inactive`; it intentionally does not
infer active premium from legacy tier, future expiry, or user metadata. This
fails closed but can temporarily remove existing customers' premium access
until their authenticated account completes the exact-entitlement server
verification. Coordinate migration with a tested sign-in/refresh path in an
isolated staging project. The owner must confirm that this temporary downgrade
and revalidation sequence is acceptable, and whether to schedule a provider
snapshot reconciliation for current subscribers. Any reconciliation must use
verified RevenueCat data; do not backfill from expiry alone or accept client
claims. Production remains unchanged.
