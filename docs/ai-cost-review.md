# Everywear AI cost and quota review

**Official provider prices and public model catalogs checked:** 2026-11-12.

**Local implementation reviewed:** 2026-11-12.
**Commercial prices:** €2.99/month and €24.99/year are owner-proposed values only. No products, prices, quotas, or public promises have been configured or published by this review.

## Recommendation

Retain `gemini-2.5-flash-lite` in the direct Gemini Developer API handlers and correct the OpenRouter identifier to `google/gemini-2.5-flash-lite`. Google currently says Flash-Lite is not deprecated and has no announced API shutdown date, but access is restricted to existing users who actively used the 2.5 models. OpenRouter's current public catalog independently lists the canonical model with image input and the same standard rates, with no `expiration_date`. Those are public documentation/catalog facts, not proof that either project key can call it or that its fashion outputs meet product quality needs. No provider inference or account-level metadata request was made.

The local quota proposal now caps accounts at 20 (free) or 200 (premium) shared AI actions per UTC month, plus 3/20 per UTC day and 1/5 per fixed UTC minute. At standard model rates and the source request bounds, estimated worst-case inference is about **$0.041 per free account-month** and **$0.405 per premium account-month**. An ordinary illustrative use mix costs less than a cent (light), about five cents (typical), or about seventeen cents (heavy). These figures are modeled, not measured. They exclude hosting/storage allocation, support, refunds, taxes, exchange-rate effects, and provider price changes.

These proposed € prices look plausible against bounded inference alone; overall sustainability is **not demonstrated**. The annual gross average is **€2.0825/month** before fees and taxes. Under an illustrative France standard EEA card rate of 1.5% + €0.25, Stripe alone would be about €0.295 on a €2.99 monthly charge and €0.625 on a €24.99 annual charge. This leaves €2.695 and €24.365 respectively before tax and other costs. It is only an example: merchant country, Stripe contract, card mix, checkout currency, refunds, and tax treatment are unknown. Run a measured staging beta before fixing the commercial allowance or publishing either price.

## Provider and feature trace

| Feature | Client → local handler | Local provider, endpoint, model and auth | Source bounds / behavior |
|---|---|---|---|
| Clothing analysis | `VisionEngineServiceMobile` → `analyze-clothing` | Gemini Developer API REST `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent`, server `GOOGLE_AI_API_KEY` in `x-goog-api-key`; not Vertex AI | One JPEG, ≤3,000,000 decoded bytes, dimensions ≤1280×1280; small static prompt, output ≤200 tokens, temperature .1; model default thinking is off with no request override; 20s timeout, no retry/fallback. Manual entry remains available if AI fails. |
| Outfit-photo advice | `AiSuggestionsService` → `ai-suggestions` | OpenRouter chat completions `https://openrouter.ai/api/v1/chat/completions`, server `OPENROUTER_API_KEY`, canonical `google/gemini-2.5-flash-lite` | One JPEG with same server byte/dimension limits; profile fields ≤500 chars, name ≤80; system prompt ≤4,000 UTF-8 bytes; output ≤500 tokens, temperature .1; 20s timeout; provider fallbacks disabled and input/output `max_price` set to $0.10/$0.40 per million tokens; no app retries/model fallback. |
| Today's outfit | `TodaySuggestionService` → `today-suggestion` | Same direct Gemini Developer API endpoint/key/model as clothing | Request body ≤16 KiB; server reads at most 40 owned wardrobe rows; final prompt ≤16,000 UTF-8 bytes; output ≤600 tokens, temperature .7; model default thinking is off with no request override; 20s timeout; no retry/fallback. Triggered automatically on daily screen load and by user actions. |
| Style coaching | Passive, active, event calls from `StyleService` → `style-coach` | Same direct Gemini Developer API | Body ≤32 KiB; final prompt ≤16,000 UTF-8 bytes; output ≤400 tokens, temperature .7; model default thinking is off with no request override; 20s timeout; no retry/fallback. Passive coaching is requested automatically when its screen loads and consumes the shared allowance. |
| AI insights | `AIIntelligenceService` → `generate-ai-insights` | Same direct Gemini Developer API | Body ≤4 KiB; authenticated reads capped at 250 wardrobe/outfit rows; final prompt ≤16,000 UTF-8 bytes; output ≤800 tokens, temperature .4; model default thinking is off with no request override; 20s timeout; no retry/fallback. Successful result cache is 30 min per user/range/category in app memory; force-refresh, app restart, or simultaneous cache misses can create more calls, all still quota-bound. |
| Deterministic / utility paths | `StylistEngineService`, `InsightsDashboard`, `CloudVisionService` | Local deterministic logic or connectivity check; no external inference | No model token charge. |

Sources: `lib/services/ai/vision_engine_service.dart`, `ai_suggestions_service.dart`, `today_suggestion_service.dart`, `style_service.dart`, `ai_intelligence_service.dart`; `supabase/functions/analyze-clothing/index.ts`, `ai-suggestions/index.ts`, `ai-suggestions/openrouter_request.ts`, `today-suggestion/index.ts`, `style-coach/index.ts`, `generate-ai-insights/index.ts`, `_shared/ai_action.ts`, and `_shared/jpeg_bounds.ts`.

### Source, deployed snapshot, and account access

- The inspected local source uses direct Gemini Developer API in four functions. It does not use Vertex AI endpoints, Vertex credentials, or Google Cloud SDKs. Google's Vertex AI model prices/retirement dates therefore do not apply to these four REST calls.
- The ignored read-only deployed source snapshot under `.tooling/recovery/remote-functions-project/supabase/functions/` showed Gemini Flash-Lite in all five deployed feature files at snapshot time. Its deployed `ai-suggestions` source used an OpenRouter key but had a noncanonical bare model field. It predates the current local request constraints and quota handlers; it was not copied over local code. Snapshot inspection cannot prove whether functions have changed after that read.
- The app contains no model provider key. The direct Gemini and OpenRouter keys are server-side environment variables. Source does not expose model selection through a client define or server environment override. The model constants are code literals. No automatic expensive fallback is configured locally.
- No secret values were read. Google AI Studio's public docs currently limit API access to qualifying existing 2.5 users; whether the Everywear Google API project qualifies and its key/billing tier are unknown. The OpenRouter public metadata/catalog confirms the canonical slug is listed, supports `text+image+file+audio+video -> text`, has `expiration_date: null`, and lists current $0.10 input / $0.40 output per million token rates. It does not confirm this account's key, route capacity, billing balance, actual provider selection, or output quality. OpenRouter routing remains OpenRouter and should not be misreported as direct Google AI Studio or Vertex AI.
- No paid inference, authenticated Google model metadata call, live key validation, or quality evaluation was performed.

## Limits and server enforcement

The prepared migration `supabase/migrations/20261112100000_server_ai_action_quotas.sql` and handler changes are **local only**. All five handlers authenticate with Supabase Auth and call a shared atomic reservation RPC immediately before model execution. The database—not client tier state—derives premium status from `user_profiles.tier`, `subscription_status`, and expiry. See [`ai-quotas.md`](ai-quotas.md) for windows, idempotency, failure behavior, migration prerequisites, staged rollout, and fail-closed rollback.

A reservation consumes one shared action after preflight. Provider errors, malformed output, timeout, interrupted work, or finalization failure are not refunded because the provider might already have billed the request. Same user/request UUID replay is rejected across endpoints. A caller that retries with a fresh UUID remains inside the shared quota. UTC month/day/minute windows are independent. Premium downgrades or expiry use the free limits on the next reservation; a request already reserved continues to completion. The quota RPC requires a non-null future expiry for active, grace-period, or cancelled records; a missing expiry fails closed to free limits. This is stricter than some existing entitlement helpers, so reconcile subscription renewal and grace-period webhook semantics before rollout.

Request ceilings in source:

- At most one JPEG per image operation; decoded image bytes ≤3 MB, width and height ≤1280 px. Server verifies base64 format, JPEG structure, and dimensions.
- Handler JSON body limits are 4.1 MB for image endpoints, 16 KiB for daily suggestion, 32 KiB for style coach, and 4 KiB for insights.
- Final text prompts are capped at 16,000 UTF-8 bytes for direct Gemini, 4,000 bytes for the OpenRouter system prompt, plus a short bounded language line. Google's current token docs say text and image inputs are tokenized; a 1280×1280 image would be about four 768px tiles ×258 tokens = roughly 1,032 image input tokens. Token cost scenarios below treat the 16,000-byte text cap as 16,000 input tokens, a conservative planning approximation, then add image tokens.
- Output caps are 200/500/600/400/800 tokens by feature. Gemini Flash-Lite documents thinking off by default and requests no thinking override; OpenRouter does not request reasoning and its catalog says reasoning is not mandatory. Any billable output thinking tokens are included in the provider output-rate policy.
- Provider execution has a 20-second timeout and response body cap of 65,536 bytes. Application retries are zero. OpenRouter model/provider fallback is disabled. Concurrent work is capped per account at 1 free / 3 premium requests, alongside minute burst limits.
- There is no provider-response cache server-side. Local 30-minute insights cache is a usability optimization, not enforcement. Automatic daily suggestion and passive coach calls count as actions and may use free allowance without a tap.
- Logs contain action, configured model, latency, provider-reported token counts where available, and safe error class; they must not contain prompts, photos, user tokens, or provider secrets.

Manual entry and non-AI wardrobe/outfit functions remain usable at zero quota. AI errors do not turn into fake successful recommendations. The new localized UI displays monthly remaining allowance and maps monthly/daily/burst denials and unavailability to messages; day/burst availability is also considered when marking an allowance exhausted.

## Current official provider pricing checked 2026-11-12

### Gemini Developer API / AI Studio

Google's [Gemini 2.5 Flash-Lite pricing table](https://aistudio.google.com/docs/pricing#gemini-2.5-flash-lite) lists Standard paid rates of **$0.10 per million text/image/video input tokens** and **$0.40 per million output tokens, including thinking tokens**. Audio uses different rates but no Everywear path sends audio. The free tier lists free token prices, but says content is used to improve Google products; the paid tier says it is not. Do not base personal-photo production privacy or cost planning on free-tier access. Priority and cached rates differ; source requests do not use either. No search/map grounding is configured.

Google's [current model page](https://aistudio.google.com/docs/models#gemini-2.5-flash-lite) says `gemini-2.5-flash-lite` is not deprecated and will continue through the API until further notice, while access is restricted to existing users who actively used the 2.5 models. Google's [deprecation schedule](https://aistudio.google.com/docs/deprecations#gemini-2.5-flash-models) lists no shutdown date for Flash-Lite. The different `gemini-2.5-flash` model is deprecated; that schedule must not be applied to Flash-Lite.

[Gemini token documentation](https://aistudio.google.com/docs/tokens#images) says a ≤384px image counts as 258 tokens; larger images are tiled into 768×768px tiles, each counting as 258 tokens. At the app's 1280×1280 maximum, roughly four tiles/1,032 tokens is used as an estimate here, not a measured tokenizer result. Provider response usage metadata should be retained to replace this estimate.

### OpenRouter

The [official model page](https://openrouter.ai/google/gemini-2.5-flash-lite) and public [model metadata](https://openrouter.ai/api/v1/model/google/gemini-2.5-flash-lite) independently show canonical ID `google/gemini-2.5-flash-lite`, image input, $0.10/M prompt and $0.40/M completion prices, `expiration_date: null`, and no mandatory reasoning. This is catalog availability, not account access or quality evidence. The local request disables routing fallback and caps accepted rates using OpenRouter's documented [`provider.max_price`](https://openrouter.ai/docs/guides/routing/provider-selection) controls. If no route meets the cap, AI should error rather than silently pick a costlier model/provider.

## Modeled inference costs

Formula: `input tokens × $0.10 / 1,000,000 + output tokens × $0.40 / 1,000,000`. No caching discounts, tax, grounding, audio, inference retries, or unconfigured fees are included. Failed/time-out provider operations consume quota and may still have incurred costs; one operation never causes an application retry.

| Feature | Assumed normal input | Assumed output | Estimate/action |
|---|---:|---:|---:|
| Clothing image | 2,500 tokens including image | 200 | $0.00033 |
| Outfit-photo advice | 5,000 including image/profile | 500 | $0.00070 |
| Today's outfit | 8,000 | 600 | $0.00104 |
| Coach turn | 6,000 | 400 | $0.00076 |
| Insights | 10,000 | 800 | $0.00132 |

| Scenario | Feature mix per month | Quota relation | Modeled cost |
|---|---|---|---:|
| Light | 4 clothing, 3 daily, 1 coach, 1 insights, 1 outfit photo (10 actions) | Free: 10/20 month, within 3/day when spread across at least four days | $0.00722 |
| Typical | 12 clothing, 20 daily, 18 coach, 6 insights, 4 outfit photos (60 actions) | Premium: 60/200 month, with no more than 20/day | $0.04916 |
| Heavy | 40 clothing, 40 daily, 60 coach, 40 insights, 20 outfit photos (200 actions) | Premium monthly maximum; spread across at least 10 days under 20/day | $0.16720 |
| Bounded maximum | 200 actions at maximum text/image and output bounds | Premium monthly and daily limits both allow 200/month | ≈$0.405/month |

The bounded maximum assumes at most 17,032 input tokens/action (16,000 text-token planning ceiling plus estimated 1,032 image tokens) and 800 output tokens: `$0.0017032 + $0.00032 = $0.0020232/action`, multiplied by 200 = `$0.40464`. It is a conservative cost model, not a mathematically strict bound: UTF-8 bytes are not an exact model-token counter, Google tokenization can differ, and provider metadata/prices can change. Current source output caps and image dimensions are strict; input text is byte-bounded, not checked against a provider token counter.

The maximum free account cost is approximately **$0.041/month** (20 actions). With 10,000 free monthly-active accounts each exhausting quota, the modeled aggregate is about **$405/month**, before platform costs. Premium exhaustion costs up to about **$0.405/subscriber-month** before shared infrastructure. Typical premium use is about five cents. Free-user abuse therefore remains a population-level cost to monitor even under the cap.

## Commercial and hosting scenarios

- Proposed monthly gross: €2.99.
- Proposed annual gross: €24.99/year = **€2.0825/month average** before deductions.
- Illustrative Stripe France standard EEA card schedule is 1.5% + €0.25 per transaction ([official pricing](https://stripe.com/fr/pricing)). On those sticker amounts that is about €0.295/monthly and €0.625/annual charge. Fee is not guaranteed for this merchant; UK, premium/international cards, currency conversion, payment method, merchant country, and negotiated rates differ.
- RevenueCat currently advertises Pro free through $2,500 monthly tracked revenue, then 1% of tracked revenue ([official plans](https://www.revenuecat.com/pricing)). RevenueCat says web billing is included and reports US Stripe 2.9% + $0.30 and optional Stripe Tax fees, while actual Stripe fees vary by country ([RevenueCat Billing overview](https://www.revenuecat.com/docs/web/web-billing/overview)). Check the owner account's plan and actual fee schedule; do not stack the US quote on top of the France scenario as though both applied.
- Taxes cannot be calculated without merchant establishment, customer residence, registration, tax-inclusive/exclusive pricing, and collection settings. For a tax-inclusive price and rate `r`, VAT-exclusive revenue is `price/(1+r)`; this is only a formula, not an assumed rate or legal conclusion. Applicable tax could materially reduce the available gross.
- Supabase's current public [Pro pricing](https://supabase.com/pricing) shows $25/month before overages, 100GB storage, 250GB uncached and cached egress, with compute costs depending on project configuration. This is an example public plan, not evidence about the recovered project's plan/invoice. If the entire $25 base were allocated per paying subscriber, it is $0.25/user at 100 users or $0.025/user at 1,000, before compute/usage; actual allocations also need to include free users.
- Currency conversion, Stripe tax/processing, RevenueCat account terms, Supabase bill, image storage/egress, support, disputes, and refunds remain unmeasured. Therefore no net margin/profit estimate is asserted.

## Launch recommendation

The 20/200 monthly, 3/20 daily, and 1/5 per-minute server policy is a reasonable **provisional implementation baseline**, not a final commercial promise. It is finite, limits the model cost in source, and leaves manual/basic styling available. Keep it through a private staging pilot only if observed tokens and automatic-call frequency match assumptions. Consider reducing free automatic calls (especially passive coaching and page-load suggestions) or moving them behind explicit user action if they routinely consume the allowance; do not make AI “unlimited.” Consider reducing premium monthly allowance from 200 if telemetry reveals higher-than-modeled inputs, unbounded provider/hosting costs, or excessive passive calls.

Before product creation, establish Google API eligibility/key and paid tier, OpenRouter account/key/routing access (without using production photos for a smoke test), and response quality with consented synthetic/staging examples. Run staging traffic to measure provider-reported input, output, and thought tokens plus error/timeout/call rates. Confirm owner Stripe activation, merchant country, actual payment method fees and VAT/tax setup, RevenueCat plan, and Supabase actual bill. Only then decide whether proposed €2.99/€24.99 pricing and these limits are commercially viable.

## Official sources

Checked 2026-11-12:

- Google Gemini Developer API: [deprecations](https://aistudio.google.com/docs/deprecations), [model catalog](https://aistudio.google.com/docs/models), [pricing](https://aistudio.google.com/docs/pricing), [thinking behavior](https://aistudio.google.com/docs/thinking), [token counting/image tokenization](https://aistudio.google.com/docs/tokens).
- OpenRouter: [model page](https://openrouter.ai/google/gemini-2.5-flash-lite), [public model metadata](https://openrouter.ai/api/v1/model/google/gemini-2.5-flash-lite), [provider routing and max price](https://openrouter.ai/docs/guides/routing/provider-selection).
- Fees/hosting: [RevenueCat plans](https://www.revenuecat.com/pricing), [RevenueCat Billing and web fees](https://www.revenuecat.com/docs/web/web-billing/overview), [Stripe France pricing](https://stripe.com/fr/pricing), [Supabase pricing](https://supabase.com/pricing).
