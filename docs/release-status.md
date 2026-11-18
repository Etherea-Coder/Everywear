# Android release status

## Locale-independent clothing color analytics (2026-11-18)

- Moved the exact existing `generate-ai-insights` color keyword vocabulary to
  `_shared/color_vocabulary.ts` and added French/Spanish legacy aliases.
  Matching uses normalized whole-word/phrase tokens, maps the existing `grey`
  spelling to canonical `gray`, and counts at most one color per semantic label.
  English, French, Spanish, and mixed-language fixtures produce identical
  canonical dominant-color counts and percentages. No schema migration or
  hosted-record rewrite is needed.
- `analyze-clothing` now requests canonical English `color` and material fields
  independently of locale, while returning additive localized `colorLabel`
  and `materialLabel` display fields. Existing category and `style_vibe` enum
  values remain fixed. The app uses localized labels for the suggested item
  name and canonical fields for the persisted `semantic_label`.
- `generate-ai-insights` keeps its existing canonical `dominantColors`
  response shape; the AI Intelligence chart localizes labels at render time and
  keeps canonical keys for color swatches. Its user-facing AI prose still uses
  the requested response locale.
- Checks: focused Deno tests **12 passed**; Deno checks for
  `analyze-clothing` and `generate-ai-insights` passed; targeted Dart tests
  **4 passed**; targeted Dart analysis reported no errors (11 existing
  info-level lints); targeted Deno format/lint and Dart formatting passed.
  No live inference, quota use, hosted operation, full suite, device test, or
  deployment was performed.
- Staging must deploy **both** `analyze-clothing` and `generate-ai-insights`
  before relying on language-independent AI-saved attributes and normalized
  analytics. Production remains untouched.

## Locale/font staging APK build (2026-11-17)

- Built the current source with `scripts/build_uptodown_free_beta.sh`, explicit
  staging ref `aftdbphdobfrshienple`, the existing private mode-0600 staging
  config, Java 21, one Gradle worker and a 2 GiB Gradle heap. The helper forces
  free-beta mode, Uptodown distribution, purchases unavailable, ads disabled,
  and the staging marker enabled. No device was connected or used.
- APK: `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-4-aftdbphdobfrshienple-debug-LOCALE-FONTS-20261117.apk`;
  size **198,715,418 bytes**; SHA-256
  `0a200a1a55364240557369d76ae4a63547d93065b9c7684a1a79f36062b2575b`.
  ZIP integrity passed. `aapt` confirmed `com.stylewise.app`, version
  `1.0.0-beta.1` / code 4, and target SDK 36. APK Signature Scheme v2
  verification passed with the Android Debug certificate (SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`).
- All four bundled font files and their OFL/trademark notices are present in
  the APK asset bundle. This proves packaging and compilation, not runtime font
  rendering on a device. The artifact is a staging debug test APK, unsuitable
  for public distribution. Installation and physical-device checks remain
  pending. Gradle emitted an Android SDK XML v4/tooling-version warning but
  completed successfully.

## Edge Function checks after locale/font checkpoint (2026-11-17)

- Installed Deno **2.9.6** into ignored `.tooling/deno/` and ran the complete
  `supabase/functions` fixture suite: **51 passed, 0 failed**. These tests use
  mock/provider fixtures and did not call hosted functions or AI providers.
- `deno fmt --check`, `deno lint`, and `deno check` passed for
  `_shared/response_locale.ts` and the modified `analyze-clothing`,
  `generate-ai-insights`, and `today-suggestion` handlers. No hosted operation
  or deployment was performed.

## Project-wide Flutter analysis (2026-11-17)

- `.tooling/flutter/bin/flutter analyze --no-pub` completed in 4.4 seconds and
  reported **245 info-level diagnostics, 0 warnings, and 0 errors**. Flutter
  returned exit code 1 because the info-level findings are still emitted as
  analyzer issues. The findings include existing style and deprecation lints;
  this is not a clean project-wide analyzer pass. The focused analyzer run for
  the locale/font files was previously recorded separately.

## Full Flutter test suite after locale/font checkpoint (2026-11-17)

- Ran `.tooling/flutter/bin/flutter test --no-pub --concurrency=1
  --reporter expanded` from commit `a2e68572876ff4010b17184784ce986943d55cea`.
  Result: **135 tests passed, 0 failed**. This includes locale propagation,
  passive advice refresh/stale-response handling, and bundled-font loading.
- A few offline fail-closed service tests printed expected diagnostics because
  Supabase was deliberately not initialized in those unit fixtures; they did
  not fail. The run did not call hosted services, start an emulator, or test
  device behavior.
- No build, device smoke, Deno check, deployment, production operation, or push
  was performed. Existing unrelated working changes remain unstaged.

## Client locale consistency (2026-11-17)

- The active UI locale is now the source for every client AI call:
  `style-coach`, `today-suggestion`, `generate-ai-insights`, and
  `analyze-clothing` receive normalized `responseLocale`; `ai-suggestions`
  receives its uppercase `language` contract. The insights cache includes the
  locale in its cache key. No client AI service rereads only the saved locale
  or substitutes English when the device fallback is active.
- Startup precedence remains explicit saved choice, supported device
  language, then English. An explicit saved Spanish choice therefore wins
  over a French device locale; a fresh French device resolves to French.
- The signed-in passive coach tip was cached after first load. It now clears
  when the app locale changes and offers a localized **Refresh advice**
  action. Changing locale alone does not start another AI request. The
  explicit refresh uses the current locale, and the controller ignores late
  responses from older locales. Other inspected signed-in screens resolve
  localized strings during build rather than caching them in `initState`.
- On the passive-coach screen, locale changes do not initiate a replacement
  request. The old tip is cleared; localized refresh copy and a **Refresh
  advice** action are shown. Failed requests retain that retry action, and
  request sequencing prevents a previous-language response from replacing
  fresh advice.
- Focused Flutter tests passed (13 tests): device fallback, saved-choice
  precedence, welcome/picker language, next-request locale changes, passive
  locale changes without automatic calls, explicit refresh with the new
  locale, stale-response rejection, and loading Inter/Google Sans assets with
  runtime fetching disabled. Targeted Dart analysis found no errors and 37
  info-level lint/deprecation findings across the touched files. Formatting
  and `git diff --check` passed. Deno is unavailable here, so no Edge Function
  type-check/test was run. No live AI, device, or hosted checks were run.
- `google_fonts` is pinned to 8.1.0. Bundled official Google Fonts CDN files
  match that package's expected hashes for Inter Regular/Medium/SemiBold and
  Google Sans Medium; `pubspec.yaml` includes `assets/fonts/`. The two OFL 1.1
  notices and Google Sans trademark notice are retained beside the font files.
  `main()` disables runtime font fetching. A focused widget test cleared the
  Google Fonts in-memory cache, disabled fetching and loaded all four variants
  from the asset bundle.

## Staging coach deployment and bounded evaluation gate (2026-11-17)

- Before deployment, authenticated only with the dedicated staging smoke
  account and read `get_ai_allowance`: project ref
  `aftdbphdobfrshienple`, free tier, 17 monthly actions remaining, 0 daily
  actions remaining (3/3 used), and 1 burst slot remaining. No request ID was
  reserved and no provider request was made.
- Deployed only the committed `style-coach` implementation from
  `e1cdace29dafdcb379f1f2eea87a87d1350d8091` to the CLI-verified
  `Everywear-staging` project (`aftdbphdobfrshienple`, `eu-north-1`), using
  the repository Deno import map and server-side Supabase bundling. No
  `--no-verify-jwt` option was passed. Read-only `functions list` afterward
  showed `style-coach` active at version 4 with `verify_jwt: true` and deployed entrypoint SHA-256 `f558744a0e607bf67e26ea55de77064a7e3ad13e84d54d3a0773b978360af127`.
- The authorized allowance gate prevented the three planned active/passive/
  event requests because daily remaining was zero. No inference was attempted;
  therefore there are no response outputs or request-driven quota changes.
  Language, item grounding, useful next-step behavior, and insufficient-event
  behavior remain pending runtime evaluation. Do not reset or bypass the
  account's quota; use an authorized synthetic staging account with available
  daily allowance for a later bounded evaluation.
- The deployed prompt/context source was not changed beyond commit `e1cdace`.
  Production, other functions, app builds, phone/emulator tests, and push were
  untouched.

## Coach grounding and response quality update (2026-11-17)

- Local `style-coach` now queries wardrobe rows only after validating the
  bearer user, with both the caller JWT/RLS context and an explicit
  `user_id = auth user UUID` filter and an exact count. It selects stable item IDs plus saved
  `name`, `category`, `semantic_label`, and `notes`; image URLs and other
  account rows are excluded. The resulting context is capped at 24 items and
  4,500 UTF-8 bytes. A wardrobe-query failure returns a clear unavailable
  response before reserving AI quota.
- The context includes server-generated `complete`, `partial`, or
  `unavailable` status. Omitted counts are attached only when the exact count
  is known; a capped query without a count reports `partial` without guessing
  the number. If the overall context limit forces removal of the list, status
  becomes `unavailable` and the known total is reported as omitted. Optional
  outfit history is trimmed before the owned-item list.
- Selection remains newest-first by `created_at`, not relevance-ranked. Older
  saved pieces may be omitted even if they better fit a request; this is a
  known limitation pending usage evidence and a deliberate ranking design.
- Every mode is told a partial list is not the user's entire wardrobe, and an
  unavailable/empty context is not evidence that they own no clothing. Active
  mode now allows useful general guidance or one relevant question in `answer`
  when item context is unusable, while retaining a concrete non-question
  `next_step`.
- At the time of the original prompt update, client callers sent the saved app
  locale. The later client-locale consistency checkpoint above supersedes that
  detail: callers now pass the resolved, current UI locale. The function
  normalizes unsupported values to English. Coach context is JSON
  data, capped at 8,000 UTF-8 bytes, with a 16,000-byte total prompt ceiling.
  Questions, wardrobe descriptors, profile values, event details, and history
  are explicitly marked untrusted reference data. The static safety and mode
  instructions stay outside that data block.
- Shared, passive, active, and event instructions now prioritize practical
  everyday outfits from owned items, comfort/preferences and the asked
  occasion; request a short explanation and a useful distinct next action
  where the existing contract supports it; avoid generic praise and routine
  disclaimers; and allow at most a relevant gentle experiment within stated
  boundaries. Event mode asks for missing context instead of inventing details
  and retains its existing JSON keys. Active parsing now rejects a missing or
  verbatim-duplicate `next_step`, while retaining the same response fields.
- Added focused Deno tests for owner filtering, stable descriptors and context
  bounds, locale normalization, data/instruction separation, mocked Gemini
  response parsing, malformed output, and insufficient event context. These
  use fixtures only; no provider request, quota reset, hosted operation, or
  full smoke suite was run.
- **Not deployed:** staging `style-coach` still runs its previous deployed
  source until a separately authorized staging deployment. No schema change
  or migration is needed. After review, deploy only this function to staging
  with the repository import map, then test one bounded request using a
  synthetic account with available quota (do not reset the exhausted account).
  Reviewed staging command:
  `.tooling/supabase/node_modules/.bin/supabase functions deploy style-coach --project-ref aftdbphdobfrshienple --import-map supabase/functions/deno.json`.
  Production remains untouched.
- Existing uncommitted purchase/wardrobe UI and staging-script changes remain
  unrelated and unstaged.
- Checks actually performed: targeted `deno fmt`; focused Deno tests for
  `coach_context_test.ts` and `coach_response_test.ts` (**13 passed, 0 failed**);
  targeted Deno lint on the five changed TypeScript files; Deno type-check of
  `style-coach/index.ts` with the repository import map; Dart formatting of
  `lib/services/style_service.dart`; and `git diff --check`. One initial
  focused test invocation exposed an outdated fixture without `next_step`; the
  fixture was corrected and the focused suite then passed. No Flutter tests,
  project-wide analysis, staging request, live inference, deployment, build,
  or full device smoke was performed.

## Bounded staging Gemini validation (2026-11-17)

- The owner reports saving `GOOGLE_AI_API_KEY` to staging project
  `aftdbphdobfrshienple`. Read-only project identity and Edge Function secret
  name checks confirmed `Everywear-staging` is active/healthy and the Gemini
  key name is present. `OPENROUTER_API_KEY` remains absent by design. No secret
  values were read.
- The AVD used for the pending OAuth attempt was shut down with `adb emu kill`;
  the OAuth log capture was already stopped. No device or core smoke test was
  run for this AI check.
- The existing mode-0600 staging app config and dedicated mode-0600 smoke
  credentials were validated by file shape and location. A password-grant
  login for that dedicated staging account succeeded. An unauthenticated
  `style-coach` request returned HTTP 401. The authenticated
  `get_ai_allowance` RPC reported free tier with 20 monthly, 3 daily, and 1
  burst action remaining before inference.
- The first bounded synthetic `style-coach` call returned HTTP 502 /
  `AI_PROVIDER_REJECTED`. Its post-request allowance was 19 monthly and 2
  daily; the burst action was consumed. The sanitized response contained no
  generated coach text.
- After the owner explicitly authorized deployment, only `style-coach` was
  deployed to the verified staging project. JWT verification remained enabled.
  The deployment added status-only telemetry; no provider response body,
  prompt, credential, token, or personal data is logged. One synthetic retry
  returned HTTP 502 / `AI_PROVIDER_REJECTED`. Its function log reported
  upstream status **402**, category `provider_rejected`, and 259 ms latency.
  The sanitized API envelope remained generic and contained no generated
  coach text. No raw Gemini error body was read.
- Google AI Studio's current billing documentation defines HTTP 402 as
  `Payment Required`; the Gemini API stops serving requests when a Prepay
  balance is zero, and the billing UI also uses “No credits” when required
  Prepay setup is missing or the balance is depleted. This identifies the
  failure as Gemini billing/Prepay availability for the project behind the
  saved key. The exact AI Studio project and whether it lacks Prepay setup or
  has a zero balance were not inspected. Check AI Studio → Billing for the
  project that owns the staging key; do not change billing or purchase credits
  without the owner's separate decision. See
  [Gemini API billing](https://aistudio.google.com/docs/billing).
- Immediately after the two failed provider attempts, allowance was 18 monthly
  and 1 daily;
  the burst action was consumed by the retry. This matches the documented
  backend policy: reservation is charged before provider execution and is not
  refunded after provider errors because the provider may already have incurred
  cost. No quota reset or accounting change was made. The HTTP 402 result
  occurred before a model response; whether this failed attempt incurred any
  provider charge was not independently measured.
- The deployed `style-coach` telemetry code and status classifier are present
  locally. The coach prompt remains unchanged. The later synthetic success
  below is the only model-response sample; no real-user response was requested.
- Other Gemini-backed endpoints were not called after the 402, avoiding
  unnecessary requests while this shared key/project billing issue remains.
  The OpenRouter-backed `ai-suggestions` outfit-photo advice feature remains
  unavailable until `OPENROUTER_API_KEY` is intentionally configured in
  staging. Its failure path was not invoked.
- After the owner reported adding Gemini credit, I checked the allowance
  before making another request: free tier, 18 monthly, 1 daily, and 1 burst
  action remained. One synthetic active-mode `style-coach` request then
  succeeded with HTTP 200 and a validated `answer` plus concrete `next_step`.
  The allowance became 17 monthly, 0 daily, and 0 burst. The deployed
  function log reported `gemini-2.5-flash-lite` as both requested and served
  model, 1,184 ms latency, 316 input tokens, and 102 output tokens. No further
  AI requests were made. A sanitized example is recorded in
  [coach-prompt-review.md](coach-prompt-review.md).
- A fresh public Auth settings GET returned HTTP 200 with Google and email
  providers enabled. The isolated emulator OAuth flow had previously reached
  Google's account sign-in page, but no private account interaction or
  callback/session completion was observed. The emulator was shut down
  gracefully at the owner's request; Google OAuth remains unverified. No
  production project, provider settings, or production data was changed.
- Checks actually performed: authenticated staging password grant; unauth-
  enticated and authenticated function calls; authenticated allowance reads
  before and after each request; read-only staging function/secret inventory
  and Edge Function logs; and one-function staging deployment. The CLI's
  server-side bundler initially failed because it was not given the Deno import
  map; the deployment succeeded after explicitly passing
  `supabase/functions/deno.json`. `deno` is unavailable, so no Deno
  test/type-check was run. `git diff --check` passed. No build, analyzer, core
  smoke, or production operation was performed.

## Staging Google OAuth recheck after Google Cloud callback update (2026-11-17)

Historical pre-configuration snapshot; superseded by the newer bounded staging
Gemini validation entry above. At the time of this check, public Auth settings
reported Google disabled and no OAuth attempt was started.

- The owner reports adding
  `https://aftdbphdobfrshienple.supabase.co/auth/v1/callback` to the existing
  Everywear Google OAuth **Web** client while preserving the production
  callback. This is owner-reported Google Cloud configuration; it does not
  enable Supabase Auth for the staging project.
- Read-only `https://aftdbphdobfrshienple.supabase.co/auth/v1/settings` still
  returns HTTP 200 with `external.google=false` and `external.email=true`.
  Consequently the app would still receive `unsupported provider` if OAuth
  were attempted, so no browser flow or emulator launch was started.
- Staging Google provider client-ID/secret presence cannot be inspected through
  the available interfaces. The public Auth settings omit those fields; the
  Management API Auth-config GET previously returned HTTP 401, and the current
  authenticated CLI has project/function/secret-name read access but no Auth
  config read command. No secret values were accessed.
- **Next owner action:** in Supabase Dashboard, open project
  `aftdbphdobfrshienple` → Authentication → Sign In / Providers → Google.
  If the existing Everywear Web client ID and secret are already populated,
  enable Google and save. If either is empty, enter the ID and secret for the
  existing Web client whose callback was just updated; do not create a new
  client. In Authentication → URL Configuration, confirm
  `io.supabase.everywear://login-callback` remains allowlisted (the owner
  previously reported it was added). If Google's consent screen is in Testing,
  allow the intended test account there. Do not send credentials in chat.
- After the owner confirms that save, run only an isolated staging-app Google
  OAuth test on the emulator. At the Google account/consent step, pause with the
  process alive for private interaction, then verify that the callback returns
  to Everywear and produces a Supabase session and authenticated screen. No
  phone, app data, or production setting is involved.
- A new read-only staging secret-name listing still shows
  `GOOGLE_AI_API_KEY` and `OPENROUTER_API_KEY` absent. If Google sign-in passes,
  bounded AI validation will additionally require those values entered into
  staging Edge Function Secrets from the providers; no production key can be
  reused without explicit authorization. No AI call was made.
- Checks actually performed: staging identity via CLI, staging public Auth
  settings GET, staging Edge Function secret-name listing, local callback and
  package source inspection. No build, OAuth flow, test, inference, hosted
  mutation, or production operation was performed. Existing core smoke result
  at `87f33baf` remains valid and was not repeated.

## Staging Google OAuth and AI provider preflight (2026-11-17)

Historical pre-configuration snapshot; its disabled-provider and absent-key
findings were superseded by later staging configuration checks above.

- Baseline preserved: `main` at successful core-smoke checkpoint
  `87f33bafcf41d7fd80ab4a66595cd36ae205b23e`. The existing modifications in
  `purchase_tracking.dart`, `wardrobe_management.dart`, and
  `scripts/build_uptodown_free_beta.sh` remain untouched.
- Read-only Supabase CLI project listing confirms `Everywear-staging`, ref
  `aftdbphdobfrshienple`, `eu-north-1`, active/healthy. CLI read-only function
  and secret-name inspection used that explicit staging ref. No project link,
  setting, secret, or deployment was changed.
- A staging public Auth settings GET returned HTTP 200 with Google disabled and
  email enabled. App source calls Supabase browser OAuth with
  `io.supabase.everywear://login-callback`, and the Android manifest registers
  that callback. The owner previously reported the callback allowlisted, but
  the current hosted redirect allowlist was not independently read back: the
  Management API Auth-config GET previously returned HTTP 401 and the CLI has
  no Auth-config read command. The exact hosted allowlist and provider client
  configuration therefore remain unverified.
- No suitable Google OAuth Web client ID/secret was found in Git history, local
  environment variables, or the local Android `google-services.json` file.
  That file is ignored, does not match `com.stylewise.app`, and has no OAuth
  client entries; it was not changed. The owner-suggested Google Cloud project
  `gen-lang-client-0622881366` remains only a candidate: `gcloud` is not
  installed, and this environment could not inspect its Google Cloud Console
  OAuth setup. The app's browser-based Supabase OAuth flow needs a Google OAuth
  **Web** client, not a Firebase Android client.
- Google sign-in could not be completed. No browser flow or Google account
  interaction was started. To unblock it, verify the intended Google Cloud
  project; create/reuse a Web OAuth client whose authorized redirect URI is
  `https://aftdbphdobfrshienple.supabase.co/auth/v1/callback`; enable Google in
  the **staging** Supabase Auth provider and enter that client ID/secret
  there; confirm `io.supabase.everywear://login-callback` remains in the
  staging redirect allowlist; and add the test Google account to the consent
  screen if it is in Testing mode. Keep the secret in Supabase, never the app.
  After that, perform the Google account step privately in the emulator and
  verify return to the app plus a Supabase session.
- Read-only inspection of the deployed staging AI functions was saved in the
  ignored directory
  `.tooling/recovery/staging-functions-aftdbphdobfrshienple-20261117/`; local
  function files were not overwritten. Deployed handlers match source:
  `analyze-clothing`, `today-suggestion`, `style-coach`, and
  `generate-ai-insights` require `GOOGLE_AI_API_KEY` and use direct Gemini
  Developer API `gemini-2.5-flash-lite`; `ai-suggestions` requires
  `OPENROUTER_API_KEY` and uses `google/gemini-2.5-flash-lite` through
  OpenRouter. A read-only staging Edge Function secret-name listing shows
  **both names absent**. This confirms the current `AI_UNAVAILABLE` response
  cause; no provider key value was read and no production key was copied.
- No AI request or paid inference was made in this pass. Before bounded
  staging validation, add a valid Gemini Developer API key as the staging
  `GOOGLE_AI_API_KEY` secret and an OpenRouter key as staging
  `OPENROUTER_API_KEY` (needed for outfit-photo advice). Add them through the
  staging Dashboard's Edge Function Secrets or a private local credential
  channel. Then verify authenticated success, one quota-limited exhaustion
  case, unauthenticated denial, and unavailable/malformed-provider errors with
  synthetic data only. Do not copy production provider secrets.
- The coach prompt and its dynamic fields/output contracts are documented at
  [coach-prompt-review.md](coach-prompt-review.md). The deployed staging
  prompt matches local source. No prompt, model, quota, or app behavior was
  changed. The core smoke at `87f33baf` was not repeated.
- Checks actually performed: source and Git-history inspection; staging
  project/function/secret-name reads; staging public Auth settings GET;
  callback and manifest inspection; targeted diff/status inspection. No build,
  tests, analyzer, OAuth browser flow, email test, or AI inference was run.

## Unattended emulator smoke: prebuilt staging test APK (2026-11-16)

- Updated the unattended runner to build the isolated
  `com.stylewise.app.stagingtest` APK while the AVD is stopped, select Java 21,
  retain the 2 GiB Gradle heap/one worker, stop Gradle daemons after compile,
  and require at least 6 GiB available RAM before build and before boot. After
  boot it checks a separate 3 GiB runtime threshold and invokes the pinned
  Flutter `drive --no-build --use-application-binary` route. The pinned Flutter
  3.35.7 source was inspected: drive resolves the provided APK package and
  passes the same package identity to install, launch, stop and teardown; the
  installed Android SDK platform prevents the runner's fallback build branch.
  No Gradle process ran after emulator boot in the successful run.
- The fresh integration APK build succeeded with Java 21, one worker and a
  2 GiB heap while the emulator was stopped. The Gradle daemon was gracefully
  stopped before boot. The emulator then installed and ran the already-built
  artifact. No phone was used. The runtime preconfirmed staging login was
  supplied from the existing private credential file; credential values were
  not logged or included in the APK.
- Fixed the gallery test tap to wait for a control to become hit-testable and
  made hit-test warnings fatal. The first run proved the prior false success:
  its bottom-sheet option was offscreen during tap and no image reference was
  saved. It also exposed that the Today test tried to scroll while Today was
  still showing its load spinner. The runner now waits, with a finite bound,
  for the refreshed scrollable to mount before scrolling to the exact saved
  outfit row. A later preconfirmed-account name assertion was corrected to
  distinguish displayed Auth metadata from profile-row synchronization; this
  account is not a fresh signup fixture.
- Latest bounded emulator run: **passed**. Authenticated staging login and
  project guard passed; a synthetic wardrobe row was saved, its image uploaded
  and rendered; outfit confirmation rendered that image; a synthetic outfit
  was saved; Today completed its refreshed fetch (`cardsNow=7`) and displayed
  the exact saved outfit row; profile displayed the authenticated Auth full
  name; final test-app sign-out completed. Flutter reported `All tests
  passed.` The test package was removed at teardown. The normal package on the
  emulator remained installed with version/install/update metadata unchanged.
- The separate disposable-signup metadata check was **not run** because its
  configured signup address is already registered (`SIGNUP_ADDRESS_UNUSED=
  FAIL`). Signup metadata persistence and confirmation-email delivery remain
  unverified. The existing account's `user_profiles.full_name` did not match
  its Auth `full_name`; the UI nevertheless displayed the Auth name. This
  existing-account row mismatch is recorded, not repaired by changing account
  data, and is not evidence about fresh-signup persistence.
- AI-backed tips and purchase verification returned configured-unavailable
  errors from staging; no successful model inference or billing validation is
  claimed. Ads and purchases remained disabled. These errors did not block the
  core smoke flow.
- Checks performed: pinned Flutter prebuilt-drive source inspection; targeted
  Dart formatting; shell syntax checks; `git diff --check`; three isolated APK
  prebuilds during this diagnostic sequence, each with the emulator stopped;
  and the final end-to-end emulator run. The first two runs failed on test
  interaction timing and a premature Today scroll respectively; their causes
  were fixed before the passing run. No project-wide analyzer or unrelated test
  suite was run. Temporary Flutter Java selection was restored; the AVD was
  shut down and no emulator/build daemon remains active.
- Private latest Flutter log:
  `/tmp/everywear-full-isolated-smoke-20261116-231608-2123970.log` (mode 0600).
  Private emulator boot log:
  `/tmp/everywear-emulator-boot-20261116-231534-2122708.log` (mode 0600).
- Next: use a fresh, disposable staging signup address (or provision another
  confirmed synthetic account) to verify Auth metadata and trigger-created
  profile persistence independently. Keep any existing-account profile-row
  discrepancy under review without altering the account. Do not rerun the
  already passing core flow without a relevant code change.

## Emulator image installed; guarded run stopped for memory (2026-11-16)

- Installed the exact available SDK package `system-images;android-37.0;google_apis_playstore;x86_64` into `/home/theanarchitect/Android/Sdk` using the existing SDK Manager. The AVD's `system.img` is now present; no AVD configuration or other system image was changed.
- Reran `scripts/run_staging_emulator_smoke.sh` with the saved, mode-0600 private credentials and approved staging config. The Android 37.0 AVD booted and passed its identity check, then the script stopped at its safety threshold: available RAM during the booted-AVD check was about 3.1 GiB, below the required 4 GiB for starting the build. The wrapper shut down the emulator on exit.
- No APK build/install, signup metadata request, authenticated test login, UI test, or hosted request occurred. Existing staging records and the physical phone were untouched. No test passed or failed; emulator application checks were not run.
- After shutdown, 7.9 GiB RAM was available and 383 GiB disk remained free. No emulator/build process remains active. The SDK image installation itself completed successfully. Avoid bypassing the 4 GiB guard; a future attempt needs safer resource headroom or a separately provisioned lower-memory test AVD whose boot and app-test viability are verified first.

## Bounded unattended emulator attempt (2026-11-16)

- Current local checkout: `main`, HEAD `8a6329457634e40071000bc8e6f9509f86e354b0` before this checkpoint. Credentials and the private staging config passed the helper's outside-repository, mode-0600, schema and staging-project checks; values were not printed.
- Resource preflight passed: 7.3 GiB available RAM, `/dev/kvm` accessible, no active build/compiler/emulator, existing registered AVD `Medium_Phone_API_37.0` configured x86_64/2 GiB. No phone was used.
- Emulator launch failed before device registration. Fresh private log `/tmp/everywear-emulator-boot-20261116-214143-2090146.log` (mode 0600) reports the configured SDK root is valid but the AVD's required image directory is absent: `system-images/android-37.0/google_apis_playstore/x86_64/`. The AVD config explicitly requests Android 37 Google Play Store x86_64. A local search found no installed `system.img` under the inspected SDK roots.
- Consequently no APK build/install, controlled signup metadata request, test-account login, UI test, or staging record write occurred. There are no test passes or failures to report; all emulator checks were not run because the AVD could not boot. Existing application records and the phone were untouched.
- The runner now exports the discovered SDK/AVD roots and checks the AVD's registered name, configuration and system-image directory before launch. Its emulator boot failure is detected promptly. `bash -n` and `git diff --check` passed after this guard; no build or test suite was run.
- Blocker / next step: install the licensed SDK package `system-images;android-37.0;google_apis_playstore;x86_64` into `/home/theanarchitect/Android/Sdk` using the installed `sdkmanager`, then rerun `scripts/run_staging_emulator_smoke.sh` once after resource preflight. Do not create a replacement AVD or change the pinned AVD configuration for this retry.

## Isolated UI smoke runner package-identity failure (2026-11-16)

- The corrected run built the isolated APK and launched the activity under
  `com.stylewise.app.stagingtest`. It reached `SIGN_IN_REQUIRED` and waited
  through the configured 15-minute period. No synthetic wardrobe/outfit writes
  occurred; therefore the visible-tab, row-specific Today assertion was **not
  run**.
- The current invocation's Flutter output ended with a timeout at
  `integration_test/app_test.dart:74`, the wait for the isolated test app's
  authenticated user. The runner then reported normal-package preservation
  failure. Fresh ADB inspection found `com.stylewise.app` absent and
  `com.stylewise.app.stagingtest` still installed. The normal authenticated
  session is consequently **not verified and cannot be restored by reinstalling
  an APK**; reinstall would create a fresh local app data area. Do not reinstall
  without the owner's decision and private sign-in.
- Diagnosis: the pinned Flutter runner's
  `IntegrationTestTestDevice.start()` captures the package from the existing
  APK before calling `AndroidDevice.startApp()`. `startApp()` builds the
  isolated variant and resolves its new package ID locally, but the test
  device retains the earlier package object. Its `kill()` later stops and
  uninstalls that stale object. The current device log records the package
  manager uninstall command for `com.stylewise.app`; immediately afterward,
  `.stagingtest` remained installed. This matches the source-level stale
  package object and the observed package state. Do not treat this as a normal
  app failure or infer that the test APK had the wrong application ID: the
  produced `app-debug.apk` manifest is `.stagingtest`.
- Harness fix prepared in `scripts/run_staging_ui_smoke.sh`: build the
  staging-test APK before invoking Flutter's integration runner, inspect its
  manifest with Android `aapt`, and refuse to continue unless it is exactly
  `com.stylewise.app.stagingtest`. Flutter's initial cached package resolution
  and later teardown should then use the same test-only identity. The runner
  now captures run-scoped logs from `logcat -T 1` and checks that no normal
  package stop/removal appears.
- After that failure, the owner-directed beta-4 restoration was performed as a
  fresh install. It is version code 4 with first/last install time
  `2026-11-16 13:21:52`; its previous local session is lost and was not called
  recoverable. No sign-in was performed.
- The runner was fixed to prebuild and verify the isolated APK before Flutter
  resolves its package object. A login-free test target was then run through
  the same `scripts/run_staging_ui_smoke.sh` runner/artifact path. Its prelaunch
  record was `FLUTTER_RESOLVED_PACKAGE_ID_BEFORE_LAUNCH=
  com.stylewise.app.stagingtest`; the built APK manifest matched. The minimal
  integration test passed **1/1** and made no app/backend requests. Fresh
  device logs show every Everywear force-stop and uninstall operation targeted
  `.stagingtest`; teardown removed `.stagingtest`. Normal package version and
  first/last install timestamps stayed `4` / `2026-11-16 13:21:52`. This
  verifies package isolation and cleanup, not an authenticated app session.
- The test's sanitized runner and device logs are retained privately at
  `/tmp/everywear-full-isolated-smoke-20261116-132344-1949676.log` and
  `/tmp/everywear-a065-ui-smoke-20261116-132344-1949676.log` (mode 0600). The
  initial diagnostic run used Flutter verbose output, which prints build
  defines; those fields were redacted in the private runner log and verbose
  output was removed from the helper. No configuration value is included in
  this document.
- No authenticated smoke run was started after this correction. The normal
  package is installed fresh but signed out, and the isolated test package was
  removed by its expected cleanup. The owner asked not to start another
  authenticated run or request sign-in yet. The corrected harness now has
  demonstrated package isolation; the row-specific Today assertion remains
  unverified. Production remains untouched.
- After the test process finished, five obsolete debug APKs were moved (not
  deleted) to `/home/theanarchitect/Projects/Everywear-apk-archive-2026-11-16`.
  The archive `MANIFEST.txt` records each artifact's purpose, version, build
  timestamp, SHA-256 and the retained artifacts. All seven inventoried APKs
  were signed by the Android Debug certificate; the beta-artifacts directory
  contained no release-signed file, signing material, or checksum/report
  sidecar. Archived hashes were rechecked successfully. Kept under ignored
  `build/beta-artifacts/`: version-code-4 latest normal staging APK (previously
  installed before the runner removed its package) and version-code-3 known-good
  rollback APK. The active `.stagingtest` APK remains at
  `build/app/outputs/flutter-apk/app-debug.apk`, outside the archive.

## Full smoke preflight after beta-4 restoration (2026-11-16)

- The owner requested a new authenticated baseline before the full smoke. The
  normal package is installed as beta-4, with fresh first/last install time
  `2026-11-16 13:21:52`. Launching it read-only showed the sign-in screen, not
  Today; this confirms the previous session did not survive uninstall and the
  fresh install is not authenticated. A private screenshot of the sign-in
  screen is kept at `/tmp/everywear-normal-auth-baseline-20261116.png` (mode
  0600).
- No full smoke process was started, no sign-in was performed, and no staging
  rows or images were written. The owner was asked to sign in privately to the
  normal app and confirm that Today is visible. After that baseline is
  confirmed, the full runner will start; its live output must be surfaced
  immediately at `SIGN_IN_REQUIRED` while `Everywear UI Smoke Test (STAGING)`
  (`com.stylewise.app.stagingtest`) remains active for the owner's response.

## Full isolated staging smoke result (2026-11-16)

- Before launch, the normal beta-4 app showed its authenticated Today screen;
  the isolated package was absent. Baseline screenshot is private at
  `/tmp/everywear-normal-auth-baseline-20261116.png` (mode 0600). Package
  version/install metadata was recorded as version 4 with both timestamps
  `2026-11-16 13:21:52`.
- The corrected full runner prebuilt the isolated APK, verified its manifest,
  and recorded Flutter's prelaunch package as
  `com.stylewise.app.stagingtest`. It emitted `SIGN_IN_REQUIRED` immediately
  with the labeled app and remained active. The owner signed in privately; the
  test detected the session and passed its staging project/account guard.
- Passed: authenticated test-app session, approved staging project guard,
  synthetic wardrobe image upload and row display, authorized Storage image
  rendering, outfit confirmation image rendering (the test proceeded through
  it), and saving/querying the synthetic outfit row for the expected user and
  local date. These are staging-only records; they were preserved.
- Today refresh: the screen's fetch marker changed from **3** rows before the
  new outfit to **4** after route return. The direct query found the saved row
  for the current user/date. However, the row-specific card finder found no
  widget and timed out (`cardsBefore=0`, `cardsNow=0`,
  `savedCardVisible=false`). This assertion **failed**; it is not reported as
  passed. Source inspection shows the outfit cards are in a nested, lazily built
  list far below the top of the long Today `ListView`; the test never scrolled
  to that section. The evidence points to a test visibility gap rather than a
  failed data refresh, but a scroll-to-row assertion still needs device
  verification before calling Today complete.
- Not run because the Today assertion failed first: profile-name check and the
  test's final sign-out. The runner did clean up `.stagingtest` and reported
  that the normal package's version/install timestamps were unchanged.
- Post-run normal-app auth check: `com.stylewise.app` remained installed at
  version 4 with first/last install time unchanged, but the foreground screen
  was the sign-in page. Thus **the normal package-preservation check passed;
  the authenticated-session check failed**. The test log contains no stop or
  uninstall targeting the normal package. The reason its screen became signed
  out is unconfirmed. Screenshot is private at
  `/tmp/everywear-normal-auth-post-smoke-20261116.png` (mode 0600); do not
  infer that the normal app's session survived merely from package metadata.
- Fresh private logs: `/tmp/everywear-full-isolated-smoke-20261116-134412-1956155.log`
  and `/tmp/everywear-a065-ui-smoke-20261116-134412-1956155.log` (mode 0600).
  Staging remains the only backend contacted; no production changes occurred.

## Staging APK update/install and authenticated-session check (2026-11-16)

- The old Gradle daemon was verified idle and associated with this checkout,
  then stopped gracefully. Available memory was reassessed at 3.6 GiB with
  zero measured pressure PSI. One staging helper build succeeded (exit 0)
  using Java 21, one Gradle worker, a 2 GiB heap, staging ref
  `aftdbphdobfrshienple`, visible staging identification, and ads/purchases
  disabled. No emulator, production endpoint, or hosted mutation was used.
- APK archive and v2 signature verification passed. Artifact:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-4-aftdbphdobfrshienple-debug.apk`,
  197,334,955 bytes, SHA-256
  `97f6a2e4d18ab8a70bddcec0f4eb33eeb48072467a5bfebbe01aebe7435fc4ce`.
  Package is `com.stylewise.app`, version code 4; the debug certificate
  matches the installed app. This staging APK is not for public distribution.
- Before the update, the phone showed the normal app's authenticated Today
  screen. `adb install -r` succeeded without uninstalling or clearing data.
  First-install time remained `2026-11-15 22:31:24`; after update, the phone
  remained on Today with the staging banner and an authenticated session.
  This is an actual session restoration check for that existing account; no
  account data was intentionally modified by this build/install check.
- The old Today-card assertion is **inconclusive test observation**, not a
  demonstrated product refresh defect: its baseline was captured while Today
  was offstage, and it did not prove Today was visible after route return. The
  staging row was present for the expected account/date. Commit `48324a9`
  strengthens the test with a visible-tab baseline, row-specific card finder
  and smoke-only load markers. The revised assertion has not run on-device;
  it is not reported as fixed or passed.
- No full UI smoke was started. The isolated test package requires its own
  private sign-in. Keep the runner confined to
  `com.stylewise.app.stagingtest`; normal `com.stylewise.app` remains installed
  and signed in.
- Checks performed: daemon ownership/status, Java 21 selection, RAM/PSI
  reassessment, one staging APK build, archive integrity, package/version,
  certificate match, SHA-256, successful in-place install and visible
  post-install authenticated screen. No tests, analyzer, full smoke, or
  production operation was run for this update.
- Two unrelated formatting-only working-tree changes remain in
  `lib/presentation/purchase_tracking/purchase_tracking.dart` and
  `lib/presentation/wardrobe_management/wardrobe_management.dart`; preserve
  them unstaged.

## USB startup diagnosis and route fix (2026-11-14)

- Reviewed `main` at `849c4587c9d74211fb4edcfcb0243007619307f1`; the starting
  checkout had unrelated modified Linux/macOS generated files, which remain
  unstaged and untouched.
- Reproduced the route-construction failure with the staged startup probe on
  the attached A065. Its sanitized on-device report identified
  `_AssertionError` at `package:flutter/src/widgets/app.dart:375:10`.
  Flutter asserts there when `MaterialApp` is given both a non-null `home` and
  a `/` entry in `routes`. `MyApp` supplied `home: const AuthGate()` and
  `AppRoutes.routes`; that map registered `AppRoutes.initial == '/'` as a
  second `AuthGate`. This is the confirmed normal-app first-frame failure.
- The probe also exposed a separate probe-only issue: synchronous diagnostics
  notifications during the child app's build caused a mark-needs-build error.
  Probe notifications are now deferred until after the frame. Focused widget
  tests cover that behavior and safe source-location reporting.
- Removed the duplicate `/` entry because the root is provided by `home`;
  retained the `/home` named route used after authentication. The generic
  error-screen root action now navigates to `/home`. Added a widget regression
  test that mounts `MaterialApp(home: ..., routes: AppRoutes.routes)` and checks
  there is no Flutter exception.
- Focused route/startup tests passed **10/10**. Targeted analysis of the route
  files and regression test reported no issues. Formatting and diff checks
  passed.
- Built the normal staging APK with the approved helper, staging ref
  `aftdbphdobfrshienple`, free-beta gates on (purchases/ads disabled), Java
  21.0.13, one Gradle worker and a 2 GiB heap. The first attempt stopped before
  compilation because Flutter selected JDK 25; the retry temporarily set
  Flutter's JDK to Java 21 and cleared the override at exit. APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`,
  235,134,063 bytes, SHA-256
  `007bcee2a440d36ee04067d3877f30c65594ff51ef8bf7bd78aeb050b1365183`,
  Android debug certificate SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
  Package/version remain `com.stylewise.app`, `1.0.0-beta.1` code 2.
- Installed with `adb install -r` over the probe, preserving application data.
  After the owner unlocked the A065, the normal app visibly displayed the
  branded sign-in page with Google and email options and the STAGING ribbon.
  This verifies the corrected root now reaches app UI on this device; it does
  not verify authentication or post-login navigation. The first black capture
  coincided with the phone being `Dozing`, not a reproduced app black screen.
  Captured app-process logs contain no route assertion or fatal app crash. One
  `TimeoutException` and one `NotFoundException` warning remain in the log;
  their source was not conclusively attributed. Renderer/allocator error tags
  appeared while drawing, but the sign-in UI rendered. Do not claim all startup
  or service warnings are resolved.
- Raw logs and screenshots are retained privately under the ignored
  `.tooling/recovery/device-startup-20261114/`; they are not staged.
- Remaining: sign in with a synthetic staging account and verify the resulting
  onboarding or home screen. This confirms first visible app UI but does not
  complete account-isolation, Storage, quota, or full release checks.

## Staging sign-in verification (2026-11-14)

- Supabase CLI project listing confirmed `Everywear-staging`, ref
  `aftdbphdobfrshienple`, region `eu-north-1`, active/healthy. The CLI lists
  production `qxsdwwdrxoyxmnapuqqv` as linked and staging as unlinked; no link
  or hosted mutation was performed. The build's private public-config file
  points exactly to `https://aftdbphdobfrshienple.supabase.co`.
- A read-only GET of the staging Auth public settings returned HTTP 200 and
  advertised only `email` as an external provider. Google is disabled; email
  is enabled, signups are allowed, and `mailer_autoconfirm` is false. The
  reported Google error (“Unsupported provider: provider is not enabled”) is
  therefore confirmed as staging Auth configuration, not an Android startup
  or callback failure.
- The app calls Supabase `signInWithOAuth(google)` with
  `io.supabase.everywear://login-callback` (`lib/presentation/splash_screen/
  splash_screen.dart`). The Android manifest registers that scheme and host,
  and the device's package resolver maps the URI to
  `com.stylewise.app/.MainActivity`. This verifies local callback registration.
  The staging Auth redirect allowlist and any stored Google client ID/secret
  are not exposed by the public Auth settings response; they remain unverified.
- Staging setup required to enable Google: use a Google OAuth Web client ID
  and secret authorized for the staging Supabase callback
  `https://aftdbphdobfrshienple.supabase.co/auth/v1/callback`; enable Google in
  the staging Supabase Auth provider and store those credentials there; add
  the exact app redirect `io.supabase.everywear://login-callback` to staging
  Auth URL Configuration. If Google's consent screen is in Testing, add the
  test Google account there. The repository has no Google client credentials,
  and existing Google Cloud credentials/console access have not been supplied
  or verified. Keep all values private. Supabase's current
  [Google provider guide](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)
  describes the Web OAuth client and Supabase callback; the
  [redirect URL guide](https://supabase.com/docs/guides/auth/redirect-urls)
  covers the app deep-link allowlist.
- Google OAuth failed on device with the provider-disabled 400 response. The
  app returned to its sign-in flow; no Google identity was created. The email
  sign-in form was opened on the phone, but no test account was created because
  staging requires email confirmation and no accessible disposable test
  mailbox was available. Next: owner enters a disposable staging email/password
  on-device, confirms the email, and reports when the authenticated screen
  appears. Do not share credentials in chat.
- No provider settings, production settings, source code, or hosted data were
  changed. Payments and ads remain disabled.

## Staging email confirmation callback (2026-11-14)

- Signup previously omitted `emailRedirectTo`. A confirmation link resolving to
  `localhost:3000` is consistent with Supabase Auth falling back to its Site
  URL; the confirmation template could also construct a localhost link. The
  exact Site URL and template remain unverified: the public Auth settings do
  not include them and a read-only Management API GET to
  `/v1/projects/aftdbphdobfrshienple/config/auth` returned **401**.
- Added `signUpWithEmailRedirect`, which always sends
  `io.supabase.everywear://login-callback`, and reused the URI for OAuth and
  password recovery. `SupabaseService.initialize` now explicitly enables the
  installed Supabase Flutter SDK's auth deep-link observer.
- Source inspection of installed `supabase_flutter` 2.18.3 confirms its
  AppLinks observer accepts callback codes/tokens and calls
  `auth.getSessionFromUrl`. The Android resolver maps the custom URI to
  `com.stylewise.app/.MainActivity`. `AuthGate` uses that session/profile to
  select onboarding or home. A successful email confirmation round trip has
  not yet been observed on-device.
- Staging settings still need review/configuration: set the Site URL fallback
  to the mobile callback, allow the exact redirect, and inspect the Confirm
  signup template for `{{ .ConfirmationURL }}`. Keep confirmation enabled.
  Email auth is enabled but auto-confirm is false. Default Supabase SMTP may
  only send to pre-authorized organization team addresses; its documented
  current limit is 2 messages/hour. Use an allowed staging test inbox or
  configure staging SMTP. No SMTP or template readiness is claimed.
- The email form was advanced to **Create Account**, but no account was
  submitted and no fresh email was sent. Do not send one from the old
  installed APK before the redirect/template settings are fixed. The owner
  must provide local staging Management API access with `auth_config_read` and
  `auth_config_write`, or make the changes in the staging Dashboard and report
  completion. Never send a token or account credentials in chat.
- Targeted auth redirect and splash tests passed **7/7**. Targeted analysis
  found no errors or warnings (one existing `anonKey` deprecation info).
  Targeted formatting passed. Built and installed commit `4586cc4` with the
  approved staging helper (project `aftdbphdobfrshienple`), Java 21.0.13, one
  Gradle worker, and 2 GiB heap. APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`,
  235,141,304 bytes, SHA-256
  `84a4465f69f099f33222d4e02274d04f61f4045e87ff2f632e6a4c8ef8bb2e3b`,
  Android debug certificate SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
  The APK was installed with `adb install -r`; user data was preserved. The
  device's MainActivity is resumed, but the screen has returned to the lock
  screen after dozing. No fresh email or confirmation round trip has yet been
  run because staging URL/template configuration awaits the owner Dashboard
  update.
- Production requirements and the ordered staging email verification are in
  [`email-auth-readiness.md`](email-auth-readiness.md). Production settings
  remain untouched.

## Startup probe root-mount boundary (2026-11-13)

- Owner reports the stage probe shows its orange shell and remains at
  “Starting Flutter app” for over one minute. The repository at `a665131` has
  **no literal** `Starting Flutter app`; the nearest source string is the
  default `StartupDiagnosticState.stage == 'Starting Flutter'`. On the old
  probe, deferred-library stage 0 attached the listener and immediately copied
  that default into the shell. That label could appear after loading `main.dart`
  and before the reporting, Supabase, Hive, provider or root-mount stages. It
  was stale initial state, not proof that root mounting had begun.
- The actual normal app operation begins in `_MyAppState.initState()` when it
  calls `_initializeApp()`. That first sets `Waiting for core services`, then
  awaits the already-completed `Future<void>.value()` passed by the probe,
  attaches app-link/auth listeners, reads saved locale/theme (diagnostic-mode
  two-second timeout), sets Riverpod locale/theme, and awaits optional
  notification and reporting-preference restoration. Once preferences are
  applied, `MyApp` rebuilds its nested `MaterialApp` with `AuthGate`; the gate
  then resolves password-recovery, signed-out splash, onboarding, or home from
  auth/profile providers. None of these source paths establishes which
  operation is hanging on the phone.
- The probe shell is the outer `MaterialApp`/`Scaffold`/`Column`; the
  `ProviderScope` and `MyApp` are children of its `Expanded`. MyApp's nested
  `MaterialApp` therefore does not replace the outer orange shell. At commit
  `a665131`, the 30-second observation was a separately tapped final stage. It
  waited silently, sampled existing state once, and had no completion message
  or elapsed counter. If root mounting/`endOfFrame` was still pending, that
  later observation stage had not begun; if it completed, the unchanged stage
  label could still look like no result.
- No specific plugin/provider cause is established. Updated only this boundary:
  the probe now ignores the misleading default stage until MyApp emits a real
  stage, shows a once-per-second operation timer, and automatically starts its
  30-second observation after the nested app root's first frame. The outer
  shell continues to show the app's latest startup stage and sanitized errors;
  observation completion now produces an explicit summary. If the phone is
  stuck synchronously during root mounting, the timer's last visible value
  should stop changing; if startup is asynchronous, it should keep advancing
  while the internal stage/errors update.
- Focused probe and startup-diagnostic tests passed **6/6**. Targeted analysis
  reported **zero warnings/errors** and four existing informational `main.dart`
  lints. Targeted formatting and `git diff --check` passed.
- One new APK was built with the approved staging helper/ref, purchases and ads
  disabled, staging identity visible, Java 21, one Gradle worker and a 2 GiB
  heap. ZIP integrity and APK v2 verification passed. Path:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-STARTUP-STAGE-PROBE-debug.apk`;
  size **235,148,141 bytes**; SHA-256
  `dfb21d2aa924a7360db860e98183a5bd2c3e31fd7cbd95174d428a1aa1fdf603`.
  Package is `com.stylewise.app`, version `1.0.0-beta.1` (code 2), target 36;
  its Android Debug certificate SHA-256 remains
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
  Flutter's temporary JDK override was cleared. No installation or phone result
  for this updated APK is claimed.
- Next phone check: install this updated APK as an in-place update, confirm
  **Everywear Startup Probe (STAGING)**, and tap through the stages to mount the
  root. Observe whether the `Mounting ProviderScope and MyApp` timer advances,
  whether `Application stage` changes from `Waiting for core services` through
  preferences/settings, and whether the explicit 30-second result appears. If
  the timer freezes, capture a screenshot showing its last value. Production
  remains untouched.

## Controlled startup probe after engine-isolation result (2026-11-13)

- Reviewed current local source at `7154b7b` on `main`. The owner reports the
  ENGINE-ISOLATION APK displayed its blue `EVERYWEAR ENGINE TEST` screen on the
  phone. That confirms this phone can launch the installed Flutter activity,
  run the minimal Dart entrypoint, and draw a Flutter first frame. It narrows
  the fault to code/dependencies omitted by that minimal entrypoint; it does
  not identify the exact failing component. No device logs are available.
- The isolation target imports only Flutter Material and calls `runApp`
  directly. Normal `main.dart` has a large eagerly imported app graph. Source
  inspection shows the current diagnostic startup calls
  `WidgetsFlutterBinding.ensureInitialized()` and `runApp()` in the same
  `runZonedGuarded` callback; it does not defer the first frame, and service
  futures are started but not awaited before `runApp`. This makes a service
  wait less likely to explain a missing frame in the current source, but leaves
  app-library loading/static initialization, root construction, providers,
  global handlers and routing as hypotheses rather than confirmed causes.
- Added `lib/startup_stage_probe.dart`. It imports the app library deferred,
  paints an orange diagnostic shell first, and then exposes separate manual
  stages for app-library loading, reporting, staging Supabase, Hive, root-widget
  construction, root mounting/first frame, and a 30-second observation of
  MyApp startup. The shell stays outside the nested application tree. Errors
  show sanitized exception type and an allowlisted `package:`/`dart:` source
  location; no exception message, configuration, token or user data is shown.
  Binding initialization and `runApp` share the same guarded zone. The staging
  helper gained an exclusive `EVERYWEAR_STARTUP_STAGE_PROBE=true` mode with a
  distinct app label and artifact suffix. The helper still validates the exact
  approved staging project, staging banner, purchases disabled and ads
  disabled.
- Focused tests passed **4/4** (probe first-frame shell/sanitizer and existing
  diagnostic screen/timeout tests). Targeted analysis of five Dart files had
  **zero warnings/errors** and four pre-existing informational lints in
  `main.dart`. `dart format`, helper `bash -n`, and `git diff --check` passed.
- One staging probe APK was built after those checks using Java 21, one Gradle
  worker and a 2 GiB heap. The previous `app-debug.apk` was preserved in the
  ignored `.tooling/recovery/` directory before the helper overwrote it.
  Artifact:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-STARTUP-STAGE-PROBE-debug.apk`;
  size **235,145,437 bytes**; SHA-256
  `984b69066534a3c852a0efd9b204ff4424bc8bbc9bf16d3c7ede0aba2424a6b1`.
  ZIP integrity and APK Signature Scheme v2 passed. `aapt` confirms app label
  `Everywear Startup Probe (STAGING)`, package `com.stylewise.app`, version
  `1.0.0-beta.1` (code 2), target SDK 36. Its debug certificate SHA-256 is
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`, the
  same as the successful engine-isolation APK. The APK contains the probe
  stage/badge strings; this verifies packaging, not execution on the phone.
- Flutter's temporary JDK setting was cleared after the build. No production
  service was contacted or changed, and no installation/runtime result is
  claimed for this new APK. Next phone check: install this same-package,
  same-certificate APK as an update without uninstalling or clearing data.
  Confirm the launcher label, then confirm the orange
  `EVERYWEAR STARTUP PROBE (STAGING)` shell appears before tapping any stage.
  Tap `Run next stage` once per line in the displayed sequence and record the
  last completed stage plus any sanitized error. If the orange shell never
  appears, confirm the probe label/file was installed; a native launch screen
  still requires device logs to localize the failure.

## Physical-device startup investigation (2026-11-13)

- Reviewed source at `b23a2e0d71d4ec99f234a15d6e890313c35ad0dc` on `main`.
  `adb devices -l` reported no attached devices, so the logo-to-black-screen
  symptom could not be reproduced and no device logcat was captured. The
  startup source review preceded the separate APK rebuild recorded below.
- Confirmed startup defect in the reviewed source: `main()` awaited orientation
  setup and essential service initialization before `runApp()`. That path
  awaited stored analytics preference, Sentry initialization (then unbounded),
  Supabase (10-second timeout), and Hive (5-second timeout). Therefore a
  stalled plugin/service could prevent Flutter's first frame entirely. This is
  a confirmed first-frame gate and a credible cause of a launch-screen-to-black
  transition; it is **not confirmed as the physical device's specific failure**
  without device logs.
- Changed startup to call `runApp()` immediately, render the existing branded
  loading screen while services initialize, bound Sentry initialization to five
  seconds, and attach auth/billing-return listeners after Supabase bootstrap.
  Billing background initialization remains after essential bootstrap and the
  free-beta config keeps it disabled. Added a focused test asserting that the
  startup screen paints while the injected service future is still pending.
- Focused Flutter tests passed **2/2** (`main_startup_test.dart` and
  `app_import_smoke_test.dart`). Targeted analysis of those tests and
  `lib/main.dart` completed with **five info diagnostics and no warnings or
  errors**; the diagnostics are existing informational lints. Targeted Dart
  formatting completed, and `git diff --check` passed after the documentation
  update. The later APK rebuild below verifies archive/signature only; no
  device reproduction, install, or runtime verification was performed. The
  startup fix is not confirmed on the reported device.

### Audit finding classifications

- **Confirmed:** `android/app/build.gradle` (`namespace` and `applicationId`),
  `android/app/src/main/AndroidManifest.xml` (`.MainActivity`), and
  `android/app/src/main/kotlin/com/everywear/app/MainActivity.kt` (`package
  com.stylewise.app`) agree on `com.stylewise.app`.
  The Kotlin file's directory path differs from the declared package but does
  not change its compiled class package. Do not change application identity.
- **Confirmed:** the loading image referenced in `lib/main.dart:390` exists in
  the existing staging APK. `pubspec.yaml:75-77` bundles `assets/images/` and
  `assets/icons/`; `assets/env.json` is neither listed as an asset nor loaded
  from app source. The APK contains the startup image and not `assets/env.json`.
- **Confirmed:** tracked `assets/env.json` has obsolete production-project
  configuration and a Stripe test publishable value; source checks found no
  runtime reference to it. Its provider-secret fields are empty. Do not use this
  file for builds; staging configuration comes from
  `scripts/build_uptodown_free_beta.sh` and its separate private config. The
  publishable value is configuration, not a server
  secret, but the file is stale and should be removed in a separately reviewed
  cleanup once its ownership/use is confirmed.
- **Confirmed:** `pubspec.yaml` has no Stripe SDK dependency and app source has
  no Stripe client call; the `android/app/proguard-rules.pro` Stripe
  keep/dontwarn entries are stale configuration. The legacy
  `create-subscription-payment` function is a
  separate deployed-backend retirement concern already documented in
  `recovered-supabase-reconciliation.md`.
- **Confirmed:** `lib/routes/app_routes.dart` registers the premium route and
  profile/upgrade widgets link to it. In the free-beta build,
  `lib/services/revenuecat_service.dart` and
  `lib/services/revenuecat_web_checkout.dart` disable purchases; the Uptodown
  card in `lib/presentation/premium_upgrade/premium_upgrade.dart` shows
  the localized unavailable explanation and does not expose a checkout button.
  This is an unavailable screen, not an absent premium route.
- **Confirmed:** Monetag/AdMob are not initialized integrations. The beta
  helper sets the free-beta gate and ads disabled;
  `lib/services/ads/ad_service.dart` keeps the neutral ad service disabled. No
  real or placeholder ad is shown.
- **Partially correct:** manifest camera and location permissions correspond to
  `outfit_capture_flow.dart`, `photo_capture_section.dart`, and
  `services/weather_service.dart`. Notification boot receiver is registered in
  the manifest, while `services/notification_service.dart:221` schedules with
  `inexactAllowWhileIdle`; exact-alarm and old
  external-storage declarations have no direct app-code request/use found and
  need a separate manifest-minimization review. They do not explain startup.
- **Confirmed:** `.github/workflows/android-ci.yml` runs Flutter analysis,
  tests, an unsigned release AAB
  compile, and Deno tests/lint/type checks. Its Android compile has no staging
  Supabase defines and is compile-only, not a staging runtime check.
- **Outdated:** `ENVIRONMENT_SETUP.md` (including its partial SQL setup block)
  instructs creating a new Supabase project,
  applying a partial hand-written schema, configuring client-side Gemini, and
  setting up Codemagic. It is historical guidance and conflicts with the
  recovered production/staging migration workflow. `docs/release-setup.md`
  describes a future paid release path; it is not the free-beta build recipe.
- **Unverified:** no physical-device logs, install/startup, permission prompt,
  network outage, or account flow was observed in this pass. No production
  behavior was tested or changed.

## Corrected staging APK rebuild (2026-11-13)

- Rebuilt current `main` after startup fix commit `0cbf2ff` with
  `scripts/build_uptodown_free_beta.sh`, explicit approved project ref
  `aftdbphdobfrshienple`, and the private mode-0600 staging config. The helper
  forces purchases and ads off and enables the visible staging banner.
- Used installed Java 21, the project's `org.gradle.jvmargs=-Xmx2G` and
  `org.gradle.workers.max=1`. Build completed successfully in **31.2 seconds**.
  Flutter's temporary JDK 21 override was cleared afterward; `flutter doctor`
  again selected the pre-existing Android Studio JBR 25.0.3 default.
- APK path:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`;
  size **197,317,047 bytes**; SHA-256
  `91a61c5226695a1a99def3de69350c7aed3292698f5de9c1adfb93453028dbaa`.
- `unzip -t` passed. `aapt` confirms `com.stylewise.app`, version
  `1.0.0-beta.1` (code 2), target SDK 36. `apksigner verify` passed APK
  Signature Scheme v2 with the Android Debug certificate SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
  This is still a controlled staging test APK, not a public-release artifact.
- The old same-path APK was preserved at ignored
  `.tooling/recovery/Everywear-staging-before-startup-fix.apk`. No device was
  attached, so startup, onboarding/sign-in, and the black-screen symptom remain
  unverified. No production or hosted project was changed.

## Startup diagnostic build (2026-11-13)

- Added an opt-in `EVERYWEAR_STARTUP_DIAGNOSTICS` Dart define. The staging
  helper accepts it only as `true`/`false`, always retains the approved staging
  URL guard, and names diagnostic output separately. The diagnostic build has
  its own orange badge, current startup-stage panel, sanitized initialization
  failures, and a 30-second timeout screen. It captures Flutter framework,
  platform-dispatcher and zone-unhandled failures by exception type only.
- Reviewed Android launch configuration: manifest launches `.MainActivity` via
  `LaunchTheme`; the day launch background is white, night launch uses the
  system background, and `NormalTheme` uses the system background. No custom
  native splash artwork is declared in the launch drawable. Android may show
  its app icon in the OS splash before Flutter paints. The Flutter diagnostic
  badge only proves the Dart widget frame was drawn; its absence cannot
  distinguish native Activity/plugin, Flutter engine/Dart entrypoint, or
  first-frame rendering failure.
- Focused diagnostic/startup/import widget tests passed **4/4**. Targeted
  analysis of five changed Dart files completed with **four info diagnostics
  and no warnings/errors**. Targeted Dart formatting made zero changes; helper
  `bash -n` and `git diff --check` passed.
- One build completed with the approved helper and project ref
  `aftdbphdobfrshienple`, Java 21, one Gradle worker, 2 GiB heap, staging banner
  enabled, purchases and ads disabled. Flutter's JDK override was cleared and
  the default Android Studio JDK selection was verified restored.
- Diagnostic APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-STARTUP-DIAGNOSTIC-debug.apk`;
  size **235,132,619 bytes**; SHA-256
  `7817112fc1f1d7380f04b4e5fa6be86b9b9063df4e639cfb773bbcb70d2b0451`.
  `unzip -t` and `apksigner verify` passed; `aapt` confirms
  `com.stylewise.app`, version `1.0.0-beta.1` (code 2), target SDK 36, Android
  Debug certificate SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`. The
  diagnostic banner and timeout strings are present in the compiled APK.
- Wireless ADB pairing remains unsuccessful per owner direction; no further
  pairing attempt was made. No physical device/runtime result is claimed.

## Native launch / engine isolation (2026-11-13)

- Owner reports the diagnostic APK still shows a centered Everywear logo on
  white for over a minute, without diagnostic UI. No device logs are available.
- Source evidence points to the Android launch screen, not the app's Flutter
  loader: the manifest starts `.MainActivity` with `LaunchTheme`; its day-mode
  drawable is a plain white layer with no image, while the Flutter app's
  non-diagnostic loader is green and the diagnostic screen is navy/orange. The
  launcher icon is the Android adaptive icon. Android's system launch screen
  can show that icon centered over the launch background. This is a strong
  match, not direct screenshot/runtime proof.
- The manifest uses Flutter's `MainActivity` (`FlutterFragmentActivity`). App
  source has no `deferFirstFrame`, `allowFirstFrame`, native splash preserve or
  remove calls. In the diagnostic entrypoint, `WidgetsFlutterBinding` is
  initialized inside the `runZonedGuarded` callback and `runApp` is called in
  that same callback/zone. Essential services are started as a future, then
  `runApp` is invoked without awaiting them; Sentry initialization occurs after
  an async preference read. Source inspection therefore does not explain a
  missing first Flutter frame.
- The previous diagnostic build used the helper with
  `EVERYWEAR_STARTUP_DIAGNOSTICS=true`; the helper writes that value as a Dart
  define and its `STARTUP-DIAGNOSTIC` output suffix is selected from the same
  flag. The archived APK contains the diagnostic screen strings. This confirms
  the intended build configuration and code payload, not that the phone
  executed that entrypoint or installed that exact file. The owner-observed
  absence of the badge remains ambiguous without device logs.
- Added an isolation entrypoint at `lib/startup_engine_test.dart`. It imports
  only Flutter Material, calls `runApp` directly, and renders a blue screen with
  `EVERYWEAR ENGINE TEST`; it does not import `main.dart`, providers, services,
  Sentry, Supabase, or the diagnostic/startup wrappers. The staging helper has
  an exclusive engine-test mode that selects this target and sets the Android
  app label to `Everywear Engine Test (STAGING)`, while retaining application
  ID `com.stylewise.app`, staging project validation, free-beta gates and the
  debug signing key.
- Focused isolation widget test passed **1/1**; targeted analysis reported no
  issues. Targeted formatting, helper `bash -n`, and `git diff --check` passed.
  The first Gradle attempt stopped at manifest merge because the new app-label
  placeholder replaced Flutter's `applicationName` placeholder. This was
  corrected by merging the placeholder into the existing map; the subsequent
  build completed and produced the APK below.
- Isolation APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-ENGINE-ISOLATION-debug.apk`;
  size **197,317,047 bytes**; SHA-256
  `5a51428a8f8793adfdd7afde71f54ec269dbbbccfccd5441f68180f80e4a119e`.
  Archive integrity and APK Signature Scheme v2 verification passed. `aapt`
  confirms label `Everywear Engine Test (STAGING)`, package
  `com.stylewise.app`, version `1.0.0-beta.1` (code 2), target SDK 36, and the
  same Android Debug certificate SHA-256 as the diagnostic build. Its kernel
  contains the engine-test screen string and omits the normal startup/diagnostic
  stage strings. No physical device was attached; this is not a runtime result.
- Interpretation: if this APK reaches the blue screen, Android launch,
  FlutterActivity/engine, the isolated Dart entrypoint, and a Flutter first
  frame work; the failure is in the normal application entrypoint/startup path
  or its dependencies. If it remains on the native launch screen, the fault is
  before this minimal Dart UI: native Activity/plugin registration, engine or
  Dart startup, first-frame rendering, or failure to install/launch this exact
  labelled package remain candidates. Neither result alone proves a production
  fix or tests backend behavior.

### Preserved local changes

The pre-existing generated changes remain untouched and unstaged:
`linux/flutter/ephemeral/.plugin_symlinks/{connectivity_plus,package_info_plus,sentry_flutter,share_plus}`;
untracked generated `linux/flutter/ephemeral/.plugin_symlinks/geolocator_linux`;
and the two `macos/Flutter/ephemeral` generated configuration files. No
platform directory was deleted or broadly ignored.

Last updated: 2026-11-13

## Current classification

Recovery is in progress on `main`. The reviewed startup-gate source was at
`b23a2e0`; current source includes the first-frame fix in `0cbf2ff`, and the
corrected staging APK evidence is recorded above. The earlier `aeda62a`
checkpoint restricts the staging APK helper to the exact approved project
ref. The preceding `f71efd8` checkpoint records staging deployment/hosted
checks and the visible staging banner. A sequential full Flutter suite passed
**94/94** on a prior application checkpoint. A subsequent provider-test isolation change passed
its focused file **6/6**; the full suite was not repeated after that change.
The earlier full run printed nonfatal binding/Supabase initialization
diagnostics. A full project analysis completed with **248 info diagnostics and
no warnings or errors** at that prior checkpoint. Previous local checks include
Deno pure tests/lint/type checks and a JDK 21 unsigned release AAB build, but
that AAB predates the Uptodown free-beta configuration and is not a beta
artifact. A staging-only debug APK is now built and verified; it has not been
installed or run on a physical device.

An owner-approved isolated Everywear staging project now has the reviewed
migrations and eight Edge Functions. Synthetic hosted checks verified Auth,
PostgREST isolation, private Storage, quota enforcement, account deletion, and
user-filtered Realtime (details below). A staging APK is built and archive/
signature checked, but has not been run on a device. Production remains
read-only and unsafe for the beta because its
recovered RLS, public buckets, and deployed Edge Function versions remain
unchanged. Upload signing, release URLs/artwork, and physical-device behavior
also remain unresolved. Google Play publication is deferred.

## Approved staging preflight (2026-11-12)

- Authenticated `supabase projects list --output json` confirmed `Everywear-staging`,
  ref `aftdbphdobfrshienple`, region `eu-north-1` (North EU/Stockholm), in the
  existing Everywear organization `ioohmyibnlzfltqcsnkg`. The owner confirmed
  the organization is on Free and approved this project. The CLI list does not
  expose plan metadata; no billing API/plan check is needed to reconfirm this
  owner-approved target. No paid upgrade, add-on, or extra project was made.
- `supabase db query --read-only --remote=aftdbphdobfrshienple` confirmed
  PostgreSQL 17.11; there are no app `public` tables, app functions, migration
  history rows, Storage buckets, or app Storage policies. Supabase-managed
  `storage` relations exist with RLS enabled. The explicit project list and
  query output identified the target as staging, never production.
- `supabase functions list --remote=aftdbphdobfrshienple` initially returned
  no deployed functions. The reviewed nine migrations were then applied in
  order to staging, and a subsequent migration list matched all nine local and
  remote versions. The migration chain includes the entitlement prerequisites,
  security fixes, atomic AI quota operations, and private image buckets.
- Read-only production policy inspection confirmed the exact two public image
  policies are bucket-scoped (`avatars` and `wardrobe-images`). The new final
  migration creates those buckets privately when absent, preserves existing
  bucket metadata when present, and applies authenticated owner-folder policies.
  Applying it to production later still requires legacy-reference conversion
  and the compatible client rollout.
- The main checkout remains explicitly linked to production. Staging changes
  used a separate detached worktree and explicit
  `--remote=aftdbphdobfrshienple` targets. No staging credentials were printed
  or written to tracked files. The CLI labels the staging project's main branch
  `production`; this is a branch environment label within staging, not the
  recovered Everywear production project.
- Added `20261112140000_private_image_bucket_security.sql` after the entitlement
  and quota migrations. It creates missing image buckets privately, preserves
  existing bucket metadata except public visibility, removes the exact
  production-observed public/legacy owner policies, and enforces owner-folder
  access for select/insert/update/delete. The storage regression fixture and
  staging/production rollout docs now reference the migration. Production must
  still wait for client rollout and stable-reference conversion.
- Read-only production policy lookup confirmed the two public image policies
  are bucket-scoped (`avatars` and `wardrobe-images`). The private-bucket
  migration drops those policy names and replaces them with owner-folder
  policies. Production still requires compatible client rollout and stable
  reference conversion before any private cutover.

## Staging deployment and hosted checks (2026-11-12)

- All nine ordered migrations are present in staging migration history. Eight
  functions are active with gateway JWT verification: `ai-suggestions`,
  `analyze-clothing`, `check-and-request-suggestion`, `delete-account`,
  `generate-ai-insights`, `style-coach`, `today-suggestion`, and
  `verify-purchase`. No webhook, payments, ad integration, or provider secret
  was deployed/configured. The CLI's `production` environment label is the
  staging project's branch label; the recovered Everywear production project
  was not targeted.
- Synthetic API checks passed in separate phases: security/Auth/PostgREST and
  quota checks **52/52**; filtered two-user Realtime **5/5**; Storage ownership,
  private URL delivery/replacement, object deletion, and account deletion
  **31/31**. A read-only aggregate query after cleanup found zero synthetic
  users, image objects, wardrobe rows, or outfit rows. These are live staging
  integration results, not production results.
- AI endpoint checks confirmed unauthenticated and invalid JWT requests are
  denied. Authenticated model-backed requests returned the expected 503
  `AI_UNAVAILABLE` without consuming allowance because no provider key was
  configured. Purchase verification likewise failed closed with 503. No paid
  inference, real purchase, or advertising request occurred. Model quality,
  billing lifecycle, device behavior, and provider-backed paths remain
  unverified.
- The integrated smoke runner had two initial combined-run failures in test
  assertion ordering and Realtime payload parsing. Both defects were fixed;
  the final separated phases all passed. The complete `all` mode was not
  rerun as a single invocation.
- Added a staging-only visible app banner and wired the private-config APK
  helper to set it. The focused banner widget test passes **2/2**. The helper
  was run against the exact staging project and private config. The resulting
  APK is `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`, **197,317,047 bytes**, SHA-256
  `63e279122694cea641dace7bb963e642b9ebb777d03fdc97e0ee402ec7f2f73e`.
  `unzip -t` passed; `aapt` reports `com.stylewise.app`, version
  `1.0.0-beta.1`, version code `2`, target SDK 36; `apksigner verify` passed
  for APK Signature Scheme v2 with Android Debug certificate SHA-256
  `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`.
  This is a staging test APK signed with the debug key, unsuitable for public
  distribution or signing continuity. No physical Android device is attached,
  so installation/runtime checks remain pending.
- Main checkout linkage is unchanged; staging operations used the detached
  worktree and explicit ref. The synthetic test's service-role config was
  deleted after the checks. Only a mode-0600 URL/anon-key config remains
  outside the repository for the APK helper. No production or Clameo mutation
  occurred.

## Checks from this continuation

- Targeted Dart formatting completed with **0 changes** across the main entry,
  banner, and banner test. `bash -n` passed for the APK helper; Python AST
  parsing passed for the hosted smoke runner; `git diff --check` passed.
- The staging-banner widget test passed **2/2** with
  `.tooling/flutter/bin/flutter test --no-pub --concurrency=1
  test/widgets/staging_build_banner_test.dart`. Two earlier attempts exposed
  incorrect test finders (painted banner text and Flutter's built-in debug
  banner); the test was corrected and the final run passed. This did not run a
  build, emulator, analyzer, or broader test suite.
- A targeted analyzer pass over `lib/main.dart`, the staging banner, and its
  test reported **5 info-level diagnostics** in existing `main.dart` lines and
  no warnings/errors; the banner/test introduced no reported diagnostics.
- Tightened the APK helper to accept only the approved staging project ref.
  `bash -n` passed, and a no-build guard check with the unrelated Clameo ref
  exited 2 with the expected refusal. `git diff --check` passed.
- Build retry diagnosis: this turn's first build attempt failed before
  compilation because Flutter preferred Android Studio JBR 25.0.3 over the
  shell's Java 21 `JAVA_HOME`. Flutter's own selection order confirmed that
  Android Studio takes precedence. Setting `flutter config --jdk-dir` to the
  installed Java 21 path made Flutter report Java 21; the one-worker build
  then completed in **52.3 seconds**. Available RAM was about 6.6 GiB before
  build and 4.7 GiB at peak observation; swap remained full, with no unsafe
  memory pressure. The temporary JDK preference was cleared afterward.
- The requested APK exists at the exact path/hash above. `adb devices -l`
  still lists no physical device; do not claim runtime verification. See
  [`uptodown-free-beta.md`](uptodown-free-beta.md) for install instructions.

## Uptodown billing checkpoint (2026-11-12)

- Current branch source has monthly and annual plan labels, but no literal
  price, subscription currency, RevenueCat product/package ID, entitlement ID,
  or trial duration. Native Play prices use provider `priceString`; Uptodown
  product options/prices are shown by RevenueCat's hosted page. The old
  hardcoded €7.49/month and €69.90/year strings existed in `f9c562f` and were
  removed during the later RevenueCat repair; they are not verified current
  terms. The exact references and quota/restriction discrepancies are in
  [`billing-readiness.md`](billing-readiness.md).
- Added explicit distribution/environment config and strictly validated
  `pay.rev.cat` purchase links. Release builds can use production links only;
  non-release builds can use sandbox links only. The app appends the current
  Supabase UUID and rejects unconfigured/unsupported billing rather than
  falling back to a placeholder offer.
- Registered `io.supabase.everywear://billing-return` on Android and iOS. Link
  and browser-resume paths refresh the authenticated backend verifier and
  invalidate account tier/profile state. Callback arrival alone never grants
  premium. Refresh requests are serialized across account changes and duplicate
  callbacks are bounded. Added RevenueCat SDK management-link access behind
  exact official-host/path validation.
- Added a server-required `REVENUECAT_EXPECTED_ENVIRONMENT`. Purchase snapshots
  require the exact entitlement's product subscription to explicitly match
  production/sandbox `is_sandbox`; webhooks with missing or mismatched
  environments are ignored. Keep sandbox in an isolated staging RevenueCat and
  Supabase environment.
- Added focused routing, UUID, cancellation/return, no-config, management URL,
  backend-verification, and all-language unavailable-state tests. Flutter tests
  passed 14/14, including a rerun after checkout cleanup was hardened for an
  account switch during browser launch; Deno environment
  and entitlement tests passed 7/7. Targeted Deno lint passed six changed
  files; cached Deno checks passed for the changed verifier and webhook.
  The latest targeted Dart analysis completed with 7 informational lint
  findings and no warnings/errors. `dart format` reported no changes to the
  final service edit, and `git diff --check` passed. No live checkout, provider
  API or production database operation was performed.
- Stripe activation, RevenueCat Billing catalog/links, exact entitlement,
  public Android SDK key and server-side expected-environment configuration are
  still owner/provider inputs. The locally changed verifier/webhook are not
  deployed. No purchase or refund evidence is claimed.

## AI model, cost, and quota checkpoint (2026-11-12)

- Corrected the earlier model-retirement finding in [`ai-cost-review.md`](ai-cost-review.md): Google AI Studio currently lists `gemini-2.5-flash-lite` as not deprecated, with no shutdown date, but access is limited to qualifying existing 2.5 users. OpenRouter independently lists canonical `google/gemini-2.5-flash-lite`, image input, current $0.10/$0.40 per million token rates, and no public expiration date. This confirms public documentation/catalog status only; Google account eligibility, both provider keys, OpenRouter serving capacity, and output quality remain unverified. No paid inference or credential inspection occurred.
- Added a local-only shared quota migration and integrated reservations into clothing analysis, photo advice, daily outfits, style coaching, and insights. Provisional server policy is 20 monthly / 3 daily / 1 per UTC minute for free and 200 monthly / 20 daily / 5 per UTC minute for premium, plus 1/3 in-flight request caps. Counters use server-derived subscription state and serialize via a per-user row lock; duplicate user/request IDs are rejected across endpoints. Provider errors, timeouts, invalid responses, and interrupted calls retain their consumed action. Requests are bounded to one JPEG ≤3 MB and ≤1280×1280, bounded JSON/prompt/response bytes, 200–800 output tokens, 20-second provider timeout, and no application retries or model fallback. OpenRouter provider fallback is explicitly disabled and rate capped.
- Added localized remaining/exhausted/unavailable states and kept manual entry and deterministic/non-AI outfit features available. The daily-suggestion failure path now surfaces a localized status instead of silently returning no result. Insights in-memory caching remains a convenience; all cache misses/refreshes still pass server quota.
- Checkpointed the AI quota, client, tests, and cost-review work in local commit `4758b91` (`Add bounded server-side AI quotas`). Linux/macOS generated platform modifications remain outside the commit.
- Added migration/security fixtures, two-session quota concurrency harness, bounded request/response, image bounds, timeout, OpenRouter request, request-ID, allowance parsing, and localization tests. Focused unit tests were executed as listed below; the database fixtures require an isolated disposable non-production database and remain unexecuted.
- Updated [`ai-cost-review.md`](ai-cost-review.md) with fresh official model/pricing evidence and revised examples: approximately $0.00722 light, $0.04916 typical, $0.16720 heavy, and a modeled $0.405 premium monthly cap; 10,000 free accounts all exhausting allowance would be about $405/month. These are assumptions, not observed use. The €2.99/€24.99 proposals remain potentially plausible against inference alone, but net sustainability is unproven after merchant-country processing, tax, RevenueCat terms, hosting/storage, support, and refunds.
- Clarified that `$0.405` models one provider execution per reserved action, not a guaranteed invoice ceiling: OpenRouter documents provider retries generally, and its billing behavior for failed upstream attempts under this request remains unverified. Provider-side spend limits and staging invoice measurement are still needed.
- Added [`ai-quotas.md`](ai-quotas.md) with reset semantics, consumed-action rules, migration prerequisites, local-only staging sequence, and fail-closed rollback. No migration, provider setting, production record, or hosted function was changed.
- Tightened the quota RPC premium rule: active, grace-period, and cancelled statuses all require a non-null future expiry; missing expiry fails closed to free. Added a pgTAP assertion for this case and updated the quota notes. Same user/request UUID is unique across all five endpoint names, so switching endpoints cannot replay it. The migration remains local-only and awaits exact recovered-schema reconciliation.
- Focused verification completed on 2026-11-12: Deno lint passed on 16 changed Edge Function files; 34 AI-focused Deno tests passed; cached Deno type-check passed for all five AI handlers and the allowance endpoint. Flutter’s five focused test files passed 12/12 tests. Targeted Dart analysis covered 20 changed app files and returned 39 informational lints, with no warnings or errors. Targeted Dart formatting changed 0/24 files; Deno formatting checked 16 files and formatted the changed OpenRouter handler. Static pgTAP plan/assertion count is 29, `bash -n` passes for the concurrency fixture, and `git diff --check` passes.
- Database isolation/concurrency fixtures remain unexecuted because no disposable non-production database was supplied or started; production was not queried for these tests. No full Flutter suite, project-wide analyzer, Android build, emulator, Docker, deployment, hosted mutation, paid inference, or purchase was run. Provider catalog/documentation facts are verified, but Google account eligibility/key, OpenRouter key/routing/account access, real response quality, and deployed quota enforcement remain unverified. Before staging, obtain authorized staging Supabase and provider configuration; reconcile rather than apply the migration against production.
- Next exact step: obtain a disposable non-production Supabase database and reconcile the proposed schema against the recovered project's metadata read-only; only then run the migration fixtures in disposable staging. Separately confirm qualifying Gemini API access and paid tier plus OpenRouter account/routing access, then measure synthetic/staging output quality and token/call behavior. Production remains read-only; no provider setup, schema, deployment, or commercial decision is changed here.

## Local checkpoints

- `0cbf2fff0a9ab1b70ea4b1e5e782a316c72bee26` — render a branded first frame
  before essential service initialization, defer auth and billing-return
  listeners until Supabase bootstrap, and cover pending startup with a focused
  widget test. Device symptom remains unverified without an attached device.
- `aeda62a` — restricts the staging APK helper to
  `aftdbphdobfrshienple` and records a no-build rejection check for an
  unrelated project ref.

- `f71efd8` — records the staging migration/function deployment and separated
  hosted integration results; adds a visible staging banner, staging APK
  helper wiring, synthetic hosted smoke runner, and focused widget coverage.

- `e3de01c` — prepares Uptodown hosted checkout with explicit production and
  sandbox configuration, authenticated Supabase identity, callback-based
  backend verification, management links, and exact server environment checks;
  adds focused Flutter and Deno regression coverage. Flutter checkout tests
  passed 14/14 and targeted Dart analysis reported seven infos only.
- `395255ba2937c31fd2d486e0ec823c3b0273f125` — recovered-schema-aligned
  security proposal, local-only pgTAP fixture, private image cutover review,
  and protected Edge Function cleanup.
- `5ba8204203c24e98e50e57188ed5d13d614e89db` — expiry-aware entitlement
  decisions, client/offline and notification fixes, release-only shim, removal
  of obsolete placeholder screens/services, and focused tests.
- `fe0a5c5fc0b3463a8014a869f74927b6aaf71bef` — setup/release documentation,
  reconciliation updates, resumable goal status, and sequential Flutter/Deno CI.
- `ae02ee0359ef46f8e344fdd27579ee14f345e415` — recorded the recovery checkpoint
  IDs in the release status.
- `ed2f491f071ee823f5e87823b1893a91614dbf7c` — subscription expiry parsing
  now fails closed for malformed server values, with focused unit cases.
- `1f9261f7035488e388b2f29b814c70591fbd1d5e` — removes replaced/deleted
  owner-scoped wardrobe image objects and cleans new uploads after failed saves.
- `5f2bef06cddcf7f4f7948a4d152a28faa5bf17b2` — removes unreachable ad
  placeholder startup/layout/action code and the blank home banner.
- `5b12e53897c9a8180e269e6f1952404b0f053cd2` — serializes RevenueCat identity
  changes with purchase/restore verification, centralizes session cleanup, and
  paginates/checks account-deletion outfit links.
- `1b7dcc3dfc4dd22d4f2b6f98fbe04d0fc8a0f8d3` — keys private image cache by
  stable owner-scoped references and clears it during account cleanup.
- `d70bb6d6984c436239043757c4ef66b0df155054` — recognizes authenticated
  Supabase Storage URLs and evicts private image bytes from both cache layers.
- `c8cff417c982015871e0f70fb9d35753c255f081` — adds disposable-local Storage
  isolation coverage for anonymous access, private bucket state, both account
  owners, uploads, and deletion; records fresh read-only production metadata.
- `281efa2a5c49f1a7dcc9d5e646e42bebefe0eb66` — pages in-app full-reset outfit
  links, bounds delete batches, clears private image cache before partial remote
  cleanup, and adds three passing pure helper tests.
- `2d7d9f3f928311bcdbe2b0e1d93db1bb63e6d9a0` — schedules the next reminder by
  IANA-zone calendar date across DST and adds four passing time-boundary tests.
- `84d2923504c82d616f82329167ffc8120d9a9bd6` — records the unavailable
  `adb`/physical-device verification prerequisite.
- `192a8f2275a043ef11b7b78e8197b3d5e6c9015a` — records 49 passing current
  Flutter tests, clean targeted analysis, and the rebuilt final-source unsigned
  AAB with archive/hash verification.
- `9f1a54a9d669a5c8114ebf99f4dc547c980b434f` — records the prior verification
  checkpoint and preserves the full resumable goal checklist.
- `9c4ade3e88f1d19d5e0c6009b2874052f16be52f` — reconciles the recovery plan
  with current test, analyzer, database, and AAB evidence.
- `6ca57003c881ddc15aa3c2a9ad19dc8ce2e1d1c0` — replaces the local-path and
  caller-URL outfit AI flow with bounded compressed image bytes, authenticated
  validation, and focused Dart/Deno tests; errors returned to clients are
  generic.
- `7abb46d841e0210cc11cc319b75736c76ae88cf3` — records the coordinated AI
  image-flow checkpoint and deferred production rollout.
- `1a088cf12a5c120037cafd97a57c5aa08381ec75` — records the latest project-wide
  analyzer result and its unresolved diagnostics.
- `b9f4ddc3ca64ce0977b28746d4ac75d929080cc3` — localizes the password-recovery
  action and adds a three-locale regression test.
- `42512f64b50813c17d473cf775d0a1e45024c379` — fixes challenge history's
  nested relation mapping, preserves backend failures for a retry state, and
  adds focused merge/localization tests.
- `317e22e10e40a441b8768d0a98ec9a2630007704` — surfaces learning outages,
  replaces the “coming soon” action with explicit saved completion of the
  existing module summary, and adds failure/success widget coverage.
- `e2085cb` — promotes the PDF image decoder to a direct runtime dependency,
  updates the RevenueCat purchase call to the current SDK API, and records
  focused image/billing tests plus clean targeted analysis.
- `ec4e018` — records resumed focused test, analysis and Deno availability
  results.
- `36a0f22` — configures CI to keep warnings fatal while treating the current
  info-level analyzer backlog as advisory; the exact gate passed locally.
- `43db178f01d51fbddfd89d3c7855c68ad0f37823` — clarifies that the inspected
  unsigned AAB predates current HEAD and defers its rebuild under full swap.
- `d8fc87b3d1baa5309531168aaaace28e23e390ad` — prepares a loopback-only,
  two-session regression for concurrent suggestion and coach quotas.
- `0a95323d748d6cc1a93499e09fa21949b6fcd117` — removes explicit `any` from
  insights aggregation, bounds untrusted Gemini output, adds pure tests, and
  verifies targeted Deno lint plus no-remote tests.
- `5d8433cf77b03b5d352778c8dd0247bc657f30b9` — makes purchase entitlement
  selection exact and date evaluation fail closed; four no-remote regression
  cases cover lifetime, active, grace, expired and malformed values.
- `099cec7932dedad970b08fd975ab026ee0cb7d7e` — requires the configured
  RevenueCat entitlement to be an own property and guards prototype-name edge
  cases in the same focused test.
- `483742c738165636367fcb9f3cee8d9aba1d37ec` — sends Gemini API keys in the
  `x-goog-api-key` header for all four model-backed functions instead of URL
  query parameters; adds a no-network request-construction regression test.
- `621457a0015639682fe0959f42dac9a56bb36613` — runs the pure Deno Edge
  Function regression tests with `--no-remote` in CI; this workflow change has
  not yet run in CI.
- `8100a292df13ff070163fb9915b534db10cffba1` — removes explicit `any` and
  inline JSR imports from the Gemini handlers identified by targeted lint,
  using typed prompt data and the configured Supabase import alias.
- `487ed3e5537366a6c0098f7456ab01aacc6d7922` — switches the final two Edge
  Functions to the configured Supabase import alias; the full Edge Function
  lint check now passes.
- `3d725306c96eff2a521965d965e83f0b19090572` — orders isolated Deno tests
  before protected-function type-checking so a type-check failure does not
  suppress their independent CI result.
- `03aef89503c9b7dfd1a6cc81381c0c6e4122ccc3` — validates and bounds style
  coach model output by mode, prevents model fields from overriding response
  status, returns a gateway error for unusable responses, and adds pure tests.
- `2714408822692e0ee8ba921c7b08e634dffcc9d3` — loads the daily suggestion's
  canonical wardrobe through the authenticated user's RLS-protected query,
  validates generated item IDs/slots, returns database image references, and
  adds offline response-validation tests.
- `a1a7e1e8fce9be613359afa6b99549c7d5b696d7` — validates clothing-image
  request bodies and bounds allowed Gemini analysis fields; adds no-network
  regression tests and includes them in CI.
- `a37a4fad31c06aea5a107988ef1d810f1d1c664b` — validates coach mode/body
  and checks Gemini configuration before quota consumption; daily suggestions
  also reject malformed request bodies and check configuration before querying
  wardrobe or consuming quota.
- `aa756517c50d5f1dff100c053179bd19a1416f24` — adds full Edge Function lint
  as a CI gate before protected-function type-checking; the workflow has not run.
- `28a3bfd3f288010d167bd259e6408ccebaaf6a80` — rejects `anchor` as a slot on
  supporting daily-suggestion items; only the separate anchor field can use it.
- `4a205cf3a5d496da7302914f2d416d466a53054b` — removes the unreachable
  `/outfit-rating` demo route, fake outfit image/date, and widgets used only by
  that screen; daily-log and outfit-history rating flows remain available.
- `505c5730dcbd4ea6dba65938e0eeb4b9fbfcbf64` — records the rating-demo
  removal and its focused route/import checks in this status document.
- `8140241d29e1e0729cdba6ee230eabe32881be66` — records the current full
  Flutter suite and CI analyzer gate results.
- `5055140fd15a2a4df9e79966d347e83e09d9cc43` — records the current Deno
  pure tests and lint results before the protected-handler type check was fixed.
- `04a57bc26c38ef1c4938eef5b19498b6af94ca87` — fixes protected-handler type
  errors, selects the Supabase Deno config in CI, and bounds style-coach rating
  hints with focused pure tests.
- `917665d58df227a46abb76242a47e654cd7b4573` — records the successful
  protected-handler Deno checks and current-source AAB.
- `2a3dedd10c46baced6757a62a794282f604ca519` — pins JDK 21 for Flutter
  Android CI, adds unsigned release AAB compilation to the workflow, and
  limits Gradle to one worker with a 2 GiB heap.
- `645ff8b1c8d92c9220dcfcf31f9e18635bdfed4e` — fixes one account cleanup
  analyzer diagnostic; focused image, billing, operation-serialization and
  reminder tests pass, and Deno CI-equivalent checks pass from cache.
- `ca800ea5468e0a66c22c6322469423a5e0814200` — loads the splash PNG with
  `Image.asset`, ties auth-option visibility to animation completion, and
  fails closed with localized messages when Supabase is unavailable for Google,
  email, and password-recovery actions. Adds four splash and one localization
  regression case.
- `3ff72eab433b03d43de589e971479358f3196502` — clarifies that the Flutter
  validation applies to unchanged Dart sources after the Deno-only changes.
- `ff170eb8407367906acf96cb6e48a17e710188d9` — records the verified debug APK
  and its debug-only signing/runtime limitations.
- Latest work rebuilt the unsigned current-source AAB from `ca800ea`; archive
  integrity passed and signing was disabled because private upload-signing
  inputs are absent. The debug APK is a prior artifact built with the Android
  debug certificate. Full artifact details are below.

## 1. Completed local code changes

- Flutter 3.35.7/Dart 3.9.2 are pinned; dependencies resolve; `pubspec.lock` is
  tracked; Android identity remains `com.stylewise.app`; release signing no
  longer uses debug credentials.
- Removed the unused Stripe `PaymentService`, its unreferenced UI imports/helpers,
  and the uncalled local Stripe Edge Function source. The recovered production
  Stripe Edge Function remains a separate retirement/deployment item.
- Supabase client failures are surfaced as retryable/unavailable states instead
  of silently becoming empty data. Onboarding reports success only after the
  authenticated profile write succeeds. Signed-out AI suggestions render a
  retry state.
- The splash-screen password recovery action now uses the existing translated
  string in English, French, and Spanish rather than hard-coded English.
- System text scaling is preserved. Sentry event and transaction reporting
  respect the opt-out. Android/iOS now supply IANA timezone identifiers;
  reminder scheduling stays disabled if a valid device timezone is unavailable
  and no longer opens Settings unexpectedly. Next 08:00 occurrences are
  calculated by local calendar date so daylight-saving transitions do not shift
  the reminder hour.
- Removed the unused AdMob placeholder path: there was no ad SDK, production
  unit IDs were fake literals, and the home screen reserved blank banner space.
  No ads are claimed/configured for this release.
- Removed the unreferenced `/outfit-rating` demo screen, which displayed a
  fixed stock outfit and stale date. Source search found no callers of its route;
  the real inline rating flows in daily-log and outfit-history remain.
- Private image client flow stores stable owner-scoped Storage references in
  existing database columns, resolves authorized URLs at display time, refreshes
  a failed signed URL, preserves external/provider URLs and provides unavailable
  placeholders. Avatar replacement/removal, account isolation, wardrobe
  consumers and PDF embedding are covered by focused tests. Wardrobe replacement
  and deletion remove prior owned Storage objects after the row change; failed
  initial saves clean up newly uploaded objects. Cleanup is best effort because
  Postgres row changes and Storage deletion are separate operations. CSV omits
  image URLs; unavailable images do not fail an export. Private image cache keys
  use stable owner paths, are indexed without signed URLs, and are evicted on
  account cleanup and object deletion.
- The PDF image normalizer's `image` package is now a production dependency,
  matching its runtime import. Subscription purchases use RevenueCat's current
  `PurchaseParams.package` API rather than deprecated `purchasePackage`.
- `generate-ai-insights` uses explicit wardrobe/outfit row types and validates
  and bounds Gemini response fields before returning them. Malformed model
  output falls back safely without logging the response body. The affected
  functions use the project import-map alias and native `Deno.serve`.
- `style-coach` now accepts only bounded fields for passive, active, and event
  modes. It ignores model-supplied control fields, requires the active answer
  and event intro/outfit content, and returns HTTP 502 when output is malformed
  or incomplete. Existing client fields remain (`tip`, `answer`, `next_step`,
  and event outfit fields); unneeded raw model text is no longer returned.
  Invalid JSON/unsupported modes fail before quota use, and missing Gemini
  configuration no longer consumes the atomic coach quota.
- `style-coach` now accepts only finite outfit averages from 1–5 and bounded
  safe-integer rating counts when building its model-facing item list. Invalid
  hints are dropped; regression tests cover null/malformed values, score/count
  bounds, descending order, and the five-item prompt cap.
- `today-suggestion` loads its canonical wardrobe through the authenticated
  user's RLS-protected `wardrobe_items` query, using recovered table columns.
  It merges only rating hints tied to those database IDs, omits image paths from
  the Gemini prompt, and returns canonical names/categories/image references.
  Unknown IDs and invalid slots are removed; output without a real wardrobe
  anchor fails closed. Unusable model output receives HTTP 502. This remote
  database path has not been integration-tested against a disposable project.
  Invalid JSON and missing provider configuration fail before quota consumption;
  the atomic suggestion quota is consumed only after an owned wardrobe exists.
- `analyze-clothing` rejects malformed/oversized base64 payloads before
  consuming the atomic suggestion quota, checks provider configuration first,
  validates and bounds Gemini output to the expected category/color/material/
  confidence/vibe fields, and fails with a generic 502 for unusable output.
  Error responses include CORS headers and logs omit provider response bodies.
- All four Gemini-backed functions now construct requests through a shared
  helper that keeps the server API key in `x-goog-api-key`, avoiding key
  exposure in request URLs and URL-oriented logs. A pure test verifies the
  request method, body, content type, empty query, and header placement without
  contacting Google. This local source change still needs a separately reviewed
  Edge Function deployment.
- `verify-purchase` now selects only the exact configured entitlement and
  rejects malformed date fields before producing a verified snapshot. Valid
  active, grace-period and no-expiry lifetime cases are covered by pure tests.
- Challenge history now reads the `style_challenges` relation actually selected
  by the service (instead of the nonexistent `challenges` key), safely skips
  dangling relationships and deduplicates the featured challenge. Read errors
  and missing authentication propagate to a localized retry state rather than
  being presented as an empty challenge catalog.
- Learning catalog/stat failures now remain errors with a localized retry
  state. Modules use existing descriptions and `key_learnings` as the learning
  summary; users can explicitly mark that summary complete, and the app reports
  success only after the progress write succeeds. Completion is self-attested;
  the recovered `learning_modules` schema has no lesson-content or quiz field,
  so this does not claim a structured course or assessment.
- RevenueCat UI stays unavailable without the Android SDK key and exact
  entitlement. Purchase/restore are single-flight, bind to the authenticated
  Supabase UUID, reject account changes, require store entitlement and backend
  verification, and only report success after verification. Entitlement display
  and client limits also require active server status and an unexpired period;
  delayed expiry events no longer leave stale premium flags trusted. Webhook
  state uses wrapped `event` data and a server-only ordered/idempotent RPC.
  RevenueCat identity changes are serialized against the full purchase/restore
  and verification flow; app logout now signs Supabase out before RevenueCat
  logout so it cannot re-bind the account being exited.
- Local AI Edge Functions validate Supabase identity before protected work and
  consume AI quotas atomically. The suggestion preflight is read-only so it
  cannot spend a second quota. Removed `@ts-nocheck` from the protected local
  functions; backend errors return generic client messages. Outfit suggestions
  now compress device-local images and send bounded base64 bytes. The function
  validates the authenticated request and no longer fetches caller-provided
  URLs, fixing the local-path failure and removing the URL-fetch SSRF path.
  The app and Edge Function contract must be deployed together; production
  still uses the old `imageUrl` contract and was not changed.
- Account deletion checks outfit-log query errors and pages all outfit IDs in
  bounded batches before deleting their junction rows; the previous single-page
  query could miss links on large accounts.
- The in-app full reset now uses stable outfit-log pagination and bounded
  junction-delete batches as well. It evicts owner-scoped private image caches
  before remote reset steps can partially succeed. Added focused unit tests for
  multi-page cleanup, bounded batches, and listing failure propagation; these
  tests passed locally without a Supabase connection.
- `20261111090000_reconstruct_and_secure_backend.sql` was revised against
  recovered metadata: protected profile fields/counters, bilateral outfit/item
  ownership, atomic quotas, pinned/restricted helper functions, preserved
  subscription history, missing app tables/catalog content and Realtime
  membership. It is an unexecuted proposal, not an approved deployment.
- `supabase/review/private-image-cutover.sql` is review-only and preserves
  private rollback. No hosted storage configuration or record was changed.
- Added `supabase/tests/database_security.test.sql`, a local-only pgTAP fixture
  for profile separation/protected tier, bilateral outfit-item ownership and
  quota behavior. Added `supabase/tests/storage_security.test.sql`, a separate
  disposable-local pgTAP fixture for private bucket visibility and anonymous,
  user A, and user B read/upload/delete isolation after applying the review-only
  private-image cutover. Neither SQL fixture has been executed. Concurrent
  quota behavior still needs a two-session local database proof.
- Added pinned tool/setup guidance and CI for Flutter tests/analyzer and Deno
  checks. CI has not run.

## 2. Checks actually performed

| Check | Actual result |
|---|---|
| Checkout/resources | `recovery/android-v1`; no `AGENTS.md`; 14 GiB RAM, 7.3 GiB available, 511/511 MiB swap used, memory PSI avg10/avg60/avg300 at 0.00; an idle 4 GiB Gradle daemon from this checkout remains; Linux/macOS generated changes preserved |
| Toolchain | project Flutter 3.35.7 / Dart 3.9.2; Java 21; Node 22.23; Supabase CLI 3.1.0; Deno 2.9.6 exists at `.tooling/deno/node_modules/.bin/deno` but is not on PATH |
| Dependency resolution | `flutter pub get` completed; the latest offline resolution records `image` as a direct runtime dependency |
| Full Flutter tests | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` — **63 passed** on current source commit `ca800ea`, including learning/challenge recovery and new splash/auth coverage. |
| Flutter analyzer | Default `.tooling/flutter/bin/flutter analyze --no-pub` exits 1 on informational diagnostics (latest earlier run: **249 info, 0 warnings, 0 errors**). The latest CI severity gate exits 0 with **244 info**, no warnings/errors. Targeted analysis of image/export/storage/billing/account cleanup and focused tests exited 0 with **No issues found** |
| CI analyzer severity gate (2026-11-12) | `.tooling/flutter/bin/flutter analyze --no-pub --no-fatal-infos --fatal-warnings` exited 0 on source commit `ca800ea`; output reports 244 informational lints, with no warnings/errors. The remote workflow itself has not run |
| Flutter test resource event (2026-11-12) | One full-suite retry was interrupted after available RAM fell from 5.3 GiB to 4.3 GiB, swap remained full at 511/511 MiB, and memory PSI avg10 reached 0.65. It did not complete. After pressure cleared, the exact sequential full-suite command completed with **63/63 passed** on `ca800ea`; no further test attempt is pending. |
| Targeted Dart analysis | Earlier cleanup removed four infos in `notification_service.dart`. Latest `.tooling/flutter/bin/dart analyze` across image, Storage, export, subscription, serialization, notification, account cleanup and their focused tests exited 0 with **No issues found** after adding braces to account cleanup's debug guard. |
| Focused Flutter regression tests (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` over private image consumers, image reference routing, subscription, serial operation queue, and local notification schedule — **19 passed**. Tests use local fakes/helpers; they made no production, billing or AI requests. |
| Splash/auth recovery tests (2026-11-12) | The four new splash widget cases plus `app_localizations_test.dart` passed **5/5** after correcting a timer-based splash gate and scrolling test targets into view. They verify the PNG is rendered as an image and that Google sign-in, email sign-in and password recovery show the localized unavailable state when Supabase is uninitialized. No backend/provider requests were made. An initial test-fixture attempt failed because controls were off-screen and a pending delay remained; the final run passed after fixing both. |
| Current splash/auth targeted analysis | `.tooling/flutter/bin/dart analyze` on the four localization files, splash screen and two focused tests — **No issues found** after the final change. |
| Current-source project analyzer (2026-11-12) | CI-equivalent project analyzer gate completed on `ca800ea`, exiting 0 with **244 informational diagnostics, 0 warnings, 0 errors**. |
| Current cached Deno checks (2026-11-12) | The exact CI pure test set passed **29/29** with `--no-remote`; lint passed over **25 files**; `deno check --cached-only --config supabase/functions/deno.json` passed all **nine protected handlers** without downloading modules. No handler was executed and no backend/provider was contacted. |
| Deno formatting | `.tooling/deno/node_modules/.bin/deno fmt --check supabase/functions/delete-account/index.ts` passed. A combined default-format check of `delete-account`, `generate-ai-insights` and `ai-suggestions` reports the latter two files not formatted; legacy single-quote/no-semicolon options also report formatting differences. No mass formatting churn was applied |
| Deno protected-function type check | The first current full check exposed nullable/union handling issues plus that CI did not select `supabase/functions/deno.json`. Those issues and the CI command were fixed. `.tooling/deno/node_modules/.bin/deno check --config supabase/functions/deno.json` then passed on all nine protected handlers, including `delete-account`, `generate-ai-insights`, `ai-suggestions`, and `verify-purchase` |
| AI request validation | Dart payload tests passed **3/3**; Deno validation tests passed **5/5** with `--no-remote`; `deno fmt --check` passed on the pure validator and test. The handler now also passes the configured protected-function type check |
| Edge Function lint/tests (2026-11-12) | Initial targeted lint found 24 explicit `any` annotations and five inline dependency imports. After replacing those patterns, project-local Deno 2.9.6 lint passed on `delete-account`, `generate-ai-insights`, `ai-suggestions`, `verify-purchase` and pure helper tests. Combined no-remote request, insight and entitlement tests passed **13/13**. Pure helper formatting checks passed; `delete-account` formatting check passed |
| Read-only recovered schema | Production identity reverified. Read-only metadata query confirmed `revenue_cat_id text`, `suggestions_reset_at date`, nullable integer counters and nullable timestamptz expiry. Follow-up Storage metadata query confirmed `storage.objects.owner uuid`, `owner_id text`, nullable `bucket_id`/`name`, `metadata jsonb`, and `id` defaulting to `gen_random_uuid()`. The two image buckets remain public with no MIME/size restrictions; `anon` and `authenticated` have table CRUD grants on `storage.objects`, so row isolation depends on RLS and public bucket visibility currently permits public reads. Read-only policy catalog confirms two public SELECT policies (one `PUBLIC`, one `anon`) plus authenticated owner policies; no customer rows, Storage contents or secrets queried |
| Hosted operations | Read-only only. No migrations/history repair, settings, buckets/policies, records, functions or provider configuration changed |
| SQL parser | Project-local `pglast` parsed the outer PostgreSQL statements in the migration, review cutover and pgTAP fixture. This does not validate PL/pgSQL function bodies, schema compatibility or runtime behavior |
| SQL/database | No local Supabase, Docker or clean database chain was available/run; pgTAP fixture is prepared but unexecuted |
| Reset cleanup source | Targeted Dart formatting and `git diff --check` passed. `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/paginated_outfit_link_cleanup_test.dart` — **3 passed**; the test uses a pure callback helper and did not connect to Supabase |
| Challenge and localization | Pure challenge-history merge tests passed **3/3**; localization regression passed as part of the 59-test suite. Targeted Dart analysis of challenge service/screen/data and locale files reported no issues |
| Learning path | Widget tests passed **3/3** for load outage retry, failed progress persistence, and successful completion; targeted analysis of learning service/screen, badge, translations, and tests reported no issues |
| Notification scheduler | First test attempt failed because the IANA location was resolved before timezone initialization; setup was corrected. The rerun of `local_notification_schedule_test.dart` passed **4/4**, covering spring-forward, before-08:00, exact-08:00 and invalid-hour cases. `app_import_smoke_test.dart` passed **1/1** after the notification/reset changes |
| Android AAB | Two initial attempts failed at `compileReleaseJavaWithJavac` because Flutter 3.35.7's generated main registrant contains dev-only `IntegrationTestPlugin`, excluded from release dependencies. After adding the release-only no-op shim, the then-current source built successfully in 64.8 seconds with one Gradle worker and a 2 GiB heap. `build/app/outputs/bundle/release/app-release.aab` is 76,532,620 bytes; `unzip -tq` passed; `jarsigner -verify` reports `jar is unsigned`. SHA-256: `31c4b88da33b03d06d69935502816daa6f55589461231be20a4a8098fd5d14d5`. The artifact predates `e2085cb` and does not include its dependency/API changes. No provider values or signing inputs were supplied; no install/device/runtime verification was done. |
| Flutter CLI current-source AAB (2026-11-12) | Built after source commit `ca800ea` using `.tooling/flutter/bin/flutter build appbundle --release --no-pub` with Flutter pinned temporarily to `/usr/lib/jvm/java-21-openjdk`; Gradle completed in **65.6s**. The bundle is **76,421,600 bytes**, SHA-256 `ac2409f9eed9a6b9f5cf89f3fde6fb9e7a90439b327499889b56cb8e34c02243`. `unzip -tq` reported no archive errors; `jarsigner -verify` confirmed it is unsigned. Flutter's JDK override was reset to unset. No upload key or provider defines were used; the artifact was not installed or run. The previous `645ff8b` artifact hash `2f8574e6…edc459b` is superseded. |
| Android CI change (2026-11-12) | Commit `2a3dedd` adds Temurin 21 setup and Flutter JDK selection before Android build, compiles the release AAB in CI after tests, and sets Gradle to a 2 GiB heap/1 GiB metaspace/one worker. `git diff --check` and cached diff check passed; remote Actions execution is pending. |
| CI/JDK checkpoint verification scope | At the initial CI/JDK checkpoint, no tests or analyzers were rerun; the previously completed 59-test Flutter suite and Deno checks were the available evidence. Follow-up checks after account cleanup commit `645ff8b` are recorded separately above and include focused Flutter tests/analyzers plus cached Deno tests/lint/type checks. |
| Follow-up checks (2026-11-12) | PyYAML `safe_load` parsed `.github/workflows/android-ci.yml`; `git diff --check` passed. After PSI returned to zero, the full Flutter suite, focused Flutter tests, targeted/project analyzers, cached Deno checks, and refreshed unsigned AAB builds were completed as recorded above. |
| Debug APK | A local debug APK build was attempted after the AAB. It was stopped after 4m19s when swap reached 511/511 MiB; the build-owned Kotlin daemon was terminated, and no APK was produced. No unrelated processes were stopped. Retry only after resource pressure clears. |
| Current-source AAB attempt (2026-11-12) | `.tooling/flutter/bin/flutter build appbundle --release --no-pub` ran with one Gradle worker and a 2 GiB heap. Memory PSI rose from zero to 0.18 average over 10 seconds and swap reached 511/511 MiB; the build-owned Flutter process and newly started 2 GiB Gradle daemon were stopped. No new AAB was produced. Existing artifact timestamp remains 2026-11-12 02:14:45 +0200, size 76,532,620 bytes, SHA-256 `31c4b88da33b03d06d69935502816daa6f55589461231be20a4a8098fd5d14d5`; it predates `e2085cb`. No unrelated process was stopped |
| Focused image tests (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/private_image_consumers_test.dart test/services/image_reference_routing_test.dart` — **11 passed**. This uses test doubles; it did not contact production |
| Focused billing tests (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/services/subscription_service_test.dart test/services/serial_operation_queue_test.dart` — **4 passed**. This validates local identity/verification acceptance and serialization helpers; it is not a store purchase test |
| Deno tests (2026-11-12) | `.tooling/deno/node_modules/.bin/deno test --no-remote supabase/functions/ai-suggestions/request_validation_test.ts supabase/functions/generate-ai-insights/ai_response_test.ts supabase/functions/verify-purchase/entitlement_test.ts` — **13 passed**, no remote imports or provider calls |
| Edge Function lint and tests (2026-11-12) | `.tooling/deno lint supabase/functions` passed across **17 files**. `.tooling/deno test --no-remote` over request validation, insight parsing, entitlement evaluation, and Gemini request construction passed **14/14** with no provider calls. `deno fmt --check` passed for the new Gemini helper/test and `git diff --check` passed. Protected-function type-check and CI workflow execution remain deferred; no provider call was made |
| Style coach response validation (2026-11-12) | After adding the pure mode-aware response parser and tests, full Deno lint passed across **19 files** and the no-remote pure test set passed **18/18**. Targeted `deno fmt --check` passed on the new parser/test; `git diff --check` passed. No provider/network call was made. Protected-function type-check and CI execution remain deferred |
| Today suggestion ownership/output validation (2026-11-12) | Full Deno lint passed across **21 files**; the no-remote pure test set passed **22/22**. `deno check --no-remote` and `deno fmt --check` passed for the four pure style/daily response helper/test files; `git diff --check` passed. The handler's authenticated Supabase query and quota ordering were not integration-tested; no Supabase or Gemini function was invoked |
| Clothing analysis input/output validation (2026-11-12) | Full Deno lint passed across **23 files**; the no-remote pure test set passed **26/26**. `deno check --no-remote` and `deno fmt --check` passed for the pure validator/test files; `git diff --check` passed. The handler was not type-checked or invoked; no provider call was made |
| Current Edge Function CI steps (2026-11-12) | Reran the exact CI pure-test file list after the anchor-slot fix: **26 passed**. `deno lint supabase/functions` passed across **23 files**; `deno check --no-remote` and `deno fmt --check` passed on all six pure validation helpers/tests; `git diff --check` passed. No remote database/provider call was made. Protected handler type-check and CI workflow execution remain deferred |
| Outfit rating placeholder removal (2026-11-12) | `.tooling/flutter/bin/dart analyze lib/routes/app_routes.dart` reported **No issues found**. `.tooling/flutter/bin/flutter test --no-pub --concurrency=1 test/app_import_smoke_test.dart` passed **1/1**, verifying app entry and transitively imported screens compile. This does not test device behavior |
| Current Dart-source Flutter regression and CI analyzer rerun (2026-11-12) | `.tooling/flutter/bin/flutter test --no-pub --concurrency=1` passed **59/59**. `.tooling/flutter/bin/flutter analyze --no-pub --no-fatal-infos --fatal-warnings` exited **0** with **245 info** diagnostics and no warning/error diagnostics. Subsequent commits changed only Edge Function TypeScript, CI, and documentation; no Flutter/Dart source changed. No device, database, provider, or purchase behavior was tested |
| Current-HEAD Edge Function verification (2026-11-12) | Project-local Deno **2.9.6** ran the CI no-remote pure test list plus rating-hint cases: **29 passed, 0 failed**; `deno lint supabase/functions` passed across **25 files**; formatting passed for the new helper/test; `deno check --config supabase/functions/deno.json` passed all **9 protected handlers**. Deno fetched module/type files from esm.sh; no function handler was executed, and no database/provider operation was performed |
| Current-source Android release bundle (2026-11-12) | `./gradlew :app:bundleRelease --no-daemon --max-workers=1 '-Dorg.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError'` succeeded in **1m26s** (33 tasks executed, 738 up-to-date). Produced `build/app/outputs/bundle/release/app-release.aab` from source commit `04a57bc`: **76,959,486 bytes**, SHA-256 `3797fdf52ccd8509a2d8a4ecec9bd35c7970553efdc2fdfe3d3078b1616ebb99`. `unzip -t` passed; `jarsigner -verify` reported **jar is unsigned**. Gradle reported release signing disabled because `android/key.properties` is absent. No public app defines, device install, or runtime test was performed |
| Current-source debug APK (2026-11-12) | `./gradlew :app:assembleDebug --no-daemon --max-workers=1 '-Dorg.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError'` succeeded in **1m57s** (97 tasks executed, 335 up-to-date). `build/app/outputs/flutter-apk/app-debug.apk` is **197,268,699 bytes**, SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`. ZIP integrity and `apksigner verify` passed; `aapt dump badging` confirms `com.stylewise.app`, version 1.0.0, target SDK 36. It uses the Android debug certificate and is not a Play artifact. D8 emitted Kotlin metadata/Appstore SDK warnings during dex transforms; build completed. SDK `adb` is installed at `/home/theanarchitect/Android/Sdk/platform-tools/adb`, but `adb devices -l` returned no attached devices, so no install/runtime check was available |
| AI request/quota ordering (2026-11-12) | Full Deno lint passed across **23 files** and the no-remote tests passed **26/26** after request validation was moved ahead of quota use. `deno check --no-remote` passed for pure response helpers/tests; no network or database call was made. Edge Function handler type-check remains deferred |
| Recovered wardrobe schema (2026-11-12) | `.tooling/supabase/node_modules/.bin/supabase db query --remote=qxsdwwdrxoyxmnapuqqv --read-only` against `information_schema.columns` confirmed `wardrobe_items` includes `semantic_label`, `wear_count`, `image_url`, and `last_worn`, but not `color` or `times_worn`. Only metadata was queried; no account rows or Storage content were read and no hosted changes were made |
| Runtime dependency/API correction (2026-11-12) | `.tooling/flutter/bin/flutter pub get --offline` succeeded and updated the lockfile for direct runtime `image` usage; targeted Dart analysis of image/storage/export/subscription code and regression tests reported **No issues found** after migrating to `Purchases.purchase(PurchaseParams.package(package))` |
| Device | No emulator/device used. `/home/theanarchitect/Android/Sdk/platform-tools/adb devices -l` returned an empty device list; physical-device installation/runtime verification remains pending |
| Formatting/diff | Targeted Dart formatting; `deno fmt --check` on the new AI validator/test and three earlier functions; `git diff --check` and `git diff --cached --check` passed |

Latest verification: after the dependency/API correction, the focused image
consumer/routing tests passed **11/11** and the subscription/operation-queue
tests passed **4/4** on 2026-11-12. Targeted Dart analysis of these source and
test files reported **No issues found**. The
latest full serial Flutter suite passed **59/59** after the
learning recovery change. Learning widget tests passed 3/3 for outage retry,
failed save, and confirmed success. Pure challenge merge tests passed 3/3; the
three-locale password-recovery/challenge/learning localization test passed 1/1.
The targeted image routing/private consumer/app-import selection passed 12/12;
reset cleanup 3/3; reminder scheduling 4/4; AI payload encoding 3/3; Deno
request validation 5/5; and app import smoke passed 1/1. Targeted analysis of
learning service/screen/badge, challenge/localization files, splash screen/test,
and reset, notification, AI payload/client and helper files reported no issues.
Targeted formatting and `git diff --check` passed. The default project-wide
analyzer invocation exits 1 with 249 informational diagnostics and no warnings
or errors. The configured CI severity gate was also run locally and exits 0
with the same info backlog. Focused image and billing analysis is clean. The
previous AAB was rebuilt from the learning-recovery source and archive-checked,
but it predates `e2085cb` and does not represent current HEAD. A current-source
rebuild was attempted with one worker and a 2 GiB heap, then stopped when swap
filled and memory PSI rose. The existing artifact was unchanged. It remains
unsigned and has no provider configuration. Tests did not connect to a backend
or call AI
providers. A project-local `pglast` parse accepted all 30 outer SQL statements
in the Storage fixture; this does not execute policies or prove isolation.
Read-only metadata queries confirmed public buckets and broad Storage table
grants. No device check was performed; `adb` was not on `PATH` at that earlier
checkpoint. A later direct SDK-path check found `adb` installed but no attached
device.

## 3. Deferred or incomplete verification

- The full Flutter suite passed 59/59 after the final local Dart changes. The
  default project-wide analyzer invocation exits 1 with 249 informational
  diagnostics, 0 warnings and 0 errors. CI now allows info-level lints while
  keeping warnings fatal; that configured gate passed locally. The remote CI
  workflow itself has not run.
- The remote CI workflow has not run. Local pure tests, lint, and protected
  function type checks pass; this does not execute handlers or validate
  authentication, quota, database, or provider behavior at runtime.
- The local `ai-suggestions` client contract now sends `imageBase64`; recovered
  production still uses `imageUrl`. Keep those client/function versions
  coordinated in any future rollout. The local function now returns generic
  client errors while retaining detailed server logs. Nothing was deployed.
- Run the new pgTAP fixture and migration chain against a clean non-production
  schema, then run `storage_security.test.sql` after the reviewed cutover. A
  two-session harness at `supabase/tests/concurrent_quota.sh` is prepared for
  simultaneous free-tier suggestion and coach calls; it refuses non-loopback
  database hosts and remains unexecuted. Both calls should yield one success
  and one denial per quota kind.
- Source through `ca800ea` has the latest unsigned AAB at
  `build/app/outputs/bundle/release/app-release.aab`, 76,421,600 bytes, SHA-256
  `ac2409f9eed9a6b9f5cf89f3fde6fb9e7a90439b327499889b56cb8e34c02243`;
  ZIP integrity passed after explicitly pinning Flutter to Java 21. `jarsigner`
  confirms it is unsigned. The private upload
  key and `android/key.properties` are absent. Device/network behavior,
  timezone/permission behavior, accessibility, and export runtime checks remain
  pending; SDK `adb` is installed, but no device is attached.
- A debug APK is also available at `build/app/outputs/flutter-apk/app-debug.apk`
  (197,268,699 bytes; SHA-256
  `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`). Its
  Android debug certificate verifies and its manifest reports the preserved
  `com.stylewise.app` identity; it has not been installed or run.
- No purchase, restore, RevenueCat webhook, production deployment, Play tester
  transaction, database migration or private bucket cutover was executed.
- Deno 2.9.6 is available at the project-local ignored path. The current pure
  test set passes 29/29, lint passes across 25 files, and all nine protected
  function handlers pass `deno check` using the explicit functions config. No
  handler has been invoked against a database or provider.

## 4. Provider setup, risks and blockers

- Recovered production project: `qxsdwwdrxoyxmnapuqqv`, confirmed as Everywear,
  production, West EU (Ireland). Existing schema/data/Storage are preserved.
  Confirmed live risks and exact policy/function inventory are in
  `recovered-supabase-reconciliation.md`.
- The local migration is still unvalidated and unapplied. Remote migration
  history was absent. Do not run `db push`, repair history, or deploy it. First
  validate on a clean non-production schema and prepare an explicit existing
  project delta that preserves existing accounts, audit rows and objects.
- The app's premium resolver now requires `subscription_status`; if that
  reviewed schema delta is not present, the app fails closed to Essential tier
  while profile/onboarding access still works. The approved additive schema
  change must precede Edge Function and app rollout.
- Both hosted image buckets remain public with public read policies. Client
  code does not make existing images private. Inventory/convert exact legacy
  object URLs in existing `image_url`/`avatar_url` fields, review the cutover
  SQL, validate private behavior, then execute the separately approved
  production rollout. Rollback must keep buckets private and owner policies in
  place.
- `delete-account` changed after its earlier passing Deno check to paginate and
  verify outfit-link deletion. `generate-ai-insights` and `ai-suggestions` final
  Deno checks are also outstanding; Deno check stopped after the second attempt
  as required by resource limits.
- App build needs the recovered Supabase URL and public anon key. Keep service
  role, Gemini/OpenRouter, RevenueCat secret and webhook secrets server-side.
- RevenueCat Billing remains incomplete: confirm Stripe activation, supply the
  public Android SDK key, exact paid entitlement, production Web Purchase Link,
  offering/products/prices/terms, and server `REVENUECAT_EXPECTED_ENVIRONMENT`
  plus webhook configuration. Review and deploy the local compatible Edge
  Function/backend changes only after independent schema approval. Then test
  real Uptodown-distribution purchase, browser cancellation/return, account
  switch, expiry/grace/refund, management, and duplicate/out-of-order events in
  an isolated staging setup. No successful purchase is claimed.
- No private upload keystore or `android/key.properties` was found. A signed AAB
  cannot be produced without valid private upload-signing inputs.
- Physical-device verification needs a connected Android device. SDK `adb`
  exists at `/home/theanarchitect/Android/Sdk/platform-tools/adb`, but the
  current `adb devices -l` list is empty; no emulator was started.
- Store privacy/deletion URLs, listing artwork/screenshots, required Play
  declarations and eligibility are still owner-provided release inputs.
- The recovered `create-subscription-payment` Stripe Edge Function is still
  deployed, while the local app uses RevenueCat and has no call site for it.
  Its local source was removed. Retiring the remote function requires a
  separately reviewed deployment.

## 5. Resumable checklist and exact next step

- [x] Preserve checkout, prior commits, Linux/macOS generated files, and the
  ignored deployed-source snapshots.
- [x] Reconcile recovered schema metadata and deployed function source using
  read-only access; preserve exact production identity.
- [x] Revise local schema proposal and prepare privacy-preserving Storage
  cutover SQL without hosted changes.
- [x] Implement client auth/offline, timezone, reporting, image and billing
  race changes; prepare regression coverage.
- [x] Fix outfit AI suggestions to send a compressed bounded image payload and
  remove server-side fetches of caller URLs; authenticate before quota use,
  return generic client errors, and prepare pure Dart and Deno tests. Committed
  as `6ca5700`.
- [x] Use the existing localized password-recovery label in the splash screen;
  the focused three-locale regression test passed 1/1. Committed as `b9f4ddc`.
- [x] Repair challenge history relation parsing and distinguish backend errors
  from an empty catalog with a localized retry action; pure merge tests passed
  3/3. Committed as `42512f6`.
- [x] Restore useful learning summary/completion behavior using existing catalog
  fields; distinguish read failures from empty data and report progress writes
  honestly. Three focused widget tests passed. Completion remains self-attested
  because no quiz/content schema exists. Committed as `317e22e`.
- [x] Run the full Flutter suite sequentially: 59 passed after learning,
  challenge and localization changes; the affected image/app-import selection
  passed 12/12.
- [x] Prepare local pgTAP fixture for protected tier, profile/outfit ownership
  and single-session AI quota behavior.
- [x] Add a separate local-only Storage pgTAP fixture for anonymous denial,
  private bucket state, and user A/user B read/upload/delete owner isolation;
  the fixture assumes private cutover policies are installed only in the
  disposable test database and remains unexecuted.
- [x] Type-check all nine protected Edge Function handlers with the explicit
  Supabase functions import map; fix nullable data handling and ensure the CI
  command uses the same config. All nine now type-check without `@ts-nocheck`.
- [x] Rerun project-wide Flutter analysis after the earlier warning cleanup;
  latest run exited 1 with 249 infos, 0 warnings and 0 errors. Targeted
  analysis for image/export/storage/billing sources and focused tests passed.
  The configured CI analyzer severity gate then exited 0 locally, with info
  diagnostics non-fatal and warnings fatal.
- [x] Targeted Dart/Deno formatting and `git diff --check` passed. Full suite:
  59/59; learning path: 3/3; challenge merge: 3/3; reset helper: 3/3;
  notification scheduling: 4/4; AI payload: 3/3;
  Deno request validation: 5/5; app import: 1/1; image/app import selection:
  12/12.
- [x] Build and verify a current-source release AAB from `ca800ea` with one
  Gradle worker and a 2 GiB heap. ZIP integrity passed; it is unsigned because
  private upload-signing inputs are absent. Hash and exact build results are
  recorded in the checks table; it was not installed or run.
- [x] Build a debug APK from the same app source with one Gradle worker and a
  2 GiB heap. APK signature, archive, package identity and hash were verified;
  SDK `adb` is present but reports no attached devices, so no runtime check is
  claimed.
- [ ] Validate migration on non-production schema and prepare isolated security
  fixtures; production stays read-only.
- [x] Prepare concurrent two-session quota regression harness for disposable
  loopback database; syntax checked only, execution deferred until a local
  database is permitted and available.
- [x] Replace insight aggregation's explicit `any` types, bound untrusted Gemini
  response fields, and add pure parser tests. Deno lint/tests and the protected
  handler type-check now pass.
- [x] Extract RevenueCat exact-entitlement/date evaluation into a pure helper;
  malformed date data fails closed. Four focused tests pass and the handler
  passes the current protected-function type check.
- [x] Keep Gemini API keys out of URL query strings in analyze-clothing,
  today-suggestion, style-coach, and generate-ai-insights; the shared request
  helper regression test passed 1/1 without network access. Full-function lint
  and protected-handler type checks pass; deployment remains deferred.
- [x] Add the pure no-remote Edge Function test set to CI, including Gemini
  request construction. The focused Gemini test passed locally; the workflow
  itself has not run.
- [x] Clear Deno lint across all 17 Edge Function files by replacing the last
  two inline Supabase imports with the existing import-map alias; full lint and
  all 14 no-remote pure tests passed after the change.
- [x] Add full `deno lint supabase/functions` to CI. The same command passes
  locally across the current 23 function/helper/test files; CI has not run.
- [x] Order the CI no-remote Deno test step before protected-function type
  checks so both results remain independently visible when type-checking fails.
- [x] Validate style-coach's model responses against the existing passive,
  active, and event client contracts; bound output and ignore untrusted control
  fields. Four pure regression cases pass without network access.
- [x] Validate daily-suggestion item IDs against the authenticated user's
  database-backed wardrobe, canonicalize image data from those rows, omit image
  references from Gemini prompts, bound response fields, and restrict support
  item slots separately from the anchor slot. The focused four pure cases pass;
  the RLS query still needs disposable-database integration validation.
- [x] Validate analyze-clothing image inputs and Gemini output; reject malformed
  or oversized input before quota use, verify provider configuration before
  quota use, and return bounded contract fields with generic errors. Four pure
  regression cases pass; handler type-check passes. Runtime/provider validation
  remains deferred.
- [x] Validate style-coach modes and JSON before quota use; check Gemini
  configuration before consuming coach quota. Today-suggestion similarly checks
  request/provider configuration and confirms the authenticated wardrobe before
  consuming its atomic quota. Runtime quota-ordering integration remains unrun.
- [x] Remove the unreachable rating demo route and stale fake outfit preview;
  the existing daily-log and outfit-history rating flows remain. Targeted route
  analysis and app-import smoke test passed.
- [x] Re-run the complete Flutter tests sequentially and the configured
  CI-equivalent analyzer on current HEAD after removing the dead route: **59/59**
  tests passed; analyzer exited 0 with **245 infos**, no warnings or errors.
- [x] Re-run current Edge Function CI checks on current HEAD: **29/29** no-remote
  tests passed, lint checked **25 files**, new files passed formatting, and all
  nine protected handlers passed `deno check` with the explicit config path.
- [x] Update CI/setup/status. Source commits are recorded above; documentation
  and CI changes are committed separately.
- [x] Clean up replaced/deleted owner-scoped wardrobe images, avoid deleting
  external/avatar/other-account objects, and remove a newly uploaded file when
  the initial wardrobe save fails.
- [x] Remove unconfigured ad placeholder startup and banner reservation. No SDK
  or provider credentials were available, so this release does not show ads.
- [x] Serialize RevenueCat customer operations, centralize sign-out cleanup,
  paginate account deletion, and protect private image cache state.
- [x] Verify the paginated in-app reset cleanup helper: 3 focused tests passed;
  the Supabase-backed reset flow remains unverified without a disposable DB.
- [x] Prepare Uptodown hosted checkout using the authenticated Supabase UUID,
  account-bound return handling, backend-only entitlement refresh, exact
  RevenueCat management URL validation, explicit sandbox/production selection,
  and localized unavailable UI. Focused checkout/localization/service tests
  passed 14/14; targeted Dart analysis reported 7 infos and no warnings/errors.

**Exact next step:** owner confirms Stripe activation and completes the
  RevenueCat Billing project setup, then privately supplies the production Web
  Purchase Link, public Android SDK key, exact paid entitlement ID, and the
  approved catalog/price/renewal terms. Configure server expected environment
  and webhook only in an approved environment. Then prepare a configured
  Uptodown build and perform authorized staging purchase/restore/cancel/refund
  checks. A staging Supabase/RevenueCat environment is required to verify
  sandbox isolation and webhook races; production remains read-only. Private
  upload-signing inputs and a physical Android device are still required for a
  signed artifact and runtime check. Targeted tests and source checks do not
  prove live provider, database, or device behavior.

## Quota database and advertising checkpoint (2026-11-12)

- Read-only recovered-project inspection reconfirmed project reference
  `qxsdwwdrxoyxmnapuqqv`. Remote `user_profiles` has
  `subscription_expires_at` but lacks `subscription_status`; quota tables and
  quota RPCs are absent. The current remote profile policy/grants and legacy
  self-upgrade RPC remain unsafe. Exact metadata and migration-history
  limitations are recorded in [`ai-quotas.md`](ai-quotas.md). No hosted
  migration, policy, record, or function changed.
- Added `20261110090000_add_subscription_expiry_prerequisite.sql`, an additive
  no-op on recovered schema that completes fresh local migration chains. Local
  PostgreSQL 17.6 revealed an ambiguous `burst_limit` variable in
  `get_ai_allowance()`; the quota RPC query now qualifies policy columns.
  Corrected pgTAP expected-error arguments and the concurrency fixture's
  boolean parsing. The premium concurrency scenario now independently checks
  its in-flight cap.
- A project-local PostgreSQL 17.6 and pgTAP 1.3.3 toolchain was built under
  ignored `.tooling/` and bound only to localhost. In a minimal Supabase
  platform harness, the complete local migration chain applied; all 29 pgTAP
  security/quota assertions passed. Concurrent fixtures produced one success
  and one denial for two free requests, and three successes/one denial for
  four simultaneous premium reservations. The fail-closed rollback was tested
  transactionally. This does not test a full Supabase stack; logical Realtime
  delivery was not verified because local PostgreSQL's `wal_level` is not
  logical. Production quotas remain unenforced pending reviewed migration and
  staging rollout.
- Added a provider-neutral ad coordinator and focused tests. Monetag and future
  AdMob can be selected explicitly, but no adapter/SDK initializes; ads remain
  unavailable unless an adapter is configured. Verified premium access,
  account changes, explicit granted consent, safe context/lifecycle, successful
  display frequency, failures, and overlap are gated. Current focused Flutter
  tests passed 16/16; targeted analysis found only two existing informational
  brace-style lints and no warnings/errors. Targeted format reported 0 changes;
  `bash -n` and `git diff --check` passed.
- Monetag's [Android SDK article](https://monetag.com/blog/app-monetization-with-sdk-for-android-apps-apk/)
  says its Android SDK supports Flutter/APK and interstitials, but its linked
  technical docs at `docs.inappi.co` returned HTTP 502. Public
  `docs.monetag.com` instructions are for Telegram Mini Apps and are not
  applicable. No guessed SDK, package, placement ID, push format, or fake ad
  was added. Approval, an accessible official Android/Flutter guide, placements,
  consent setup, and device/staging checks remain owner/provider inputs.
  Advertising revenue remains modeled as zero in
  [`ai-cost-review.md`](ai-cost-review.md).
- Focused checks in this checkpoint: Flutter ad/tier tests 16/16; targeted
  Dart analysis: 0 warnings/errors, 2 info diagnostics; local PostgreSQL 17.6
  migration/RPC/pgTAP 29/29; free and premium concurrent reservation fixtures
  passed; rollback revocation/transaction rollback passed; shell syntax,
  targeted Dart format, and `git diff --check` passed. No project-wide analysis,
  full test suite, native build, emulator, Docker, production mutation,
  deployment, or ad traffic was run.

**Next exact step:** obtain an isolated full Supabase staging project and
reconcile the remaining recovered schema/migration-history differences before
any backend rollout. Then validate migrations, RLS, Storage, Realtime, and
Edge Function integration in that staging project. For Monetag, the owner must
obtain publisher approval for the Uptodown APK, the account-generated official
Android/Flutter SDK guide and supported artifact/version, placement IDs, and
consent requirements; only then implement and device-test an adapter. Ads stay
disabled until that validation is complete.

During local PostgreSQL setup, an untracked ad scaffold/test directory and the
new advertising-readiness document were accidentally removed along with
configure-generated files. They were reconstructed from the inspected working
source and captured session output, then the current source/tests were
reformatted and rerun (16/16 focused tests). This reconstructed version is not
asserted to be byte-identical to the earlier uncommitted files. No tracked
source or pre-existing generated Linux/macOS changes were removed.

## Recovered backend entitlement security checkpoint (2026-11-12)

- Rechecked production `qxsdwwdrxoyxmnapuqqv` using only explicit
  `supabase db query --remote=qxsdwwdrxoyxmnapuqqv --read-only` metadata queries.
  The project identity was reported as Everywear production. `user_profiles`
  still lacks `subscription_status`; it has nullable `subscription_expires_at`
  and `revenue_cat_id`. Effective catalog checks reconfirmed anon profile
  SELECT/UPDATE and authenticated updates to protected tier, expiry, limits and
  counters. The permissive own-row `ALL` policy still ORs with the ineffective
  narrow tier policy. Legacy self-upgrade, suggestion/counter and trigger
  helpers remain executable by anon/authenticated; SECURITY DEFINER helpers
  have no pinned settings. No quota policy/tables or verified-event RPC exist
  remotely. No user rows, Storage content, function source text, credentials or
  production migration history were retrieved or modified.
- Kept prior migration history intact. The coordinated deployment proposal is
  ordered: `20261111090000_reconstruct_and_secure_backend.sql`, then
  `20261111120000_lock_entitlement_mutator_grants.sql`, then
  `20261112100000_server_ai_action_quotas.sql`. The new lock migration adds the
  recovered `revenue_cat_id` shape to fresh local chains, revokes every overload
  of known self-upgrade/quota/counter/trigger helpers (including legacy
  `consume_ai_quota`), pins privileged paths, asserts unknown protected profile
  mutators cannot remain client-executable, enforces profile table/column ACL
  invariants, and grants the exact verified billing-event RPC only to
  `service_role`. The reconstruction migration protects legitimate profile
  fields while blocking direct entitlement/counter/limit writes and validates
  both sides of outfit-item ownership.
- Added quiet server entitlement verification on restored auth sessions and
  explicit sign-in, with per-account state invalidation; token refreshes do not
  trigger repeated checks. This gives existing subscribers a provider-backed
  path after the fail-closed status migration. The verifier must be deployed
  before this client release is used against the recovered project.
- Subscription-state mismatch is explicit: the missing status defaults to
  `inactive`; no expiry-only, tier-only, or Auth-metadata backfill grants paid
  access. Existing subscribers must be revalidated by the authenticated
  RevenueCat server path. Owner review is required to coordinate this temporary
  fail-closed downgrade and any provider-verified snapshot reconciliation.
- In a disposable localhost PostgreSQL 17.6 minimal platform harness, the fresh
  early migration chain plus recovered legacy schema transition, reconstruction,
  lock and quota migrations applied. The legacy premium/future-expiry profile
  remained inactive/free until a service-role verified billing event. A
  synthetic text overload of the legacy self-upgrade routine was revoked; its
  direct authenticated invocation failed with permission denied. The expanded
  `supabase/tests/database_security.test.sql` passed **48/48** pgTAP assertions,
  including own-profile editing, anonymous denial, protected tier/status/expiry,
  limits/counters, billing and quota isolation, forged metadata, exact service
  billing updates, duplicate/out-of-order events, and expired/downgraded access.
  Transaction rollback restored the disposable database's pre-migration test
  grant; reapplication revoked it. Concurrent quota tests passed one-of-two
  free burst reservations and three-of-four premium in-flight reservations.
  This is not full Supabase staging: Auth, PostgREST, Storage, Edge Runtime, and
  Supabase Storage services, Edge Runtime, and Realtime delivery are outside the
  harness; the local publication warning confirms logical Realtime delivery was
  unavailable. The review-only image policy and 11/11 SQL policy assertions
  also passed against a purpose-built Storage catalog/RLS stub; this did not
  exercise Supabase Storage APIs, signed URLs, or object byte delivery.
- Added [`staging-verification-checklist.md`](staging-verification-checklist.md)
  covering auth/isolation, private image access/deletion, AI entitlement/quotas,
  RevenueCat sandbox purchase/renewal/cancel/expiry/refund, unpaid checkout
  return, account switching, and ads remaining disabled. Local Edge Function
  code includes auth-before-provider handling in `analyze-clothing` and
  `today-suggestion`, exact server purchase entitlement verification, ordered
  idempotent webhook RPC use, and checked Storage/account deletion. Those local
  fixes have not been deployed; recovered production still runs older vulnerable
  revisions. Buckets remain public. Monetag remains disabled pending publisher
  approval and supported Android SDK documentation.
- Rollback is fail-closed: transactional rollback was tested only in the local
  disposable database. After a committed rollout, use forward corrections or
  revoke new quota RPC entry points while preserving counters/audit rows. Never
  restore client self-upgrade/quota grants, broad profile policies, or public
  image access. There is no production rollback or migration-history repair in
  this checkpoint.
- Checks actually performed: production read-only metadata queries; a clean local
  PostgreSQL 17.6 migration chain; 48/48 pgTAP security/quota assertions; legacy
  status transition, migration rollback, direct denied overload invocation,
  free/premium concurrency fixtures; and 11/11 private-image policy assertions
  against a local Storage catalog/RLS stub. The full Flutter suite passed
  89/89 once before the final auth-session refresh addition (some existing
  fallback tests emitted binding/Supabase initialization diagnostics); after
  that addition its focused subscription tests passed 4/4. Deno pure tests
  passed 32/32, lint checked 33 files, protected handler type-check passed for
  nine functions, and project analysis completed with 248 info-level findings
  and no reported warnings or errors. Targeted analysis after the auth-session
  edit reported five pre-existing info diagnostics and no warnings/errors.
  Deno formatting checked 34 files, shell syntax and `git diff --check` passed.
  No Android build, emulator, production mutation, deployment, paid API call,
  purchase, or advertising traffic occurred.

**Exact next owner action:** approve an isolated Supabase staging project and
sandbox RevenueCat configuration, and confirm the customer-safe handling for
existing subscribers whose new status defaults to inactive. Then run the
checklist there with synthetic accounts/data and deploy nothing to production
until the migration baseline and complete platform behaviors have been reviewed.

## Uptodown free-beta preparation (2026-11-12)

Historical checkpoint, superseded by the 2026-11-13 staging APK artifact
evidence above. The no-project/no-APK statements below describe the state on
2026-11-12 only.

- Local checkpoint: `ff4b58c` (`Prepare gated Uptodown free beta`).
- Test cleanup/status checkpoint: `8a6abb5` (`Isolate provider tests from
  backend services`).
- Confirmed the authenticated Supabase CLI identity is the Everywear
  organization `ioohmyibnlzfltqcsnkg`. Its project list contains production
  Everywear `qxsdwwdrxoyxmnapuqqv` (active) and unrelated Clameo
  `sjpdgcopihwocalrsrdb` (inactive). The CLI exposes no organization plan,
  billing credits, or project-capacity fields; `projects create --help` has no
  zero-cost preview. The official Management API documents read-only GET
  routes `/v1/organizations/ioohmyibnlzfltqcsnkg` and
  `/v1/organizations/ioohmyibnlzfltqcsnkg/entitlements`, requiring
  `organization_admin_read` / `organizations:read`; the local CLI has no
  command for these routes, and they do not guarantee project-specific cost.
  Official Supabase billing docs checked 2026-11-12 allow two active Free-plan
  projects across an account's Owner/Admin organizations and exclude paused
  projects. Every organization has its own plan; paid organizations charge
  compute per active project/hour, with the documented $10 monthly compute
  credit on paid plans. The current listing's `INACTIVE` Clameo status is not
  enough to prove paused state, and the organization's plan remains unknown.
  Sources: [billing guide](https://supabase.com/docs/guides/platform/billing-on-supabase),
  [organization endpoint](https://supabase.com/docs/reference/api/v1-get-an-organization),
  [compute billing](https://supabase.com/docs/guides/platform/manage-your-usage/compute).
  No staging project was created. The exact blocker is a read-only owner report
  of organization plan/entitlements and the Dashboard's project-specific cost
  and quota view proving $0, or an already-approved isolated staging project.
- Queried only aggregate production metadata using explicit
  `supabase db query --remote=qxsdwwdrxoyxmnapuqqv --read-only`. The three
  profile rows aggregate to two `free` and one legacy `premium` tier; all three
  have `subscription_expires_at IS NULL`. The subscription transaction table
  has no rows in any event/store category. This is not verified payment
  evidence: the profile flag alone cannot establish a paid account, and the
  recovered schema has no transaction event evidence. No individual account,
  private data, credentials, or Storage objects were queried. Do not promise
  restoration of premium until provider-side purchase history is checked.
- Added an explicit `EVERYWEAR_FREE_BETA` build gate. It disables RevenueCat
  initialization/checkout and forces ad selection to disabled even if other
  compile-time billing or ad values are accidentally supplied. The premium
  screen explains that purchases are disabled, with English, Spanish, and
  French strings. AI-unavailable copy no longer promises a retry. Added focused
  configuration and localization regression coverage. Manual wardrobe and
  deterministic outfit features remain usable; AI still needs an isolated
  backend with the reviewed quota migration/provider state.
- Updated the app version to `1.0.0-beta.1+2` (version code 2), preserving
  application ID `com.stylewise.app`. Added a beta build helper that refuses
  the production project ref and accepts only a private mode-0600 staging JSON
  file outside the checkout with the exact staging URL and anon-key fields.
  It produces only a clearly named debug APK in the ignored build directory;
  it cannot create/link/deploy backend projects. Added draft Uptodown listing,
  release notes, and device smoke instructions in
  [`uptodown-free-beta.md`](uptodown-free-beta.md).
- Attempted a separate unconfigured Android compile with all free-beta gates
  on and Supabase/provider defines empty. The first invocation failed before
  compilation because Flutter selected Android Studio JBR 25.0.3 despite
  `JAVA_HOME` pointing to Java 21. A second invocation temporarily selected
  JDK 21 and an isolated build directory, reached `assembleDebug`, then was
  interrupted when available memory dropped to about 4.4 GiB and swap was full.
  Temporary Flutter settings were restored; only the Gradle daemon started by
  that build was stopped. No new APK was produced. The older APK was copied to
  ignored `build/beta-artifacts/` and its SHA-256 verified unchanged. Further
  Android builds are deferred under the resource limit; this gives no runtime
  evidence.
- Not built: no zero-cost staging project or staging config exists, the
  recovered production backend is unsafe and read-only, and no physical
  Android device is attached for ADB verification. The existing APK was
  inspected with `aapt`: it is the old `com.stylewise.app` version `1.0.0`
  (code 1), SHA-256 `ea14e9f5511988977d80b9bdd405ab5a49e68623ce8763c68fe5608f6b3d252c`,
  and does not contain this beta source/configuration. No current beta APK or
  runtime result is claimed. `android/key.properties` and the existing upload
  signing key are absent, so no signed release artifact can be produced. Privacy,
  deletion, support, data-retention URLs, artwork, and owner-approved handling
  of the legacy premium profile are still needed before public distribution.
- Checks for this checkpoint: read-only organization/project CLI listing and
  aggregate production SQL; source inspection confirmed Android application ID
  `com.stylewise.app`, version code `2`, and no upload signing config. Targeted
  Dart formatting normalized the changed RevenueCat service; a second
  formatting check reported zero changed files. Focused Flutter tests passed
  **26/26** across RevenueCat config/hosted checkout, ad config/coordinator,
  and localization. A sequential full-suite run then passed **94/94** before a
  test-only isolation cleanup. The provider suite passed **6/6** after that
  cleanup with no binding/Supabase initialization diagnostics; the full suite
  was not repeated after the test-only change. Targeted analysis of the 12
  changed Dart files reported five info diagnostics and no warnings or errors;
  analysis of the changed provider test reported no issues. A subsequent
  project-wide analysis reported 248 info diagnostics with no warnings or
  errors. The build helper
  passes `bash -n`; missing-config and production-ref guards both refused
  safely. Targeted formatting reported zero changes after cleanup, and
  `git diff --check` passed. No Android build completed, no device test or
  Docker was run, and no production write, deployment, or publication occurred.

### Resumable free-beta checklist

- [x] Force checkout and ads off in the free-beta build; update honest UI copy.
- [x] Prepare a staging-only APK helper with private config checks and a
  production-ref guard; preserve app identity and release signing setup.
- [x] Draft Uptodown listing, notes, and physical-device checks.
- [x] Obtain owner-approved staging project identity/cost authorization; CLI
  confirmed name, ref, and region. Project's Free status is owner-confirmed.
- [x] Apply the reviewed migration chain and deploy the relevant Edge Functions
  only to the isolated staging project; run synthetic Auth, PostgREST, Storage,
  quota, account-deletion, and Realtime checks.
- [x] Build, archive-check, identify, and hash the staging APK.
- [x] Install the corrected normal staging APK over the existing app with
  `adb install -r`; no data was cleared or removed.
- [x] Unlock the connected A065; the corrected APK visibly shows the branded
  sign-in screen and staging banner.
- [x] Sign in with the staging email account, complete onboarding, and reach
  Today/home on the connected A065.
- [ ] Complete remaining physical-device smoke checks; no production or paid
  provider checks are implied.
- [x] Add a widget regression test that proves the branded startup screen paints
  while startup services are still pending.
- [ ] Resolve legacy premium account evidence/transition and provide privacy,
  deletion, support, and data-retention URLs plus approved artwork.
- [ ] Locate/validate the existing upload-signing key before any signed
  distributable; do not generate a replacement.

### Connected-device smoke test (2026-11-14)

- The owner completed email authentication on the staging APK and reported
  reaching the authenticated welcome screen. This verifies email sign-in; it
  does not verify a fresh confirmation-email link callback. Google sign-in
  remains unverified because the staging provider is disabled.
- On the connected A065 running `com.stylewise.app` version `1.0.0-beta.1`
  (code 2), onboarding was completed with synthetic preferences. The profile
  save succeeded and the app navigated to the Today home screen. This verifies
  onboarding persistence and authenticated home navigation against staging.
- Today and Wardrobe screens rendered. Wardrobe showed the empty state and
  add-item entry point. The personalization upload step displayed a 22 px
  bottom overflow on this device.
- A synthetic vector shirt image was prepared and copied to the device's
  `Pictures/EverywearSmokeTest` folder. The owner selected it for the synthetic
  `Synthetic Olive Tee` item in category `Tops`; the item saved and the shirt
  image visibly loaded in the Wardrobe grid. Two identical synthetic items are
  now present after repeated form attempts; both were left intact. This is a
  staging display check, not a private-bucket isolation or cross-account test.
- A wardrobe-built outfit was saved to staging. After refresh, Today showed
  one outfit and one linked item, and the outfit history card displayed the
  synthetic shirt. AI returned the honest unavailable state; the manual path
  remained usable. Ads and purchases stayed disabled.
- The confirmation preview did not render the selected garment image even
  though the Wardrobe grid and saved history card did. Source inspection
  confirms `WardrobeService` supplies `image_ref`/`image_url`, while the
  confirmation widget read only `item['image']`. The local fix and regression
  test are recorded below; staging-device verification is pending.
- Today initially stayed at zero after Quick Log returned. Source inspection
  confirms the photo/wardrobe quick-log option pushes the capture route without
  reloading `_loadData()` on return; the separate full-log route does reload.
  Manually refreshing Today loaded the saved outfit. The quick route now uses
  the same return-refresh path, with a focused regression test below.
- The owner confirmed Logout. The app returned to its email/Google sign-in
  screen, verifying local session sign-out; the staging account and synthetic
  records were not deleted. Google remains unavailable because its staging
  Auth provider is disabled.
- The focused app-process log captures contained no fatal exception or
  error-class entry during outfit save and sign-out. They do not establish
  backend health beyond the UI results above.
- During the gallery-picker attempt, a system notification intercepted a
  touch and opened another app. No message was sent. The test returned to the
  Everywear add-item form without selecting personal media.
- Staging only; ads and purchases remain disabled. No production changes were
  made. Generated Linux/macOS working-tree changes remain unstaged.

### Smoke-test fixes and staging rebuild (2026-11-14)

- Outfit confirmation now resolves the wardrobe image from `image_ref`, then
  `image_url`, with legacy `image` compatibility. The shared
  `CustomImageWidget` resolver remains responsible for stable private Storage
  references. A test injects a resolver and verifies the selected reference is
  routed without contacting hosted Storage.
- The Quick Log photo/wardrobe action now shares the full-log route helper,
  which reloads Today after the capture route returns. A focused test verifies
  refresh occurs after a dismissed route returns.
- The optional personalization photo tile now uses a minimum height and
  vertical padding so its content can grow with text scaling. A widget test at
  a phone-sized viewport and 1.5 text scale reports no layout exception.
- Focused Flutter tests: **4 passed** across outfit image routing, Quick Log
  route-return refresh, and the optional photo-tile layout. Targeted Dart
  analysis of the changed files completed with **no warnings or errors**; 13
  existing informational lints remain. Targeted formatting and
  `git diff --check` passed.
- Built once with `scripts/build_uptodown_free_beta.sh`, approved staging ref
  `aftdbphdobfrshienple`, the private mode-0600 staging config, Java 21, one
  Gradle worker and the configured 2 GiB heap. Ads and purchases are disabled;
  the build includes the STAGING banner. Temporary Flutter JDK selection was
  cleared after the build.
- APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-2-aftdbphdobfrshienple-debug.apk`;
  **235,141,130 bytes**, SHA-256
  `f636a3a5ba5e80dca9532f0f2cc18ba9bccfa8c557cd37a9978721758f57e265`.
  `unzip -t` passed; `aapt` confirmed `com.stylewise.app` version
  `1.0.0-beta.1` code `2`. `apksigner` verified the Android debug certificate
  SHA-256 `76fec71b0c4b3d72fd43231330967da1c9fd8d04a985c7aade7430ecb45d2d97`,
  matching the prior installed staging APK. Installed with `adb install -r`;
  staging records were preserved.
- Post-install device check is pending: the phone entered Doze before a
  visible frame could be observed. No on-device claim is made yet for the
  confirmation preview, route-return refresh, or photo-tile layout. The owner
  must unlock and sign in, then manually navigate to verify those screens.
- Follow-up ADB inspection found the app activity still foreground, but Android
  was in Doze and the captured framebuffer was black. The owner reported the
  sign-in screen was available; the UI could not be independently inspected
  until the device is awake. No failure or success for the three fixes is
  inferred from this black capture.

### Free-beta validation follow-up (2026-11-14)

- Current source reviewed from `main` at `a63a3c4717f7764d875ca9b36fdb5d048644f17b`.
  The connected A065 is present, but remained in Doze with Everywear's activity
  foreground. No automated navigation, app-data clearing, or new launch was
  performed. Outfit preview, Quick Log return refresh, and the onboarding
  photo-tile overflow remain **not verified on-device**; the owner must wake
  the phone and navigate manually.
- A new timestamped, uncleared 4,000-line logcat snapshot was retained at
  `.tooling/recovery/device-startup-20261114/validation-logcat-20261114-202439+0200.txt`.
  It contains no `TimeoutException` or `NotFoundException` for the current
  Everywear process. The earlier `TimeoutException after 0:00:02` is emitted by
  the catch around `AnalyticsService.isAnalyticsEnabled()` in `main.dart`; the
  2-second deadline wraps `SharedPreferences.getInstance()` and is earlier
  than the separate 5-second Sentry-init deadline. Supabase initialization
  followed shortly afterward in the same older log. Its impact was a skipped
  Sentry initialization and a two-second delay before Supabase/Hive bootstrap,
  not a fatal startup failure. Reporting now runs outside required core
  startup, its preference failure is identified separately, and Sentry is
  skipped when the preference is unavailable or opted out. Focused startup
  tests cover slow and failing reporting without blocking Supabase/storage.
- The earlier `Resources$NotFoundException: String resource ID #0x0` stack is
  entirely in `com.nothing.experience` (`NothingExperience.getAppName` called
  by the Nothing Experience app-tracking worker); no Everywear frame appears in
  the stack. It is an OEM/device tracking warning. No user-visible Everywear
  failure was observed from it, and no app change is warranted. It did not
  recur for the current process in the fresh snapshot.
- Tracked-artifact inventory found Android's generated Gradle problems report,
  Flutter Linux/macOS `ephemeral` outputs, and unreferenced `assets/env.json`.
  Those paths are now ignored and removed from the Git index only; local files
  and symlinks were verified to remain present. `assets/env.json` was not
  bundled or read by source. Metadata-only inspection found its AI provider
  secret fields empty; the remaining Supabase anon and Stripe publishable
  values are public client configuration but stale/production-specific. Values
  were not printed. Stripe-only ProGuard rules were removed after confirming
  Gradle does not reference that file and release shrinking remains disabled.
  Required generated platform sources were retained, including Linux's
  `generated_plugin_registrant.cc`, `generated_plugin_registrant.h`, and
  `generated_plugins.cmake`, iOS asset-catalog `Contents.json` metadata, and
  the tracked Hive `local_wardrobe_item.g.dart` adapter. No platform source
  directories were removed.
- The staging helper now supports explicit `EVERYWEAR_BUILD_MODE=release`,
  always targets `lib/main.dart`, rejects diagnostics/engine-test/probe flags,
  refuses to use `android/key.properties`, labels the output
  `release-unsigned.apk`, refuses to overwrite an existing artifact, and checks
  that Gradle produced an APK. All three diagnostic-mode rejection checks and
  `bash -n` passed. Shrinking settings were not changed.
- One release-mode staging build was attempted with the approved staging
  project/config, Java 21, one Gradle worker and the 2 GiB heap. Available RAM
  fell from 2.4 GiB to 1.0 GiB while swap was full. The build was stopped for
  resource safety; Gradle produced no release APK, and no release artifact is
  claimed. The Flutter JDK override was restored. A retry is deferred until
  the machine has materially more headroom.
- Focused Flutter tests passed **3/3** for reporting-independent core startup
  and first-frame loading. Targeted analysis found no warnings/errors; four
  existing informational diagnostics remain in `main.dart`. Formatting,
  `bash -n`, release diagnostic guards, and `git diff --check` passed. The four
  previously recorded outfit/Quick Log/onboarding widget tests passed before
  this follow-up; they were not re-run here.
- At this checkpoint, fresh same-phone email-confirmation testing had not yet
  occurred. The callback allowlist was owner-confirmed; the default Supabase
  confirmation template remained in use because editing is gated on custom
  SMTP. Later same-phone results are recorded below. A second-device result
  remains untested; no confirmation link or credentials should be shared in
  chat.

### Connected phone awake follow-up (2026-11-14)

- The owner manually navigated on the connected A065. ADB inspection at
  `2026-11-14 20:46 +02:00` found the device awake with Everywear foreground on
  Today and the STAGING ribbon visible. The screen showed one saved outfit and
  its synthetic shirt image in the history card. The timestamped screenshot is
  retained locally at
  `.tooling/recovery/device-startup-20261114/manual-navigation-20261114-204617+0200.png`.
- An uncleared 5,000-line logcat snapshot is retained at
  `.tooling/recovery/device-startup-20261114/manual-navigation-20261114-204617+0200.log`;
  no exception/error entry was found for the Everywear process in that
  snapshot. This confirms the home/history rendering at capture time.
- The owner then selected **Build from Wardrobe** in Quick Log and reported
  that Today updated after returning. The timestamped screenshot at
  `.tooling/recovery/device-startup-20261114/quick-log-return-20261114-210213+0200.png`
  shows two outfit entries (the prior capture showed one) with the synthetic
  tee image on both; the owner had been instructed not to tap refresh. This
  verifies the automatic Today refresh path on-device. The accompanying
  uncleared log snapshot contains no matching exception/error entries for the
  app process. The owner also confirmed the tee image was visible on the
  confirmation screen before saving. Together, the owner report and before/
  after screen evidence verify the image preview and automatic Today refresh on
  this device.
- The optional photo onboarding overflow remains unverified on-device.
- At the 20:46 capture, fresh email confirmation was still pending; see the
  later same-phone result below.

### Same-phone email confirmation (2026-11-14)

- The owner reported creating a fresh staging account and verifying its email.
  At `2026-11-14 21:08 +02:00`, ADB showed Everywear foreground on the
  authenticated Profile page on the same A065. This verifies the confirmation
  round trip returned to the installed app and an authenticated session was
  available. No account identifier or confirmation link is recorded here.
- The associated uncleared logcat snapshot is retained locally at
  `.tooling/recovery/device-startup-20261114/email-confirm-return-20261114-210842+0200.log`;
  it contains no matching exception/error entry for the app process.
- The owner has not yet confirmed whether onboarding, including the optional
  wardrobe-photo step, appeared before the Profile page. The owner later
  confirmed the onboarding path was fine and no overflow appeared, and that
  they navigated to Profile manually. No second device is available, so the
  other-device callback behavior cannot be tested in this pass.
- The staging redirect allowlist was owner-confirmed and the default Supabase
  confirmation template remains in use because editing is gated on custom
  SMTP. This successful message confirms delivery for this staging test inbox
  only, not general email readiness. No other-device callback test has been
  performed; behavior on another device remains unverified.

### Signup name propagation fix (2026-11-14)

- The owner reported that email signup asks for a name but the authenticated
  Profile page displayed the email. Source tracing confirmed the signup form
  captured the name, while `signUpWithEmailRedirect` sent only email and
  password. `ProfileScreen` reads `user_metadata.full_name` and falls back to
  email, so the signup metadata was missing.
- Signup now sends the trimmed entered name as `data.full_name` with the
  existing explicit mobile confirmation redirect. The existing profile
  display reads that auth metadata. A regression assertion inspects the
  outgoing signup JSON and verifies `data.full_name` is present; the existing
  redirect and Android intent tests remain covered.
- Focused auth tests passed **3/3**. Targeted analysis found no issues, and
  formatting and `git diff --check` passed. This source change has not yet been
  built or verified on the phone. The account created before the fix cannot
  recover its previously entered name from signup; the owner can set it via
  Profile → Edit Profile. No account data was changed remotely.

## Guarded authenticated phone smoke test (2026-11-14)

- Added `scripts/run_staging_ui_smoke.sh` and replaced the placeholder
  integration test with a staging-only authenticated flow. It refuses to run
  unless the explicit staging project, Uptodown/free-beta defines, ads disabled,
  purchases unavailable, private config file, and a selected authorized device
  are all present. It never reads a service-role key.
- Every UI tap and text-entry action checks Flutter's resumed lifecycle and a
  debug-only Android activity/window-focus channel before acting, and checks
  again afterward. Tests use keyed controls and condition-based waits; there
  are no coordinate taps or `pumpAndSettle` waits. If another activity takes
  focus, the test throws immediately and makes no subsequent app action.
- The integration test creates a uniquely named `SYNTHETIC UI SMOKE` wardrobe
  row and outfit with a generated local image, exercises the actual staging
  Storage upload and display, verifies outfit creation and the automatic Today
  refresh, checks the profile display-name source, then signs out last. It does
  not delete the account, synthetic records, Storage objects or existing data.
  No records have been created by this test yet.
- The integration test enables a debug-only in-memory switch to suppress
  clothing-photo AI analysis, camera permission requests and location/weather
  access during this flow; teardown always turns it off. A normal launch leaves
  it disabled, and release builds cannot enable it. Purchases and ads remain
  disabled.
- Profile display now chooses non-empty auth `full_name`, then the existing
  profile row's `full_name`, then email. The provider already reads the same
  profile row for account state; it now includes the name column. Added a pure
  name-selection regression test. An existing account created with a build
  that omitted signup metadata cannot prove the new-signup flow; that requires
  a new confirmed signup with the corrected APK. The integration test prints
  that check as skipped when the current authenticated session has no
  `full_name`, without editing it.
- `pubspec.yaml` advances Android version code from 2 to 3 so the approved
  staging APK helper can produce a distinct in-place update artifact.
- Checks performed: targeted Dart formatting; `bash -n` on the smoke runner;
  `git diff --check`; offline dependency resolution; focused profile-name,
  smoke-mode, Quick Log navigation and outfit-preview tests passed **7/7**;
  targeted Dart
  analysis of the modified Dart sources reported no errors or warnings (only
  existing informational lints).
- The approved local config was found at
  `/tmp/everywear-staging-aftdbphdobfrshienple-private/app-config.json`, mode
  `0600`. Its URL was validated against
  `https://aftdbphdobfrshienple.supabase.co`; no key value was displayed.
- Two integration-build attempts failed before the test code or any UI action
  ran. Attempt 1: Flutter selected Android Studio JDK `25.0.3` and the Flutter
  Gradle plugin loader failed. The runner now temporarily sets Flutter's JDK to
  Java 21 and restores its previous unset value on exit. Attempt 2 reached
  `compileDebugKotlin` and failed because `MainActivity.kt` referenced
  `BuildConfig`, which this Android module does not generate. Replaced that
  check with the app's Android `FLAG_DEBUGGABLE`; this source correction has
  not been compiled or device-verified. Per recovery limits, no third Gradle
  attempt was made.
- ADB confirmed the authorized A065 was awake and Everywear foreground before
  the second attempt. The build failed before APK installation, test execution,
  authentication, taps or staging writes. It returned to the launcher. The
  script restored `stay_on_while_plugged_in` to its original value `0`, and
  Flutter's JDK setting remains unset. No account data or app settings were
  changed. Zero synthetic rows/objects were created by the attempted run.
- Updated staging APK build/install and phone-flow verification remain deferred
  after the two Gradle failures. The approved config is available; no further
  credential action is needed. The guarded command for a later allowed run is
  `EVERYWEAR_STAGE_PROJECT_REF=aftdbphdobfrshienple EVERYWEAR_STAGE_CONFIG_FILE=/tmp/everywear-staging-aftdbphdobfrshienple-private/app-config.json EVERYWEAR_UI_SMOKE_DEVICE_SERIAL=21471b75 ./scripts/run_staging_ui_smoke.sh`.
- Fresh-signup name metadata check remains a separate owner-assisted case:
  sign up with a new disposable staging identity on the corrected APK, enter
  the name, confirm the email on the same phone, then verify Profile shows that
  name. Do not reuse or delete the existing account to test signup.

### Additional authorized smoke/build attempt (2026-11-15)

- Reviewed `android/app/src/main/kotlin/com/everywear/app/MainActivity.kt` at
  HEAD `2f3ce56e449355b966065c87fd54a60a7851227e`. The debug-only UI smoke
  channel uses `ApplicationInfo.FLAG_DEBUGGABLE`; `BuildConfig` is absent from
  the tracked Android source. This is the correct Android runtime flag check.
- The approved staging runner was invoked once with project
  `aftdbphdobfrshienple`, the mode-0600 private config, device serial
  `21471b75`, one Gradle worker, and the repository's 2 GiB Gradle heap. Before
  invocation, Flutter reported Java 21.0.13 at
  `/usr/lib/jvm/java-21-openjdk/bin/java`, and `./gradlew --version` reported
  Gradle 8.11.1 using the same Java 21 installation.
- A retained Kotlin daemon log contains an unresolved `BuildConfig` diagnostic
  at `2026-11-14 23:24:45 +0200`. Its compiler arguments identify
  `/home/theanarchitect/Projects/Everywear/android/app/src/main/kotlin/com/everywear/app/MainActivity.kt`;
  that is the intended checkout, not a generated or duplicate activity. The
  error is confirmed for that earlier compilation: the source at its parent
  revision had `if (BuildConfig.DEBUG)` at line 37. The corrected source was
  modified at `23:25:19` and committed at `23:26:14`, after that diagnostic.
- No fresh compiler log or build-output timestamp was retained for the later
  invocation described in the previous status entry. The `BuildConfig` message
  therefore cannot establish whether that later invocation reached Gradle or
  failed again; the earlier entry incorrectly attributed the stale diagnostic
  to it. No new build success or failure is verified from retained evidence.
- **Installation and device smoke test:** not verified by this attempt. The
  existing app data and staging records were preserved. No evidence shows this
  attempt reached installation, UI actions or staging writes.
- Cleanup was checked: Flutter's global `jdk-dir` is unset as before, and A065
  `stay_on_while_plugged_in` is restored to `0`. No source or app configuration
  was changed during the attempt. `git diff --check` passed after recording the
  result.
- Source reconciliation found no path or source-set defect. `android/app`
  uses the default Android `src/main/kotlin` source root, with no custom source
  sets or symlinks, and the current checkout has no duplicate activity. A
  separate detached worktree at `/tmp/Everywear-staging-aftdbphdobfrshienple`
  is at `fa162455`; it has no smoke runner and its older activity has no
  `BuildConfig` reference, so it is not the source of this diagnostic. Before
  another authorized build, capture that invocation's output to a uniquely
  timestamped local log and verify it records the current checkout and a new
  Gradle execution timestamp. Do not use or interpret the old daemon message as
  evidence about a later build.

### Guarded A065 staging smoke (2026-11-15)

- Preflight from `/home/theanarchitect/Projects/Everywear` confirmed branch
  `main`, private config mode `0600` targeting only
  `aftdbphdobfrshienple`, authorized A065 serial `21471b75`, Flutter Java
  `/usr/lib/jvm/java-21-openjdk/bin/java` (21.0.13), Gradle 8.11.1 on the same
  Java 21 runtime, one Gradle worker, `-Xmx2G`, and 3.81 GiB available RAM.
  Purchases were passed as unavailable and ads disabled by the runner.
- Invocation at HEAD `c6ceddee2e009829dbc9896900f2a8340fca064c` built and installed
  the Flutter integration-test APK, initialized staging Supabase, and entered
  the authenticated smoke test. It failed before any UI action because the
  test looked for `STAGING` as a `Text`; Flutter's `Banner` paints its label.
  The same fresh output exposed a Today query for nonexistent staging column
  `user_profiles.display_name` and the expected unconfigured billing verifier
  HTTP 503. No app writes occurred. Private log:
  `/tmp/everywear-staging-smoke-20261115-002134.log` (mode `0600`, exit 1).
- Fixed the banner check to assert the actual enabled `Banner` widget and
  changed Today to select `user_profiles.full_name`, matching the app's
  profile query. Added enabled/disabled banner widget coverage; the focused
  test passed **1/1**. These source changes are in `45eacee`.
- Invocation at HEAD `45eacee4c7eb61c2fd5adbd76e31876224131910` built/installed
  the integration-test APK but timed out waiting for the initial wardrobe
  navigation control. A device screenshot showed A065 at the charging lock
  screen. No tap or staging write occurred. The owner unlocked the phone.
  Private log: `/tmp/everywear-staging-smoke-20261115-002555.log` (mode
  `0600`, exit 1).
- After unlock, a third fresh invocation at the same HEAD again built and
  installed the integration-test APK, but the initial navigation control did
  not appear before timeout. During the wait, ADB reported
  `com.nothing.launcher/com.android.searchlauncher.SearchLauncher` as the
  resumed activity. The guarded test never reached its foreground assertion
  or first tap, so this is not a passed device smoke test and no private sign-in
  prompt was reached. No staging records were written. Private log:
  `/tmp/everywear-staging-smoke-20261115-003211.log` (mode `0600`, exit 1).
- **Build:** integration-test APK build passed on each invocation. **Install:**
  Flutter installed the integration target; no new normal staging beta APK was
  produced because the guarded test failed before the helper's beta-build
  step. **Device flow:** not passed; no wardrobe, outfit, Today, profile, or
  logout action ran. No staging records were written.
- Cleanup verified after the final run: Flutter `jdk-dir` is unset and A065's
  `stay_on_while_plugged_in` is restored to `0`. The current resumed activity
  is still the launcher. Next owner action: manually open Everywear and leave
  it visibly foregrounded (sign in privately only if the app presents the
  sign-in screen). Then resume with a fresh guarded run; do not tap through
  other apps. Investigate why the integration runner leaves the launcher
  resumed before attempting another UI run.

### Integration runner cleanup and launch follow-up (2026-11-15)

- Checked the runner process before considering a resume: no
  `flutter_tools.snapshot test integration_test/app_test.dart`, Dart test
  process, or `run_staging_ui_smoke.sh` process remained. A manually opened app
  cannot resume that completed test.
- ADB currently reports `com.nothing.launcher` as both resumed activity and
  focused window; `pidof com.stylewise.app` and `pm path com.stylewise.app`
  return no app process/package. This conflicts with the owner's report that
  Everywear is foregrounded. No launch or test action was taken to resolve the
  discrepancy.
- Flutter's pinned integration-test runner source explains the post-test
  launcher state: `IntegrationTestTestDevice.kill()` calls `stopApp()` and
  then `uninstallApp()` for its integration application
  (`.tooling/flutter/packages/flutter_tools/lib/src/test/integration_test_device.dart:138-147`).
  The app's `applicationId` is `com.stylewise.app`. The test target therefore
  uninstalls the app on test cleanup; Android uninstall removes app-local
  data, including the local session/cache. The earlier claim that app data was
  preserved by these failed integration runs was incorrect. No remote staging
  rows were written by these runs; production was untouched. Do not run this
  integration target against a package whose local data must be preserved.
- The timeout location is established: `integration_test/app_test.dart` calls
  `app.main()`, then waits up to 30 seconds for the wardrobe tooltip before it
  calls `_assertForeground()`. When no matching widget is mounted, the wait
  times out and the first foreground check is never reached. The test checks
  process/window foreground only after this widget wait, so it does not
  distinguish an unmounted app tree from an activity that is not foregrounded.
- The exact native launch/instrumentation reason is **not established**. The
  runner logs show the Dart test timeout, but no logcat snapshot was saved for
  the 00:32-00:34 local invocation. A later read-only `adb logcat -d` capture
  (raw private file `/tmp/everywear-a065-smoke-20261115.raw.log`, mode `0600`)
  had no entries in that window; the retained activity records began around
  21:41 local, after the test. Thus there is no surviving native launch, crash,
  or instrumentation event evidence to separate failure to launch from an
  activity leaving foreground. Do not attribute this to sign-in or a plugin.
- No integration test is running now. The current device observation is not
  consistent with a foreground Everywear install, so another test/install was
  not started. Before any next UI run, change the harness so its test
  application uses a separate package identity and checks native foreground
  immediately after startup, before waiting for app widgets. This avoids
  uninstalling the owner's app and makes startup-vs-foreground failure
  actionable. Then collect a private timestamped logcat window before launch.

### Staging app restoration and isolated test harness (2026-11-15)

- Device identity was rechecked: serial `21471b75`, Nothing A065 / device
  `Pong`, Android user `0` only. Before restoration,
  `com.stylewise.app` was absent. The prior Flutter integration-test teardown
  uninstalled it, so its local session/cache may have been lost. The old claim
  that those runs preserved app data is withdrawn. No smoke-test UI action or
  staging row write was reached, and production was untouched.
- The normal staging APK was built using the approved helper/config and Java
  21. Flutter and Gradle use Java 21; Gradle remains one worker with a 2 GiB
  heap. Purchases are unavailable and ads are disabled. The artifact is
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-3-aftdbphdobfrshienple-debug.apk`,
  SHA-256 `5f457c1b105c0ca902d583f5711eb2fed398ccfd5e144f5b5ab5c4e4c6fe826b`,
  size 205,559,105 bytes. APK metadata confirms package
  `com.stylewise.app`, version code 3. Its debug certificate matches the
  previous staging APK.
- Installed on A065 user 0 and launched. ADB confirms package path, version
  code 3, and `com.stylewise.app/.MainActivity` resumed. This is a fresh app
  installation after the earlier uninstall; the owner must sign in again.
  Server-side records were not changed by the failed UI test. The install
  timestamp `2026-11-15 22:07:32` is the baseline for the isolated test's
  post-run package-preservation check.
- The harness now builds its integration target as the distinct package
  `com.stylewise.app.stagingtest`, labeled `Everywear UI Smoke Test (STAGING)`.
  Gradle's non-compiling identity task verified the true property resolves to
  `.stagingtest` and false resolves to the normal `com.stylewise.app`; the
  smoke runner refuses to start if the normal package is absent, records its
  version/install time, and checks those values after the test even on failure.
  The normal APK helper explicitly forces the normal package ID.
- The first native foreground check now happens immediately after the Dart
  entrypoint, before app-widget waits. The harness prints
  `SIGN_IN_REQUIRED` and waits up to fifteen minutes for private sign-in to the
  test-only app before any synthetic writes. The test app has separate secure
  storage and will not inherit the normal app's login; the owner will need to
  authenticate in that test app too.
- The runner now captures continuous timestamped `adb logcat -v epoch` output
  to a mode-0600 file under `/tmp`, without clearing device logs. Flutter's
  teardown did **not** honor the distinct APK ID. The test ran under Flutter
  and reached its five-minute `SIGN_IN_REQUIRED` wait, then failed before any
  UI action or staging write. Its APK was
  `com.stylewise.app.stagingtest`, but Flutter's device log proves teardown
  ran `am force-stop com.stylewise.app` and `cmd package uninstall
  com.stylewise.app` at 2026-11-15 22:28:09 +02. The normal package was absent
  afterward while `.stagingtest` remained installed. Flutter's pinned
  `AndroidApk.fromAndroidProject` source falls back to `AndroidProject.namespace`
  when it cannot read a built APK, and its integration-test teardown stops and
  uninstalls the package object it selected. The recorded package mismatch is
  confirmed; whether this invocation took that fallback because its expected
  APK path was unavailable at lookup time was not separately logged.
- The test therefore **did not preserve** the normal app installation or local
  authenticated session. The original normal app was reinstalled from the
  existing staging artifact (same APK SHA/certificate, version code 3), and
  its sign-in screen appeared. Its install timestamp is now
  `2026-11-15 22:31:24`, not the prior `22:07:32`; the prior local session did
  not survive. No attempt was made to clear app data. Server-side staging
  records were not changed by this timed-out test. The normal app is currently
  installed but signed out; the owner must authenticate again.
- Corrective source change: the test variant now sets both Gradle
  `applicationId` and `namespace` to `com.stylewise.app.stagingtest`, matching
  Flutter's observed fallback. The activity is named by its absolute class
  `com.stylewise.app.MainActivity`, so changing the test namespace does not
  change the Kotlin activity class. The runner now refuses to start unless
  Gradle confirms both identities and the pinned Flutter package source still
  contains the namespace fallback. Its post-run package inspection also handles
  a missing normal package explicitly instead of exiting before reporting the
  mismatch.
- The normal package is currently signed out because of the earlier uninstall;
  its prior session was not retained. Google sign-in and email confirmation
  were not exercised by either package-isolation attempt.
- **Next owner action:** sign back into the restored normal staging app before
  starting the full smoke. The full runner preflights both the Gradle package
  ID and namespace as `.stagingtest`, then launches the isolated app. When its
  active test prints `SIGN_IN_REQUIRED`, authenticate privately in
  `Everywear UI Smoke Test (STAGING)` on the connected phone. After the run,
  verify the normal app is still installed and visibly authenticated; package
  metadata alone cannot prove session preservation. Do not run integration
  tests against `com.stylewise.app`.

### Minimal Flutter package-isolation verification (2026-11-15)

- The full authenticated smoke test remains paused. Added
  `integration_test/package_isolation_test.dart`, which imports only Flutter
  Material, Flutter test, and `integration_test`; it directly renders a single
  fixed message and makes no Supabase/auth/provider calls. Added a separate
  runner script that requires the approved staging project ref, checks the
  runner source paths and Gradle test ID/namespace, records normal package
  metadata, captures new logcat entries without clearing the existing buffer,
  then verifies the normal package and test-package cleanup afterward.
- Source trace for the pinned Flutter runner:
  `IntegrationTestTestDevice.start()` obtains one `ApplicationPackage` and
  passes it to `AndroidDevice.startApp()`. `AndroidApk.fromAndroidProject()`
  reads the APK manifest package when its selected APK path exists; otherwise
  it falls back to the manifest package or Gradle namespace. Android install
  uses the built APK path, Android launch uses the refreshed APK's
  `launchActivity`, and `stopApp`/`uninstallApp` use `ApplicationPackage.id`.
  Integration-test teardown uses the original package object's ID. The test
  variant now aligns both application ID and namespace with
  `com.stylewise.app.stagingtest`; its absolute activity class is
  `com.stylewise.app.MainActivity`. Thus both APK-derived and namespace-fallback
  identities map package operations to `.stagingtest`.
- On A065 user 0, the minimal Flutter integration test rendered its fixed
  marker and reported **1/1 passed**. Verbose Flutter output records the APK
  manifest package as `com.stylewise.app.stagingtest`, then shows install of
  that APK, launch of
  `com.stylewise.app.stagingtest/com.stylewise.app.MainActivity`, and cleanup
  via `force-stop` and `uninstall com.stylewise.app.stagingtest` (uninstall
  succeeded). The run-scoped logcat contains no normal-package stop/removal
  operation. Afterward, `com.stylewise.app` remained installed at version 3
  with the same first-install and last-update timestamps recorded before the
  test (`2026-11-15 22:31:24`); `.stagingtest` was absent as expected. No normal
  package install, launch, force-stop, uninstall or settings operation was
  issued by this check. The normal app was already signed out before the check,
  so authenticated-session retention was not testable.
- The first wrapper run used the full existing logcat buffer and found the
  earlier, pre-run uninstall event; that was a stale-log false positive. The
  second run used `logcat -T 1` and the Flutter widget test passed, but the
  wrapper returned 1. Retained source plus a direct ADB check identified the
  exact cause: after Flutter correctly uninstalled `.stagingtest`,
  `adb shell pm path com.stylewise.app.stagingtest` returned status 1 with
  empty output. Under `set -euo pipefail`, the command substitution exited
  before the wrapper could recognize the expected absence. This was a
  post-cleanup reporting/control-flow bug, not a normal-package operation.
- Added `read_android_package_path()`. It treats only exit 1 with empty output
  as “package not installed”; nonempty ADB errors remain failures. Its focused
  shell regression covers installed path, expected absence and device-offline
  error cases. Both package runners now use it, check device connectivity,
  verify normal version/install/update timestamps, and explicitly verify the
  isolated package was cleaned up. `logcat -T 1` ensures prior ring-buffer
  events cannot be confused with operations during the run.
- Re-ran the minimal device isolation check after this fix. Flutter integration
  test: **1/1 passed**; Flutter CLI exit status: **0**; wrapper exit status:
  **0**. Run-scoped verbose output again shows install/launch/stop/uninstall
  only for `com.stylewise.app.stagingtest`; the isolated package is absent
  afterward. Normal `com.stylewise.app` remains installed, version 3, with
  first-install and last-update timestamps both unchanged at
  `2026-11-15 22:31:24`. The run-scoped logcat contains no normal-package
  stop/removal operation. No login or backend write occurred. Evidence logs
  (mode `0600`):
  `/tmp/everywear-package-isolation-run-20261115-230825-1718207.log` and
  `/tmp/everywear-a065-package-isolation-20261115-230825-1718207.log`.
- The full test’s private-auth wait is now 15 minutes, within an explicit
  25-minute widget-test timeout. At `SIGN_IN_REQUIRED`, the process remains
  connected and pumps the test while waiting; no synthetic records are written
  until `currentUser` exists. Flutter only runs its stop/uninstall teardown
  after the test completes or times out, so the test app stays available for
  sign-in during the wait. Cleanup then intentionally removes only
  `com.stylewise.app.stagingtest`.
- The full smoke has not been started. The normal app remains installed but is
  signed out from the earlier uninstall; its metadata was unchanged during the
  minimal isolation check. The test app was removed by expected teardown.
  Before the full run, the owner must sign in privately to the normal app. When
  the active integration test prints `SIGN_IN_REQUIRED`, sign in to the
  foreground app labeled `Everywear UI Smoke Test (STAGING)`; it stays active
  while waiting (up to 15 minutes). Afterward, package metadata is checked
  automatically and the normal app will be brought to the foreground for a
  private screenshot check of its authenticated screen.
- Private evidence files are
  `/tmp/everywear-package-isolation-run-20261115-225128-1712513.log` and
  `/tmp/everywear-a065-package-isolation-20261115-225128-1712513.log` (mode
  `0600`). They contain runner/Android logs and must remain private.
- **Next owner action:** sign into the normal staging app again. The test app
  was removed by its expected Flutter teardown; prepare/launch the separately
  labeled staging-test app for private sign-in only after resolving the wrapper
  exit status. Keep the full authenticated smoke paused until both app sessions
  are established.

### Full isolated UI smoke: Today refresh assertion review (2026-11-16)

- The latest full run reached the authenticated staging account, uploaded and
  displayed the synthetic wardrobe image, and created an `outfit_logs` row
  that the smoke test found for the current user and current local date. The
  failing assertion expected a `DailyLog` outfit card, but observed
  `cardsBefore=0` and `cardsNow=0`; `captureFormVisible=false` only showed that
  the outfit form was gone.
- This failure does **not yet prove** a product refresh defect. The test
  measured `cardsBefore` while the Wardrobe tab was active, where Today is an
  offstage `IndexedStack` child, and did not assert that the visible route had
  returned to Today. The item-card finder excludes offstage widgets. The
  staging row/date check is valid, but the UI assertion did not distinguish a
  failed refresh from a stale/offstage test observation. No fresh device run
  was started during this review.
- The smoke test now waits for the Today screen after selecting its tab and
  records its card baseline there. Each rendered Today card has a stable
  test-facing key derived from its outfit row ID, and the return assertion
  waits for the exact saved row's card. Smoke-only load markers record the
  selected date and fetch row count, so a future run can distinguish route
  return, refresh invocation and rendered data without weakening the check.
  `pushRouteAndRefresh` already has a focused regression test that verifies a
  dismissed route still triggers one refresh.
- Focused checks performed: `flutter test
  test/presentation/daily_log/quick_log_navigation_test.dart
  test/core/ui_smoke_test_mode_test.dart` passed (2 tests); targeted Dart
  analysis completed with 10 existing informational lints and no errors;
  `git diff --check` passed. No full device test, build or new staging write
  was performed in this review. Existing synthetic staging rows and uploaded
  images were preserved.
- The integration runner exited 1 after the assertion and its expected
  teardown removed only `com.stylewise.app.stagingtest`. `com.stylewise.app`
  remained installed with unchanged package metadata, but that does not prove
  its authenticated session. A follow-up read-only device check at
  `2026-11-16 12:17 +02` found the launcher foregrounded, normal package
  version code 3 installed (first install and last update remain
  `2026-11-15 22:31:24`), and the isolated test package absent. The normal
  Everywear session remains unverified. The owner should bring the normal app
  to the foreground for a session check before another isolated run is
  considered.

### Profile-name source verification (2026-11-16)

- Signup passes the trimmed name as `raw_user_meta_data.full_name`; the
  existing Auth trigger copies that value into `user_profiles.full_name`; the
  Profile screen resolves auth metadata first, then profile data, and only then
  falls back to email. The current normal-app APK has not been brought to the
  foreground to verify the rendered result after the fresh signup.
- Focused local tests for the display-name resolver and signup request passed
  **6/6**. These confirm request construction and fallback precedence, not a
  live confirmation callback, database trigger execution, or device display.
- Follow-up implementation: onboarding now also copies a non-empty trimmed
  `full_name` from the authenticated signup metadata into the signed-in user's
  `user_profiles` row. Empty metadata leaves the existing profile value
  untouched. The isolated UI smoke now checks that the profile row contains
  the same name when auth metadata is available. The focused name, signup, and
  optional-onboarding-photo tests passed **9/9**; targeted analysis found 3
  informational import/key lints and no errors. This does not replace the
  pending fresh-account device verification.

### Today row visibility and auth-session investigation (2026-11-16)

- The failed smoke assertion expected the exact saved outfit card
  (`today_outfit_<saved row id>`) to be visible immediately after route return.
  The run recorded the Today fetch changing from 3 to 4 rows, the authenticated
  query returning the exact newly saved outfit ID, and `cardsBefore=0` /
  `cardsNow=0`; it then timed out looking for the card. The test had not scrolled
  the long Today page. This supports a test observation gap around the lazy,
  offscreen list, not a demonstrated failure to refresh. It is not a device
  verification that the revised assertion passes.
- Added a finite, 20-scroll search for the exact saved row ID. The smoke now
  retains its row query and rendered-card-count refresh assertion, and also
  requires the exact keyed card to overlap the Today viewport and contain the
  expected outfit label and wardrobe item tooltip. Added a widget regression
  for bounded scroll-to-row behavior. Profile-name and final sign-out checks
  remain **not run** because the prior integration stopped at Today.
- Auth findings: the test called `signInWithPassword` in
  `com.stylewise.app.stagingtest`. Its explicit final logout is after the
  failing Today assertion and was not reached. Flutter teardown stopped and
  removed only that test package; the normal package's install/update metadata
  was unchanged. The normal app later rendered sign-in, so session preservation
  failed at the UI level even though package metadata was unchanged. No normal
  process auth-event trace was captured, so the reason its UI was signed out is
  **unresolved**.
- Local source evidence rules out shared Android preference files between the
  two package IDs: Android app data is package-private. Both app variants use
  the same staging Supabase project and can authenticate the same account, but
  their persisted sessions are local to each package. `AuthSessionService`
  was the only app sign-out path; the pinned GoTrue default is local scope, and
  the app now requests `SignOutScope.local` explicitly. Account cleanup only
  removes this package's app caches/preferences and does not clear the Supabase
  auth storage key. Debug auth-state subscription now records only event name
  and session presence, never user IDs or credentials.
- These checks do not establish whether Supabase invalidated/expired the normal
  session, whether normal-app token refresh failed, or whether the prior sign-in
  screen was a transient UI state. A targeted device run must first record the
  normal app's authenticated screen, sign into the isolated app as needed, then
  inspect the isolated app's sanitized auth events and then the normal app's
  authenticated UI after the isolated run. The normal app would need the new
  diagnostic build to expose its own auth events. Added an auth-only isolated
  integration target and restricted
  the existing runner allowlist to accept it; this target only initializes the
  staging app and confirms its session, with no profile or wardrobe writes. It
  retains the immediate `SIGN_IN_REQUIRED` handoff. The device target was not
  built or run in this checkpoint.
- Focused checks: the bounded-scroll widget regression plus Quick Log refresh
  and smoke-mode tests passed **3/3**. Targeted Dart analysis of changed files
  completed with no errors after removing the new warning. `dart format` and
  `git diff --check` passed. No Android build, authenticated device run,
  backend write, profile-name check, or final sign-out check was performed.
- Staging data and the normal app were not modified during this investigation.
  The two unrelated Linux/macOS formatting changes remain unstaged.

### Auth-only isolated device check (2026-11-16)

- Built and installed the normal staging app with the new sanitized auth
  diagnostics before relying on them. APK:
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-4-aftdbphdobfrshienple-debug-AUTH-EVENTS-20261116.apk`;
  SHA-256 `52650bfb199d4be4ce238fff543db4cd51651bda0aa9f41e68590b5abd4773c9`.
  It remains package `com.stylewise.app`, version code 4, and its signing
  certificate matches the retained beta-4 APK. Installed with `adb install -r`;
  `firstInstallTime` stayed `2026-11-16 13:21:52`, confirming an in-place
  update. No app data was cleared.
- On A065, the installed normal app emitted `initialSession; session=present`
  at `14:23:02 +02` before the isolated run. During the isolated runner wait it
  emitted `tokenRefreshed; session=present` at `14:36:13 +02`. After test
  cleanup, I force-stopped and relaunched the normal app without clearing data;
  it emitted `initialSession; session=present` at `14:57:19 +02`. These events
  verify that the persisted normal session survived runner installation,
  execution, cleanup, and a process restart in this run. The sanitized event
  record is retained at `/tmp/everywear-auth-isolation-20261116-142246/normal-events.log`
  with mode `0600`. Each event appeared twice at the same timestamp; whether
  that reflects duplicate stream delivery or duplicate logging is unresolved.
- The isolated package identity was `com.stylewise.app.stagingtest` and was
  foregrounded while waiting. Its initial auth state was
  `initialSession; session=absent`. The owner did not complete private sign-in
  before the test's 15-minute authentication wait expired, so the auth-only test
  exited with `Timed out waiting for isolated auth state`. The runner then
  removed the isolated package and confirmed the normal package remained at
  version 4 with unchanged install/update metadata. No profile or wardrobe
  writes occurred.
- Since isolated sign-in did not happen, retention **after test-app sign-in**
  is not tested. This auth-only target performs no logout, so retention after
  test-app logout is also **not run**. The normal session was verified after
  cleanup as described above. The earlier report of the normal app showing
  sign-in after a different full smoke run remains unexplained and was not
  reproduced without test-app sign-in.
- Payments/ads stayed disabled; only approved staging was used. No production
  changes or publication occurred. Profile-name, Today UI, and final sign-out
  checks remain not run in this auth-only attempt. Before another auth-only
  attempt, coordinate a time when the owner can complete sign-in promptly; do
  not silently sign the normal app back in if any later check reports an absent
  session.

### Auth-only run and test-app identity follow-up (2026-11-16)

- The owner reported seeing a green screen, then black, followed by the app
  closing/display going dark, and could not tell the test app from normal
  Everywear. Source confirms the test package had a distinct Android ID and
  launcher label, but reused normal app screens with only the small corner
  `STAGING` ribbon. The test build had no prominent in-app identity marker.
- The retained auth-only runner output shows the test package began with
  `initialSession; session=absent`, then emitted `signedIn; session=present`
  after private sign-in. The test proceeded to its normal-app inspection
  checkpoint, called `signOut(scope: SignOutScope.local)`, emitted
  `signedOut; session=absent`, and reached its completion marker. The
  foreground round-trip detector accepted a return after any sustained
  background period; it did not require the owner to confirm what the normal
  app displayed. This explains why the test could proceed to sign-out and
  teardown without an explicit visual confirmation.
- The Flutter runner then force-stopped and uninstalled only
  `com.stylewise.app.stagingtest`. Its test process reported a teardown
  invariant failure because `app.main()` changed the process-global
  `ErrorWidget.builder`. This is a confirmed test-harness cleanup failure,
  separate from auth failure. No raw device log showed an app crash as the
  cause of cleanup. The phone's earlier display-off moment was not captured;
  at follow-up it was awake on the launcher.
- Follow-up on the connected A065 launched the normal app without changing or
  clearing data. It emitted only sanitized `initialSession; session=present`
  events (duplicated at the same timestamp), and was foregrounded afterward.
  Version code 4 and first/last install timestamps remained `13:21:52` /
  `14:21:09`. This verifies the normal session **after test cleanup and app
  restart**. Normal-app session state was not directly observed at the two
  intermediate checkpoints, so retention specifically after test sign-in and
  after test-app sign-out remains unverified.
- Implemented for the next isolated run: the runner supplies a test-only Dart
  define; the app displays a fixed, full-width orange
  `AUTOMATED TEST APP • STAGING` identity bar on every app screen; and both
  normal-session checkpoints now require a visible owner confirmation button
  before local test sign-out or cleanup can continue. Automated test builds
  leave Flutter's global `ErrorWidget.builder` unchanged to avoid the binding
  teardown invariant. The normal staging app retains its existing subtle
  staging ribbon; no production behavior changes.
- Verification performed: focused staging-banner widget tests passed **2/2**;
  targeted Dart analysis completed with no errors (four pre-existing
  informational lints in `lib/main.dart`); targeted formatting and
  `git diff --check` passed. No build or integration test was run for this
  follow-up. Therefore the new identity bar, confirmation pauses and teardown
  behavior have not yet been verified on-device. The auth-only run itself did
  not write profile/wardrobe data; its explicit logout affected only the test
  package's local session. Normal package remained installed and its session
  was present after cleanup/restart. Ads/purchases remained unavailable; only
  staging was used.
- Next device step: rebuild through `scripts/run_staging_ui_smoke.sh` with
  `EVERYWEAR_UI_SMOKE_TEST_TARGET=integration_test/auth_session_isolation_test.dart`.
  At the emitted `SIGN_IN_REQUIRED`, sign in only to the app with the large
  orange automated-test bar. At each modal confirmation, switch to normal
  Everywear, inspect its signed-in screen, return to the visibly labeled test
  app, and press **I checked — continue**. If normal Everywear shows sign-in,
  do not authenticate it; stop and preserve the session evidence. Then verify
  normal session state after test cleanup/restart as a separate check.

### Updated isolated auth run and loading-screen identity (2026-11-16)

- Commit `a33c6dc97a6bce63c2984b1ee9b2cd4601cff9a5` added the first full-width
  test identity overlay, confirmation gates, and a test-only guard around
  `ErrorWidget.builder`. The focused widget tests and targeted analysis passed
  before this device attempt.
- The staging helper built the isolated APK twice successfully (prebuild and
  integration-runner build), confirmed package
  `com.stylewise.app.stagingtest` before launch, and kept the normal package
  installed. On A065, the sign-in screen showed the large orange identity bar.
  After the owner signed in, the screen changed to the green AuthGate profile
  loader (“Aligning your style…”), where the identity overlay was reduced to a
  thin orange strip with no readable label. The owner had previously reported
  that this made the app impossible to distinguish. A private screenshot is
  retained at `/tmp/everywear-current-test-screen-KZxXFD.png` (mode `0600`).
- Sanitized runner output confirms `initialSession; session=absent`, then
  `signedIn; session=present`, and the normal-session checkpoint. The process
  did not reach the new confirmation dialog or sign-out marker. The runner
  stopped without a captured final test result or exit status; the isolated
  package remained installed and foregrounded on the loader. This run is
  **incomplete**, and no reason for the runner exit is established. A staging
  subscription-verification request also returned the expected `503` because
  RevenueCat verification is unconfigured; it is not established as the cause
  of the runner stopping. Ads and purchases remained disabled.
- After test-app sign-in, the normal package was force-stopped and restarted
  without clearing data. Its sanitized auth log emitted
  `initialSession; session=present`; version code and install/update metadata
  were unchanged. This confirms normal-session retention after test-app
  sign-in and normal-app process restart. No normal-app screen was manually
  confirmed at the intermediate checkpoint, so visual verification remains
  pending. No profile or wardrobe writes occurred.
- The overlay-only identity implementation was replaced with a reserved,
  full-width header row. This avoids allowing app content to paint over the
  label during AuthGate loading. A widget regression now checks the reserved
  header height and visible label. This source change is included in the
  local checkpoint, but its persistence through AuthGate loading has not been
  confirmed by a clear on-device capture.
- The owner switched to normal Everywear during the updated run and confirmed
  its Today page remained visible with only the small corner staging ribbon.
  The test runner had reached `NORMAL_SESSION_CHECK_REQUIRED_AFTER_TEST_SIGNIN`
  and was alive during this inspection. The isolated app itself was clearly
  identified by the full-width header on its earlier sign-in screen, but the
  post-authentication identity display still needs a clear device check.
- That run then reached the manual checkpoint and failed with
  `No MaterialLocalizations found`: the dialog was opened using a context from
  above the `MaterialApp` localization scope. The runner exited with status 1
  and confirmed that cleanup removed only `.stagingtest`. This is the exact
  test-harness failure; it is not an auth or normal-app failure. Since cleanup
  removed the isolated package, its local session is gone and the next run
  needs private test-app sign-in again. The normal app remains installed and
  the owner confirmed it still showed Today; no data was cleared.
- Fixed the dialog call to use a `Scaffold` context under `MaterialLocalizations`
  and extracted the checkpoint dialog. The new focused regression verifies it
  requires the explicit button and returns success only after the tap. Focused
  banner/dialog tests passed **3/3**, targeted Dart analysis reported no issues,
  formatting and `git diff --check` passed. No build or device rerun has been
  performed after this correction. The dialog and fixed-height header remain
  unverified on the phone; profile/wardrobe writes and test-app local sign-out
  were not run.

### Auth checkpoint input failure and native confirmation (2026-11-16)

- On the next A065 run, the native app label and full-width test banner were
  visible. The test requested private sign-in; the app emitted
  `signedIn; session=present`. The owner switched to normal Everywear and
  reported its Today page remained visible with only the normal small staging
  ribbon. The normal auth diagnostic had recorded `initialSession; session=present`.
- The test then emitted `signedOut; session=absent` after its local test-app
  sign-out. The owner returned to the test app, but reported the Flutter
  confirmation button did not respond after two taps. A fresh screen capture
  showed a visually enabled Flutter button. One targeted `adb input tap` at
  the button center also produced no state change. The runner remained blocked
  in the confirmation gate; no final normal-session-after-sign-out result was
  accepted.
- The runner was interrupted deliberately. Its guard reported the normal app
  unchanged and correctly failed because the isolated test package remained
  installed after interruption. The normal app was not uninstalled or cleared.
  No profile/wardrobe writes occurred. The test app had already signed out
  locally; no remote session was revoked.
- The failure is isolated to interactive confirmation under Flutter's live
  integration-test pointer handling; the precise low-level event loss is not
  proven. Replaced the Flutter dialog with a native Android `AlertDialog` on
  the debug-only smoke-test method channel, restricted to two fixed checkpoint
  names. The Dart test waits for an explicit native positive-button response;
  invalid checkpoints fail closed. This should bypass Flutter pointer
  interception, but native behavior is not yet built or device-verified.
- Focused banner and native-channel helper tests passed **4/4**; targeted Dart
  analysis found no issues; formatting and `git diff --check` passed. Kotlin
  compilation is pending a staging build. Next run must use the connected A065,
  preserve the normal package, and require private sign-in because interrupted
  test cleanup left its package installed but locally signed out. At each
  checkpoint, the owner must inspect normal Everywear and tap the native
  **I checked — continue** button. Profile-name, wardrobe and final normal-app
  session checks remain unverified.

### Native checkpoint build and inspection timeout (2026-11-16)

- The staging helper and integration runner both built the Android app
  successfully with the native checkpoint bridge; Gradle package preflight
  confirmed `com.stylewise.app.stagingtest`. The owner signed in privately and
  the test logged `signedIn; session=present`. It then waited at the first
  normal-app inspection checkpoint.
- The owner later confirmed normal Everywear displayed its authenticated
  Today page, but the test had already exceeded its ten-minute background/
  return window before the owner returned to the test app. It failed at
  `_waitForNormalAppInspection` before showing the native dialog; there was no
  test-app local sign-out. Flutter cleanup removed `.stagingtest`, which is why
  the test app disappeared. The normal package stayed installed with version
  and install/update timestamps unchanged; the owner still had normal Today.
  The isolated package's local sign-in was lost with cleanup. No profile or
  wardrobe writes occurred.
- Kotlin/native dialog compilation is verified by the successful APK build,
  but native confirmation taps are **not device-verified**. The runner did not
  reach either native dialog. The check's authenticated-session retention
  after test sign-in remains based on the normal app's prior sanitized
  `initialSession; session=present` and the owner's Today observation; the
  post-test-sign-out check remains not run.
- Extended each normal-app round-trip and native confirmation wait to 20
  minutes and the overall integration-test timeout to 65 minutes. This is
  committed separately; targeted tests and another staging run are pending.
  The next run requires private sign-in again because cleanup uninstalled the
  isolated package. Production was untouched; ads and purchases remained off.

### Successful isolated auth-session check (2026-11-16)

- On A065, the isolated `com.stylewise.app.stagingtest` build launched and
  accepted the owner's private sign-in. Sanitized auth events showed
  `initialSession; session=absent`, then `signedIn; session=present`.
- At the first native checkpoint, the owner checked normal Everywear and
  confirmed its authenticated Today page was still visible. The isolated test
  then performed explicit local sign-out and logged
  `signedOut; session=absent`. At the second native checkpoint, the owner
  confirmed normal Everywear remained on Today. No profile or wardrobe writes
  were made.
- The integration test completed **1/1 passed** and the runner exited 0. Its
  package guard confirmed cleanup removed only
  `com.stylewise.app.stagingtest`; it did not uninstall or clear the normal
  app. The normal app's post-cleanup restart emitted
  `initialSession; session=present`. Package metadata remained version code 4,
  first installed `2026-11-16 13:21:52`, last updated
  `2026-11-16 14:21:09`; its resumed activity was
  `com.stylewise.app/.MainActivity`.
- This verifies auth-session isolation for this staging test and normal-app
  process restart. It does not verify profile-name display, wardrobe upload,
  outfit creation, Today refresh, broad smoke flows, or another-device email
  confirmation. Those checks remain not run. Google sign-in and a fresh
  confirmation-link return also remain unverified. RevenueCat verification
  remains unconfigured (staging returned the expected 503); purchases and ads
  stayed disabled. Production and Clameo were untouched.

### Latest normal staging APK: manual core checks (2026-11-16)

- Current normal install on A065 is `com.stylewise.app`, version code 4,
  version `1.0.0-beta.1`, installed in place at `2026-11-16 14:21:09`.
  The APK is
  `build/beta-artifacts/Everywear-Uptodown-Free-STAGING-Beta-1.0.0-beta.1-4-aftdbphdobfrshienple-debug-AUTH-EVENTS-20261116.apk`,
  SHA-256 `52650bfb199d4be4ce238fff543db4cd51651bda0aa9f41e68590b5abd4773c9`.
  The relevant source includes outfit/Quick Log fix `a63a3c4` and profile-name
  persistence fix `71e1dc9`; there are no later application-source edits to
  the outfit-preview or Quick Log return-refresh implementations.
- **Profile name: failed on the latest APK.** The owner confirmed the profile
  label is the email handle rather than the name entered at signup. The screen
  renders a distinct label above the email, but it is the wrong label. Current
  source passes the signup name as Auth `full_name`, copies non-empty metadata
  to `user_profiles.full_name` during onboarding, and resolves auth metadata
  before the profile row. This evidence establishes the displayed-value
  failure; it does not establish whether the value was wrong at form
  submission, stored by Auth, or returned by the profile query. No account
  record was changed. Fix requires tracing the value at those boundaries
  without logging personal data.
- The owner navigated to Today and then wardrobe selection using an existing
  synthetic tee. The manual session paused on the selection screen before
  confirmation; **latest-build outfit preview and Quick Log automatic Today
  refresh are not yet checked in this pass**. Earlier device evidence remains
  valid history: on version-code-2 staging build, the owner saw the tee on the
  confirmation preview and Today updated from one to two entries after
  Quick Log returned without manual refresh. That build included fix `a63a3c4`;
  no later app-source change touched those two behaviors, but this pass has not
  repeated them on version code 4.
- A PID-scoped, private app log was captured during this manual session at
  `/tmp/everywear-manual-app-7435-20261116-200331.log` (mode `0600`). No
  exception class or app error entry was found in its captured 480 bytes. The
  device remained on `com.stylewise.app/.MainActivity`; no automated taps,
  new outfit saves, or account changes occurred. A broader initial logcat
  capture was also kept locally with mode `0600`; it includes other device
  processes and is not used as Everywear evidence.
- No builds, test suites, analyzers, production operations, or isolated smoke
  runs were performed for this checkpoint. Next: finish the latest-build
  confirmation-preview and Quick Log checks using the existing synthetic tee,
  then trace the profile-name value without exposing account data. Google
  OAuth provider setup, a fresh email-confirmation return, AI inference/model
  validation, and release-mode validation remain separate blockers.

### Unattended test direction and profile-name evidence (2026-11-16)

- The personal A065 is released from testing. All task-started logcat sessions
  were stopped, files were retained privately with mode `0600`, and the ADB
  server was stopped to release its USB connection. This task changed no phone
  settings, app data, installed packages, auth session, or account records.
- Host inspection: x86_64, 12 CPUs, AMD-V; `/dev/kvm` is accessible. Android
  Emulator and an existing `Medium_Phone` AVD are installed, using an
  x86_64 Android 37 Play Store image, hardware GPU, and 2 GiB guest RAM. At
  inspection, 3.9–4.2 GiB RAM was available and the 512 MiB swap was fully
  occupied. Existing Gradle/Kotlin daemons held about 2.9 GiB RSS combined.
  The host supports a hardware-accelerated emulator, but emulator + build
  should wait until daemon/build memory is available; no emulator was started.
  CI is not required for hardware support. If local capacity remains unstable,
  the fallback is an ephemeral GitHub Actions Android emulator job, requiring
  owner-approved runner minutes/secrets and no upload of test APKs or logs.
- A focused local run passed **8/8** tests:
  `.tooling/flutter/bin/flutter test --no-pub --concurrency=1
  test/core/profile_display_name_test.dart test/services/auth_redirects_test.dart`.
  It validates trimming/name precedence and that the signup helper sends its
  supplied name in `data.full_name`; it does not exercise the physical signup
  form or a live Auth request. The initial bare `flutter` invocation failed
  because Flutter is project-local; it was rerun successfully using the pinned
  `.tooling/flutter` SDK.
- Read-only staging metadata query, explicitly targeting
  `aftdbphdobfrshienple`, returned aggregate-only results for the last seven
  days: **2** Auth accounts, **0** with `raw_user_meta_data.full_name`, and
  **2** profile rows whose `full_name` matches the email local part. No email,
  name, UUID, token, or individual row was returned. The aggregate cannot
  uniquely associate either row with the owner's account.
- Read-only deployed trigger inspection confirms
  `public.handle_new_user()` sets `user_profiles.full_name` to
  `raw_user_meta_data.full_name`, falling back to `split_part(NEW.email,'@',1)`
  when the metadata name is absent. This explains how the observed handle can
  appear. Local signup code passes the separate name controller into the
  helper, onboarding mirrors metadata to the profile, and the focused helper
  test passes. The live signup request/body for the owner's account was not
  captured, and the aggregate rows were not individually correlated; therefore
  the evidence does **not** establish why the name metadata was absent or
  prove which row is the owner's. No signup was repeated and no account was
  changed. Preserve this as a confirmed display defect with this precise
  source/backend evidence gap; do not infer the submitted name or retrieve
  private account values.
- Unattended device strategy: use the existing local AVD, not a personal
  device; authenticate only a dedicated, confirmed synthetic staging account;
  load its credentials from a private host-side file (mode `0600`, outside
  Git) at test runtime, never a Dart define or APK; prepare uniquely tagged
  synthetic records through the signed-in staging client and clean only those
  records/objects. Current integration tests still wait for owner sign-in and
  therefore are not unattended. Do not run them until this host-side login and
  test-data setup is implemented and credential values are supplied privately.
  Keep the existing fixed staging project guard, ads disabled, billing
  unavailable, isolated package identity, and teardown safeguards.
- Latest manual pass status: Profile name failed as owner-confirmed; latest
  APK outfit preview and Quick Log refresh were left pending before selecting
  the existing synthetic tee. Earlier version-code-2 visual passes remain
  recorded and were not invalidated by later edits to those code paths. No
  personal-phone tests, builds, production changes, pushes, or publication
  occurred in this checkpoint.

### Emulator smoke preflight and signup-name reconciliation (2026-11-16)

- No build/test/emulator was active. `./gradlew --status` showed the sole
  Gradle 8.11.1 daemon idle; `./gradlew --stop` stopped it, and the idle
  project Kotlin compiler daemon received `SIGTERM`. Available RAM increased
  from about 4.0 GiB to **6.8 GiB**; swap remained nearly full. No unrelated
  processes were stopped.
- Hardware is available: AMD-V, accessible `/dev/kvm`, installed Android 37
  x86_64 Play Store emulator, and existing `Medium_Phone` AVD configured for
  2 GiB guest RAM. The emulator was not started because the required private
  test-account credential file is missing. Start it only after that
  prerequisite is supplied; current post-daemon headroom is otherwise adequate
  for this AVD. The physical phone remains released and untouched.
- The existing private Supabase app config is present at
  `/tmp/everywear-staging-aftdbphdobfrshienple-private/app-config.json`
  (mode `0600`). No dedicated smoke-account credential file was found in the
  checked Everywear config locations. The existing integration test has a
  15-minute manual `SIGN_IN_REQUIRED` wait and no host-side authentication;
  it is not safe to run as an unattended test yet. Do not launch until the
  owner supplies the one private credential bundle: a preconfirmed dedicated
  staging login email/password plus a separate disposable signup inbox
  address/access for the controlled signup check. Keep it outside Git and
  never pass credentials as Dart defines or bundle them in the APK. Ads stay
  disabled and RevenueCat billing unavailable.
- Source and focused tests: the signup form's separate name controller is
  passed to `signUpWithEmailRedirect(fullName: ...)`, which puts its trimmed
  value in Auth `data.full_name`; the helper test checks that request body.
  The Profile screen uses auth metadata before `user_profiles.full_name`, and
  onboarding mirrors a non-empty metadata value into that row. Focused tests
  passed **8/8** using `.tooling/flutter/bin/flutter` for profile-name
  normalization/precedence and signup redirect/request metadata.
- Read-only staging inspection confirms the deployed `handle_new_user()`
  trigger populates `user_profiles.full_name` from Auth metadata, falling
  back to the email local part when `raw_user_meta_data.full_name` is absent.
  Aggregate-only metadata for the last seven days showed two accounts, no
  `full_name` in either Auth metadata row, and both profile names matching the
  respective email local parts. No individual names, emails, UUIDs or account
  rows were returned. This aligns with the observed profile display defect.
  It does not identify either aggregate row as the owner's account or show
  why the actual signup request failed to preserve its supplied value.
- The controlled signup/login verification remains **not run**. It must use
  separate identities: authenticate core smoke with the preconfirmed account;
  create one uniquely tagged synthetic account via the signup UI/request;
  compare only the synthetic request name, Auth metadata and trigger-created
  profile value; then clean up only that synthetic account. Do not alter the
  owner's account, reuse manual phone flows, or infer success from the local
  helper test alone.

### Emulator-only unattended smoke preparation (2026-11-16)

- Added `scripts/create_staging_smoke_credentials.py`. It privately prompts
  for (1) the email/password of a **dedicated, preconfirmed staging login
  account** and (2) a **different disposable staging signup inbox address**.
  Password input is hidden and confirmed twice. It writes only
  `$HOME/.config/everywear/staging-smoke-credentials.json`, mode `0600`, and
  refuses to overwrite an existing file. The signup check generates a random
  one-use password in memory; it never shares the preconfirmed login account.
- The isolated debug-only Android MethodChannel accepts runtime credentials
  only when `packageName` is exactly `com.stylewise.app.stagingtest`. The host
  runner transfers just the login email/password through `adb exec-in` stdin
  into the test package's private files; values are absent from command
  arguments, shell history, Dart defines and the APK. The app consumes and
  deletes the file before calling Supabase Auth. Runtime-auth runs disable
  device logcat capture to prevent accidental credential persistence. Login
  failures report only an error type, never Auth response text or values.
- Added `scripts/run_staging_emulator_smoke.sh`, which requires the private
  config and credential file before starting anything, pins project
  `aftdbphdobfrshienple`, checks the existing x86_64/2 GiB `Medium_Phone` AVD,
  KVM and at least 6 GiB available RAM, and uses only `emulator-5554`. It
  installs the retained normal staging APK only as a package-preservation
  sentinel and never launches it. The existing guarded core smoke targets
  only `com.stylewise.app.stagingtest`; its cleanup removes only that package.
  Ads remain disabled and RevenueCat billing unavailable.
- Added `scripts/verify_staging_signup_metadata.py` for one separate synthetic
  signup before the login smoke. It refuses an already-used signup address,
  posts a synthetic `data.full_name` to the approved staging Auth endpoint,
  checks the Auth response, then issues a read-only metadata query to compare
  `auth.users.raw_user_meta_data.full_name` and trigger-created
  `user_profiles.full_name`. It emits only pass/fail status. The synthetic
  random password is not persisted or logged; the synthetic Auth record is
  retained. `EMAIL_CONFIRMATION=NOT_TESTED` is always reported: an unconfirmed
  signup does not prove email delivery, link confirmation or app callback.
- Lightweight checks actually performed: private credential-helper unit tests
  **2/2 passed**; auth redirect/signup-request Flutter tests **3/3 passed**;
  targeted Dart analysis of `integration_test/app_test.dart` reported no
  issues; Python syntax compilation, both shell syntax checks, Dart formatting,
  and `git diff --check` passed. The emulator script was invoked once without
  credentials and exited **2** at its private-file preflight; process inspection
  confirmed no AVD/emulator started. The local test confirms the app helper
  builds the request name field, while the controlled hosted signup has not run.
- Not run: no AVD start, Gradle/Android compile, APK install, emulator core
  smoke, staging signup, hosted metadata verification, full Flutter suite,
  production operation, phone interaction, push or publication. Kotlin
  compilation and actual secure credential handoff remain unverified. RAM
  after graceful daemon shutdown was about **6.8 GiB available**; swap was
  nearly full. The preconfirmed staging login credentials and separate
  disposable signup address are absent from checked private locations, so the
  runner correctly remains blocked before emulator launch.
- Exact owner action: from the repository run
  `python3 scripts/create_staging_smoke_credentials.py` in a private terminal.
  Enter only a dedicated preconfirmed staging login account and a distinct
  disposable staging signup inbox; do not paste either value into chat. Reply
  only when the helper reports it saved the file. Then the emulator runner can
  perform the single bounded signup-metadata check and core smoke without phone
  interaction. No owner account will be used or changed.
