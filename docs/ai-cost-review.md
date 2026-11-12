# Everywear AI cost and subscription price review

**Checked:** 2026-11-12

**Purpose:** planning review for proposed €2.99 monthly and €24.99 annual
subscriptions. No price, model, quota, app behavior, or provider configuration
was changed. No paid API request or production mutation was made.

## Executive assessment

At the published Gemini 2.5 Flash-Lite standard rates, modeled ordinary AI
usage is a small variable cost: approximately **$0.009/month** for the light
example, **$0.038/month** for typical paid use, and **$0.12/month** for the
heavy example below. These estimates are conditional, not observed bills. They
exclude retries outside source, unbounded prompt growth, provider/model changes,
FX, tax, hosting allocation, support, refunds, and payment disputes.

**The AI token bill alone does not make either proposed price look untenable.**
The annual offer is materially discounted (about 30.4% versus twelve monthly
payments), and its effective gross is €2.0825/month before deductions. Stripe's
fixed per-payment component takes a larger share of €2.99 monthly billing.
At low subscriber counts, shared Supabase compute and fixed operating costs
matter more than the modeled per-user AI bill. Therefore these prices look
plausible for a capped, measured launch, but overall sustainability is not
proven.

There are launch blockers before creating products:

1. The deployed/source OpenRouter call uses model ID `gemini-2.5-flash-lite`
   instead of OpenRouter's canonical `google/gemini-2.5-flash-lite`; its model
   page says it was going away on 2026-10-20. Do not assume image outfit advice
   currently works.
2. Source AI functions are hardcoded to Gemini 2.5 Flash-Lite, while Google
   currently says access to 2.5 models is limited to projects that actively
   used them before and recommends newer models for new projects.
3. The local quota migration is only a proposal. Recovered production source
   has no atomic quota call in its interactive model functions, so production
   currently has no verified per-account AI cap.
4. The proposed Signature allowance of 999 suggestion operations/day is
   effectively uncapped. Request input is not consistently bounded, and
   passive coach generation consumes the same coaching allowance as a customer
   action.

Do not create paid offers or advertise “unlimited AI” until the serving model,
backend-enforced limits, payment/tax treatment, and cost telemetry are resolved.

## AI integrations found in source

| Feature | Client path and backend | Provider/model in local source | Request bounds and controls |
|---|---|---|---|
| Clothing item/image analysis | `VisionEngineServiceMobile` sends one JPEG as base64 to `analyze-clothing`; Edge Function calls Google `generativelanguage.googleapis.com/v1beta/models/...:generateContent` with `GOOGLE_AI_API_KEY`. Web uses a local heuristic; mobile falls back to static basic analysis when remote analysis fails. | **Gemini Developer API**, hardcoded `gemini-2.5-flash-lite`; not Vertex AI. No model override or alternate provider/model. | Camera/gallery is initially limited to 1920×1920 at quality 85 and then recompressed at quality 80 (without a second dimension bound). Edge accepts up to 10,000,000 base64 characters (about 7.5 MB decoded), one image, max 200 output tokens, temperature 0.1. No explicit thinking budget, retry, cache, batch, or provider fallback. A quota is consumed before the model call in local source. |
| Outfit-photo suggestions | `AiSuggestionsService` compresses an image and calls `ai-suggestions`; function posts an OpenAI-compatible multimodal chat request to OpenRouter using `OPENROUTER_API_KEY`. | **OpenRouter**, model field currently `gemini-2.5-flash-lite`. OpenRouter's canonical ID is `google/gemini-2.5-flash-lite`; its page currently marks that model “Going away October 20, 2026.” No explicit alternative model/fallback list in request. | Client rejects originals over 20 MiB, recompresses to max 1280×1280 at JPEG quality 75, and caps encoded bytes at 3 MB. Edge caps base64 text at 4,000,000 characters and bounds profile fields to 500 characters and name to 80. One image; max 500 output tokens; temperature 0.1. No explicit thinking, request retry, or response cache. Quota is consumed before model call in local source. |
| Today's outfit suggestion | `TodaySuggestionService` calls `today-suggestion`; the function authenticates, reads the user's wardrobe under RLS, then calls Google GenerateContent with `GOOGLE_AI_API_KEY`. | **Gemini Developer API**, hardcoded `gemini-2.5-flash-lite`. No model override or alternate model. | Text-only prompt includes wardrobe rows, recent items, profile, event, weather and habits. Output cap 600 tokens, temperature 0.7. No request-body or wardrobe-row/token cap is visible in this function. No cache or retry. The daily-log screen starts this call automatically on load and can call again from UI actions; a local in-flight flag only covers one widget instance. |
| Style coach | Passive, active and event methods in `StyleService` call `style-coach`; function authenticates and calls Google GenerateContent with `GOOGLE_AI_API_KEY`. | **Gemini Developer API**, hardcoded `gemini-2.5-flash-lite`. No model override or alternate model. | Text-only prompts include profile, aggregate wardrobe data, recent outfits, patterns, ratings, silhouette history and/or question/event. Output cap 400 tokens, temperature 0.7. The Edge Function has no visible body-size or input-token cap. No cache or retry. Passive coaching is automatically requested when the Smart Suggestions screen loads and spends the same coach quota as active/event requests. |
| AI insights | `AIIntelligenceService` calls `generate-ai-insights`; function authenticates, reads wardrobe/outfit/quiz data, and calls Google GenerateContent with `GOOGLE_AI_API_KEY`. | **Gemini Developer API**, hardcoded `gemini-2.5-flash-lite`. No model override or alternate model. | Text-only prompt summarizes wardrobe, logs and quiz data; output cap 800 tokens, temperature 0.4. Database reads and prompt input have no clear row/token cap. Client caches successful results in memory for 30 minutes per user/range/category, but force-refresh, filter changes, app restart, and concurrent cache misses can issue additional calls. Server quota is consumed before JSON/body validation and data fetches, so failures can spend quota without a result. |
| Other apparent AI features | `StylistEngineService` and `InsightsDashboard` compute deterministic local suggestions/metrics; `CloudVisionService` is a connectivity utility, not a provider SDK. | No external model call found in these paths. | No provider token cost. Do not count deterministic suggestions as model usage. |

Source references: `lib/services/ai/vision_engine_service.dart`; `lib/presentation/add_clothing_item/widgets/photo_capture_section.dart:121-162`; `lib/services/ai_suggestions_service.dart:20-82`; `lib/services/ai_image_payload.dart`; `lib/presentation/outfit_capture_flow/outfit_capture_flow.dart:323`; `lib/services/today_suggestion_service.dart:12-117`; `lib/presentation/daily_log/daily_log.dart:199,376`; `lib/services/style_service.dart:254-391`; `lib/presentation/smart_suggestions/smart_suggestions.dart:60-89`; `lib/services/ai_intelligence_service.dart:20-72`; `lib/presentation/ai_intelligence/ai_intelligence.dart:52-92`; `lib/services/ai/stylist_engine_service.dart`; `lib/services/ai/cloud_vision_service.dart`; `lib/core/tier_limits.dart:6-40`; `supabase/functions/analyze-clothing/index.ts:8,62-95` and `clothing_analysis.ts`; `ai-suggestions/index.ts:4-5,60-64,135-160` and `request_validation.ts`; `today-suggestion/index.ts:5,83-84,224-226`; `style-coach/index.ts:6,72-76,233-235`; `generate-ai-insights/index.ts:27,69-73,246-247,312-314`; `_shared/gemini_request.ts`; `supabase/migrations/20261111090000_reconstruct_and_secure_backend.sql:343-386`.

### Configured versus deployed

- Local source and the read-only production Edge Function snapshot both show
  Gemini 2.5 Flash-Lite in the four Google GenerateContent functions and the
  same OpenRouter model field in `ai-suggestions`. The snapshot is preserved in
  ignored `.tooling/recovery/remote-functions-project/`; source was inspected,
  not copied over working files.
- The Google direct API is established by the `generativelanguage.googleapis.com`
  endpoint and `x-goog-api-key` header. The `GOOGLE_AI_API_KEY` value is a
  server environment input; its provider project, tier, quota, billing status,
  and key validity were not inspected. Values were not retrieved.
- `OPENROUTER_API_KEY` is also a server environment input. The deployed source
  identifies the intended provider but does not establish whether the secret
  exists, has credits, or can route the requested model. The caller's model ID
  lacks the canonical OpenRouter provider prefix. No provider request was
  attempted.
- No model ID is configurable through Dart defines or server environment in
  the inspected source. The model constants are code literals. No source
  fallback model is configured. Gemini 2.5 Flash-Lite's own documented default
  is no thinking; source does not set `thinkingBudget` or OpenRouter reasoning
  parameters. All model-backed functions set explicit output caps. No function
  implements an explicit retry or model failover.
- No AI provider key is shipped in Flutter code. Clients call authenticated
  Supabase Edge Functions; source scans found no direct client Gemini/OpenRouter
  request or client-side provider credential.
- Source is not proof of what currently runs or can be billed at runtime. In
  particular, production server secret values, provider billing tiers, model
  availability to those accounts, and current live token usage remain unknown.

## Limits, enforcement, and request risks

`lib/core/tier_limits.dart` sets Essential to **1 shared suggestion operation
per day**, **1 coach operation per week**, and 30 outfit logs; Signature is
**999 suggestion operations per day**, **50 coach operations per month**, and
100 outfit logs. Wardrobe items are effectively unlimited. The local
`consume_ai_quota` proposal in
`supabase/migrations/20261111090000_reconstruct_and_secure_backend.sql`
row-locks the profile, shares the suggestion counter across clothing analysis,
photo suggestions, daily suggestions and AI insights, and applies the same
1/999 daily plus 1/50-per-period coach limits.

Those limits are **not verified in recovered production**. The local migration
has not been applied; `docs/recovered-supabase-reconciliation.md` records that
deployed interactive AI functions do not call `consume_ai_quota`. The legacy
production counter RPCs/grants were also found unsafe. UI quota checks are not
a substitute for a protected atomic server check.

Additional cost-control findings:

- `generate-ai-insights` spends a suggestion operation before it parses JSON
  or loads data. A malformed request or backend failure can consume allowance.
- `today-suggestion` reads all owned wardrobe rows without a server-side row
  cap and interpolates them into the prompt. `style-coach` accepts a client
  JSON body without a total size or token cap. Both can be called directly by
  any authenticated user, outside the app UI.
- `ai-suggestions` bounds image and selected profile fields, but does not set an
  OpenRouter provider constraint/fallback or retry. The API call may fail after
  quota has been spent.
- There is no server idempotency key or duplicate-request suppression for AI
  calls. UI loading flags and the insights memory cache are local conveniences,
  not usage security. Parallel clients can make parallel requests; only the
  proposed row-locked quota would serialize the counter, and it is not deployed.
- Passive coaching runs automatically on screen entry and counts against the
  weekly/50 monthly coaching quota. This can use a free user's only weekly
  coach allowance without an explicit coach question.
- Client messages and premium copy are inconsistent: `lib/core/utils/
  app_localizations_en.dart` says free users can get “unlimited coaching”,
  while source quota is 50/month for Signature. The 999/day suggestion limit
  is also described in code as “effectively unlimited”. Do not advertise
  unlimited model usage.
- No Gemini or OpenRouter calls use Google Search/Maps grounding, audio, video,
  image generation, batch, or context caching in inspected requests. Their
  associated prices are therefore excluded from these projections.

## Provider pricing checked on 2026-11-12

### Gemini Developer API (the direct Google integration in source)

Google's [Gemini API pricing page](https://ai.google.dev/gemini-api/docs/pricing)
lists Gemini 2.5 Flash-Lite Standard paid rates at **$0.10 / 1M input tokens**
(text/image/video) and **$0.40 / 1M output tokens**, including thinking tokens.
Its free tier lists these token prices as free, but marks free-tier content as
used to improve Google's products; the paid tier says it is not. For users
sending personal wardrobe images, do not build production economics or privacy
promises on the free tier. Context caching is not available as a discounted
token input tier; the listed cache storage rate is $1 / 1M tokens/hour.

The [image understanding/token documentation](https://ai.google.dev/gemini-api/docs/tokens)
says an image no larger than 384×384 counts as 258 tokens; larger images are
processed as 768×768 tiles of 258 tokens each. Image token count depends on
dimensions/tiling, not JPEG byte size alone. A 1920×1920 image may therefore
be roughly nine tiles (2,322 input tokens) before text, depending on actual
image sizing/resolution behavior. The app does not log Gemini token usage, so
this is an estimate. The [thinking guide](https://ai.google.dev/gemini-api/docs/generate-content/thinking)
describes 2.5 Flash-Lite as a model that does not think by default; its
generation configuration can disable thinking explicitly. The source sets no
thinking budget. Output-token caps still bound the output charge.

Google's [model availability page](https://ai.google.dev/gemini-api/docs/models)
states the 2.5 models are not deprecated but access is being limited to
projects that actively used them, and recommends newer models for new projects.
This makes model/key eligibility an external blocker even though a stable model
ID is in source.

### OpenRouter path

OpenRouter's official [Gemini 2.5 Flash-Lite catalog page](https://openrouter.ai/google/gemini-2.5-flash-lite)
lists the canonical ID `google/gemini-2.5-flash-lite`, currently listed rates
of **$0.10 / 1M input and $0.40 / 1M output**, and labels the model as going
away on **2026-10-20**. The checked date is later. The source's bare model ID
is not the documented canonical slug and the catalog entry's retirement date
has passed. Cost projections for photo outfit advice are only a same-price
proxy, not a confirmed payable route. Provider pricing/routing can vary, and
the current request does not set a provider preference or fallback list.

The direct Google URL in four features uses the **Gemini Developer API**. It
does not use Vertex AI's endpoint/credentials. Vertex AI is a distinct product
and has its own [Google Cloud pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing);
those rates are not applied to the current direct API calls. OpenRouter may
route to Google AI Studio or Vertex providers, so exact underlying provider is
unknown for that code path.

## Per-request cost assumptions

These are deliberately simple list-rate estimates, not measured token counts.
They use $0.10/M input + $0.40/M output, no caching, no paid grounding, and no
retry. Inputs below include image tokens where applicable.

| Request type | Assumed input tokens | Assumed output tokens | Estimated model cost/request |
|---|---:|---:|---:|
| Clothing analysis (one resized image + small JSON prompt) | 2,500 | 200 | $0.00033 |
| Outfit-photo suggestions (one 1280px image + short prompt) | 5,000 | 500 | $0.00070* |
| Today's suggestion (typical wardrobe and context) | 8,000 | 600 | $0.00104 |
| Coach turn (profile and bounded recent context assumption) | 6,000 | 400 | $0.00076 |
| AI insights (typical summary prompt) | 10,000 | 800 | $0.00132 |

Formula: `input_tokens × $0.10 / 1,000,000 + output_tokens × $0.40 /
1,000,000`. `*` Outfit suggestions use OpenRouter's currently published model
price only as a planning proxy; source ID/retirement prevents claiming this
route works.

No token-count data was available for live Everywear users. Real inputs may be
larger: the prompt data has no consistent cap and wardrobe size is unlimited.
Input estimates are therefore not upper bounds.

## Subscriber usage scenarios

| Scenario/month | Feature mix assumed | Relation to local proposed limits | Estimated AI provider cost |
|---|---|---|---:|
| Light (free) | 4 clothing analyses + 5 daily suggestions + 1 AI insight + 1 coach | 10 of roughly 28–31 free shared suggestion operations/month; 1 of about 4–5 weekly coach allowances | **$0.0086** |
| Typical (paid) | 12 clothing analyses + 20 daily suggestions + 4 outfit-photo suggestions + 10 coach turns + 2 AI insights | 38 suggestion operations/month versus proposed 999/day; 10/50 coach operations | **$0.0378** |
| Heavy (paid) | 50 clothing analyses + 30 daily suggestions + 20 outfit-photo suggestions + 50 coach turns + 15 AI insights | 115 suggestion operations/month versus proposed 999/day; all 50 coach operations | **$0.1195** |

The model quota categories do not currently correspond cleanly to the UI's
feature labels: photo analysis, photo advice, daily looks, and insights all
spend the same suggestion counter. Scenarios assume every request succeeds
once and consumes one unit. They omit the passively generated coach tip count
unless included in the coach-turn totals.

The 999/day Signature suggestion limit is not a practical safety cap. At the
assumed typical daily-suggestion cost of $0.00104, 999 calls/day for 30 days
would cost about **$31.17 for one account in a month** before coach use. This
illustrative figure does not bound high-input prompts; a malicious or
unusually large wardrobe/prompt can exceed the assumed unit cost. Rate limits
and prompt-size bounds are needed even if ordinary users stay far below that
volume.

## Payment, tax, and hosting context

### Stripe and RevenueCat Billing

RevenueCat's [Billing overview](https://www.revenuecat.com/docs/web/web-billing/overview)
says RevenueCat Billing uses Stripe as the payment gateway, that RevenueCat
Web is included in RevenueCat's plan, and quotes **US pricing** of 2.9% + $0.30
per Stripe transaction. That US quote is not an exact fee for a EUR merchant.
Stripe's current [France pricing page](https://stripe.com/fr/pricing) lists
**1.5% + €0.25** for standard EEA cards (and different prices for UK,
international, premium, currency-conversion, and other payment cases). This
table uses only that EEA standard-card scenario, not an assumption about the
owner's country, Stripe contract, card mix, or currency settlement.

| Proposed price | Gross listed price | EEA standard-card fee scenario | After fee, before tax/hosting/AI |
|---|---:|---:|---:|
| Monthly | €2.99 | €0.29485 | €2.69515 |
| Annual | €24.99 | €0.62485 once per year | €24.36515/year = €2.03043/month equivalent |

The annual price is about **30.35% below** twelve monthly payments (€35.88).
Annual effective gross is €2.0825/month before processing; after the example
Stripe transaction fee it is about €2.03/month before tax and all other costs.

RevenueCat's [current public Pro pricing](https://www.revenuecat.com/pricing)
is free below $2,500 Monthly Tracked Revenue and 1% of MTR in months above
that threshold. RevenueCat's [billing explanation](https://www.revenuecat.com/docs/welcome/set-up-revenuecat/account-management)
says the 1% applies to the full MTR, before store fees and taxes, once the
threshold is exceeded. It also says RevenueCat Billing itself adds no separate
RevenueCat web fee. The recovered project's actual RevenueCat plan/legacy
terms are unknown; verify before relying on this public schedule.

### Tax sensitivity

Tax treatment is not known. As a purely illustrative calculation, if the
listed consumer price includes 20% VAT, the price is divided by 1.20 to
separate VAT; Stripe's fee is still calculated on the gross charge in this
example:

| Price | Gross | Illustrative VAT component at 20% | EEA fee scenario | Remainder after VAT and fee |
|---|---:|---:|---:|---:|
| Monthly | €2.99 | €0.49833 | €0.29485 | €2.19682/month |
| Annual | €24.99 | €4.16500 | €0.62485 | €20.20015/year = €1.68335/month equivalent |

20% is an example, not an asserted applicable rate. The [European Commission
place-of-taxation guidance](https://taxation-customs.ec.europa.eu/taxation/vat/vat-directive/place-taxation_en)
states B2C electronic services are generally taxed where the customer resides,
with a cross-border €10,000 threshold exception for certain EU-established
suppliers. Merchant establishment, VAT registration, threshold, customer mix,
whether prices are tax-inclusive, and tax collection configuration all remain
unknown. RevenueCat Billing can use Stripe Tax or Avalara; verify selected
provider and contract. RevenueCat's overview quotes US Stripe Tax at $0.50 per
transaction, while current Stripe documentation describes 0.5% PAYG for some
no-code Stripe Tax transactions. This pricing/plan difference must be resolved
for the actual account; neither tax-provider fee is included above.

### Supabase and image hosting

Supabase's [public pricing](https://supabase.com/pricing) currently lists Pro
from **$25/month**, 100 GB file storage, 250 GB uncached/cached egress, and
included Edge Function invocation allowance; overages and compute can add
charges. Current published usage docs list storage overage at $0.0213/GB-month,
uncached egress at $0.09/GB, cached egress at $0.03/GB, and 2 million Pro Edge
Function invocations included. The recovered organization's actual plan,
compute size, included credits, storage volume, image sizes, egress, and current
invoice were not inspected. Do not allocate a precise per-subscriber platform
cost without these measurements. For scale context only, a $25/month Pro
baseline allocated over 100 subscribers is $0.25/subscriber/month; over 1,000
it is $0.025, before compute and overages. This is a shared fixed-cost example,
not the project's confirmed bill.

Supabase hosts customer wardrobe/avatar images; private-image code does not
remove Storage, CDN/egress, database, or backup costs. Image transforms are not
currently charged as model calls but may have their own plan usage charge if
introduced.

## Launch configuration recommendation (review only)

1. **Do not promise unlimited AI.** Keep Essential at one server-enforced AI
   operation per day shared across model-backed features during initial
   measurement. This is useful enough for evaluation and is already the local
   proposal, but it is not enforced in recovered production. Avoid having an
   automatic passive coach consume a free user's explicit weekly coach action;
   cache/precompute it or make it user-triggered before launch.
2. **Replace Signature 999/day with a measured finite allowance.** A cautious
   initial proposal is 10 AI operations/day shared across suggestion/image/
   insights features and 30 coach turns/month. Set server-side maximum request
   bytes and a target prompt input budget (for example 12k tokens, validated by
   measuring real prompts); cap rows/items passed into prompts and retain
   current per-feature output caps. The 10/day and 30/month values are review
   proposals, not finalized commercial terms.
3. Enforce quota atomically in protected functions before each billable request,
   with idempotency/in-flight deduplication where retries can duplicate calls.
   Validate request size and required data before spending quota. Production
   rollout needs schema review and verified migration/deployment; do not rely on
   client counters or UI guards.
4. Resolve the OpenRouter model ID/retirement and confirm Google Developer API
   key access to a supported paid tier. Use paid processing for personal
   wardrobe images if the product requires the provider not to use prompts for
   product improvement; document the data path and retention accurately.
5. Instrument per-feature request counts, token usage, provider/model,
   failures, duplicate requests, and cost per active subscriber. Recheck the
   scenarios after a representative private beta and then adjust quotas/price.
6. Confirm Stripe's merchant-country/card/currency schedule, VAT inclusion and
   tax provider, RevenueCat account plan, Supabase bill/plan/usage, and approved
   price display before creating production products.

**Recommendation:** €2.99/month and €24.99/year appear **potentially viable
against ordinary paid AI inference costs**, with annual receipts less robust
after transaction fees/tax and fixed operating costs. Do not call them
profitable or sustainable yet. Obtain real feature/token usage and actual
provider/platform billing, fix the unavailable/incorrect model route, and
deploy auditable finite server quotas in an approved staging rollout before
making the commercial decision.

## Official sources checked

- Google Gemini API [pricing](https://ai.google.dev/gemini-api/docs/pricing), [models](https://ai.google.dev/gemini-api/docs/models), [image understanding](https://ai.google.dev/gemini-api/docs/image-understanding), and [thinking](https://ai.google.dev/gemini-api/docs/generate-content/thinking) — checked 2026-11-12.
- OpenRouter [Google Gemini 2.5 Flash-Lite catalog](https://openrouter.ai/google/gemini-2.5-flash-lite) — checked 2026-11-12.
- RevenueCat [RevenueCat Billing overview](https://www.revenuecat.com/docs/web/web-billing/overview), [Pro pricing](https://www.revenuecat.com/pricing), and [MTR billing](https://www.revenuecat.com/docs/welcome/set-up-revenuecat/account-management) — checked 2026-11-12.
- Stripe [France/EUR standard pricing](https://stripe.com/fr/pricing) and [Tax pricing explanation](https://support.stripe.com/questions/understanding-stripe-tax-pricing?locale=en-GB) — checked 2026-11-12.
- European Commission [VAT place of taxation](https://taxation-customs.ec.europa.eu/taxation/vat/vat-directive/place-taxation_en) — checked 2026-11-12.
- Supabase [pricing](https://supabase.com/pricing), [billing/quotas](https://supabase.com/docs/guides/platform/billing-on-supabase), [storage pricing](https://supabase.com/docs/guides/storage/pricing), and [egress pricing](https://supabase.com/docs/guides/platform/manage-your-usage/egress) — checked 2026-11-12.
