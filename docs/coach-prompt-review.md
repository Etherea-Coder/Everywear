# Coach prompt review

## Scope and provenance

This is a review copy of the deployed staging `style-coach` source inspected on
2026-11-17 and the matching local source at that time. The local prompt has
since been revised; this section preserves the historical review baseline.
The deployed copy is retained only in the ignored
`.tooling/recovery/staging-functions-aftdbphdobfrshienple-20261117/` directory.
No real-user data was sent to a model. A separate bounded synthetic staging
request was made on 2026-11-17; its sanitized output is recorded below.
Dynamic prompt inputs elsewhere in this review are represented as placeholders.

The earlier ignored 2026-11-11 source snapshot contains the same three prompt
templates. Its only rendered-text difference is quote style around event-field
fallback literals; the fallback values themselves are unchanged. The snapshot
does not establish which hosted project it came from.

## Shared dynamic context

The function may insert these data into the prompt:

- The user's name, if present.
- `user_profiles` style profile, preferred colors, style goals and the user's
  style intention.
- Wardrobe totals, top category/occasion and a bounded wardrobe summary.
- Up to seven days of recent outfit names, item names, occasions, dates and
  ratings.
- Up to three frequent weekday and weekend occasion patterns from the last 60
  days.
- High-rated item feedback as a short item-ID prefix, average rating and count.
- Up to three months of fitted/relaxed silhouette percentages and a trend.
- Passive mode only: local hour and its morning/afternoon/evening/night label.
- Active mode only: the user's question, bounded to 2,000 characters.
- Event mode only: bounded event title, type, date, days remaining and dress
  code.

The final assembled prompt is truncated at 16,000 UTF-8 bytes. The complete
request body is separately bounded by the function. Missing fields receive
neutral fallback text; they are not populated with real example users here.

## Current shared guardrails

```text
IMPORTANT:
- Do not shame the user
- Do not mention body weight or sensitive appearance assumptions
- Do not recommend expensive purchases unless truly necessary
- Do not invent wardrobe items that are not provided
- If data is missing, be transparent and still helpful
- Sound like a supportive, tasteful stylist friend — not a chatbot or fashion influencer
```

## Current mode instructions

The following templates retain the source wording. Bracketed sections name
dynamic blocks described above; no actual account data is included.

### Passive coaching

```text
You are a personal style coach[ for {userName}] inside a wardrobe app.
Your job is to give one short weekly coaching tip. Be warm, encouraging, concise, and practical.
Do not sound like a chatbot or fashion magazine. Base advice only on the user data below.
{profileBlock}
{insightsBlock}{recentOutfitsBlock}{habitBlock}{ratingsBlock}{evolutionBlock}{optional time context}
{shared guardrails}

TASK:
Give exactly one coaching tip for this week.
- Be specific and personal
- Reference the user's recent outfit choices if available — notice patterns, suggest variety, or compliment repeated favourites
- Use habit patterns to anticipate today's likely occasion if relevant
- Suggest one realistic action
- 2 to 4 sentences maximum
- Start with a short observation, then one practical suggestion
- Output only the tip text, nothing else
```

### Active coaching

```text
You are a personal style coach[ for {userName}] inside a wardrobe app.
Help users style themselves using their own wardrobe, style profile, and goals.
Be helpful, personal, concise, and confident.
{profileBlock}
{insightsBlock}{recentOutfitsBlock}{habitBlock}{ratingsBlock}{evolutionBlock}
{shared guardrails}

USER QUESTION:
{question}

TASK:
Answer as their personal style coach. Prioritize items they already own.
If relevant, reference their recent outfit history to give context-aware advice.
Keep the answer under 180 words. The "next_step" must be a concrete action, never a question. Example: "Try pairing your blazer with white trousers this week".
Output a JSON object with keys: "answer" and "next_step"
```

### Event coaching

```text
You are a personal style coach[ for {userName}] inside a wardrobe app.
Help users prepare outfits for real upcoming events. Be personal, practical, and appropriate.
Use the user existing wardrobe first. Do not invent wardrobe items not provided.
{profileBlock}
{insightsBlock}{recentOutfitsBlock}{habitBlock}{ratingsBlock}{evolutionBlock}

EVENT:
- Title: {title or "Unknown"}
- Type: {type or "Other"}
- Date: {date or "Unknown"}
- Days left: {daysLeft or "?"}
- Dress code: {dressCode or "Not specified"}
{shared guardrails}

TASK:
Suggest up to 3 outfit directions for this event. Keep full answer under 220 words.
If relevant, reference recent outfits to avoid repeats or build on successful looks.
Output a JSON object with keys: "intro", "outfit_1", "outfit_2", "outfit_3", "prep_tip"
```

## Output and request constraints

- All modes use `gemini-2.5-flash-lite` through the Gemini Developer API, with
  `maxOutputTokens: 400`, temperature `0.7`, a 20-second provider timeout, and
  no automatic retry or model fallback.
- Passive mode asks for exactly one plain-text tip of 2–4 sentences.
- Active mode asks for JSON keys `answer` and `next_step`; the answer is under
  180 words and `next_step` is a concrete action, not a question.
- Event mode asks for JSON keys `intro`, `outfit_1`, `outfit_2`, `outfit_3`,
  and `prep_tip`; it may suggest up to three outfit directions and caps the
  full answer at 220 words.
- The current Gemini request does not set a JSON response MIME type/schema.
  Application parsing and response validation remain the enforcement boundary
  for JSON modes.

## Synthetic staging response sample (2026-11-17)

One authenticated active-mode request to staging `style-coach` succeeded with
`gemini-2.5-flash-lite`. It used only synthetic context: a casual/practical
style profile and a navy knit top, dark denim, and white sneakers. The response
passed the app's `answer` / `next_step` parser. The synthetic-name greeting was
omitted from this sanitized copy:

```text
For a relaxed weekday, let's keep it effortlessly chic. Your navy knit top and
dark denim are a classic pairing. Add your white sneakers for a comfortable and
stylish finish. This combination is perfect for a streamlined, casual look.
It's simple, clean, and totally you!

Next step: Try wearing your navy knit top with dark denim and white sneakers
for your next weekday.
```

Staging telemetry recorded 316 input tokens, 102 output tokens, 1,184 ms
latency, and `gemini-2.5-flash-lite` as the served model. This single synthetic
response confirms request/response plumbing and schema parsing; it is not a
model-quality evaluation. The prompt itself was not changed.

## Review candidates for our later discussion

- Consider enforcing active/event response shapes through provider-supported
  structured output as well as local validation.
- Clarify whether the active-mode 180-word limit includes `next_step`.
- Revisit the “weekly” passive-tip framing against the actual refresh/cache
  cadence and decide how much recent wardrobe history is needed.
- Decide whether item-ID prefixes add enough value to justify sending them to
  the provider; the prompt currently receives no raw credentials.

No prompt or model behavior was changed for this review.

## Local coach update (not deployed)

After review, the local implementation was updated to fetch up to 24 current
wardrobe rows server-side for the authenticated user, retaining stable IDs and
saved names/categories/semantic labels/notes. Questions and all other dynamic
fields now travel inside a bounded JSON reference-data block; static shared and
mode instructions explicitly treat those values as data. The app sends its
saved response locale (`en`, `fr`, or `es`). Shared, passive, active, and event
instructions now emphasize practical owned-item outfits, brief reasoning,
useful next actions, and optional gentle experimentation within stated
preferences. Event instructions request missing information instead of
inventing wardrobe/event details. The active response keys remain `answer` and
`next_step`; the parser now requires a non-empty, non-duplicate next step. No
Challenge generation or Challenge data flow was changed.

These are local source changes only. Staging still needs a separately
authorized deployment of `style-coach` and a bounded request from an account
with available quota; the existing test account's daily allowance is
exhausted. No live inference was used to validate the new prompt.
