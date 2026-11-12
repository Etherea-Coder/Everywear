# Everywear backend staging verification

This checklist is for a disposable, isolated Supabase staging project. It is not
a production rollout authorization. Production project `qxsdwwdrxoyxmnapuqqv`
remains read-only, and the local PostgreSQL harness is not a full Supabase
staging environment.

## Staging setup

- The approved staging target is `aftdbphdobfrshienple`, confirmed by the
  authenticated CLI as Everywear-staging in North EU/Stockholm. Owner confirms
  the existing organization is Free. Verify the exact ref again before each
  hosted write. Never use production or Clameo.
- Payments and advertising stay disabled; no RevenueCat sandbox is required
  for the free-beta checks. Do not configure or expose provider secrets. If a
  database password is requested, enter it at the CLI's hidden local prompt.
- Obtain staging anon/service-role keys only in a private local config when
  required for synthetic Auth/API tests. Do not copy any production keys or
  records; remove local secret files after the test window.
- Configure a disposable test account per actor (anonymous, user A, user B,
  service role) and synthetic records/images only. Set provider spend limits.
- Compare the staging schema and grants with the recovered metadata and this
  repository's complete ordered migration chain before applying anything.
  Do not use migration repair to mark reconstructed migrations as applied.
- Record a backup/restore point for staging and an operator, test window, and
  emergency contact. Confirm production project reference is not the target.

## Ordered migration checks

1. Apply `20261111090000_reconstruct_and_secure_backend.sql` to staging and
   inspect schema/RLS/grants before continuing.
2. Apply `20261111120000_lock_entitlement_mutator_grants.sql`; verify all
   overloads of legacy upgrade/quota/counter helpers are revoked from anon and
   authenticated, protected profile table/column grants are absent, legitimate
   profile update columns remain, and only service role can execute the exact
   `apply_subscription_event` signature.
3. Apply `20261112100000_server_ai_action_quotas.sql`; verify the authenticated
   quota entry points, no direct table access, and fail-closed behavior when
   policy/profile/entitlement data is absent.
4. Apply `20261112140000_private_image_bucket_security.sql` on this
   synthetic-only staging project; verify both buckets are private and only
   owner-folder policies remain. This does not authorize immediate production
   cutover, which still needs reference conversion and client rollout.
5. Deploy compatible Edge Function revisions only after migrations are
   verified. Deploy authenticated AI handlers, purchase verifier, webhook and
   deletion function as a coordinated staging release.
6. Do not convert production image references in this test. Production's two
   existing hosted buckets are public; production record conversion and
   cutover remain a separately reviewed rollout after its client/storage
   matrix passes.

## Authentication and account isolation

- Anonymous requests to profile, billing history, quotas, and protected Edge
  Functions are denied; malformed, expired, wrong-project, and revoked JWTs are
  rejected before data/provider work.
- User A can edit allowed profile/onboarding fields but cannot read or modify
  user B profiles, wardrobe, outfits, billing rows, quota state, or Storage.
- User A cannot update tier, subscription status/expiry, RevenueCat identity,
  limits, usage counters, insert/delete a profile, invoke any legacy mutator,
  or call the verified billing RPC.
- On app cold-start/restored auth and explicit sign-in, the app performs a
  quiet backend entitlement verification. Confirm successful provider state
  updates the current user's tier, a no-entitlement response leaves them free,
  transient failures remain fail-closed, token refresh does not cause duplicate
  work, and account A to B switching cannot apply A's late response to B.
- Forged `user_metadata`/`app_metadata`, client tier values, future expiry,
  premium cache state, and a caller-selected UUID never grant premium.
- Authenticated outfit links require ownership of both the outfit and wardrobe
  item. Test cross-owner, missing-row, and concurrent link mutations.
- Use two users with deliberately different rows to prove RLS on every exposed
  relation. Confirm only intended columns are selectable and writable through
  PostgREST, not merely direct SQL role privileges.

## Private wardrobe/avatar images and deletion

Run only after the separately reviewed private-image cutover is scheduled:

- Exercise anonymous denial and owner A read/list/upload/replace/delete for
  wardrobe and avatar objects. User B must be denied for every operation.
- Check expired signed URLs resolve to a fresh owner-authorized URL, while
  unavailable objects produce a placeholder and do not expose another path.
- Check stable `bucket/path` references, exact-project legacy URLs, genuine
  external provider avatars, account-switch cache eviction, PDF image embedding,
  and CSV output that contains neither tokens nor expiring URLs.
- Confirm object owner-prefix validation and converted reference rows before
  making buckets private. Keep buckets private on rollback; if references fail,
  disable image delivery and repair via the private audit mapping.
- Delete a synthetic account with nested objects in both buckets and linked
  outfit data. Induce list/delete failures and verify deletion reports failure
  instead of claiming success; verify retry behavior is safe.

## AI eligibility and quota behavior

- For all five model-backed endpoints, reject anonymous/invalid identity before
  protected reads or provider calls. Verify the server derives the Supabase UUID
  and active entitlement; body-supplied user/tier/counters are ignored.
- Verify free 20/month, 3/day, 1/UTC-minute and one in-flight request; premium
  200/month, 20/day, 5/UTC-minute and three concurrent requests. Both paid terms
  share the premium allowance. Test month/day/minute UTC boundaries, active,
  grace/cancel before expiry, exact expiry, expired, missing expiry and
  downgrade.
- In parallel sessions, prove quota caps cannot be exceeded. Replay the same
  user/request UUID through the same and another endpoint; it must not create a
  second provider attempt. Different users may use independent UUIDs.
- Verify failed/timeout/malformed provider responses consume the reservation,
  finalization failure cannot refund it, and the client receives honest
  unavailable/exhausted errors. Manual wardrobe entry and deterministic outfit
  actions remain usable at quota exhaustion.
- Confirm images, prompt text, credentials and private data are not logged;
  only approved usage/latency/model/error metadata is collected. Use synthetic
  photos and provider test keys with spend caps.

## RevenueCat Billing and checkout

Use provider sandbox only and an isolated Supabase staging backend:

- Test signed-in purchase identity equals the Supabase UUID; caller-supplied
  RevenueCat customer IDs and other entitlement names cannot grant access.
- Verify exact entitlement, sandbox environment, renewal, cancellation while
  still paid through expiry, billing grace, expiry, refund/revocation, restore,
  duplicate event, stale/out-of-order event, and webhook signature rejection.
- Return from hosted checkout without paying: callback/resume alone must never
  grant premium; the backend snapshot verifier must report inactive.
- Test account A checkout in progress followed by logout/account B login.
  A's stale callback/response must not affect B. Verify RevenueCat SDK identity
  remains serialized across login, checkout, restore, and verification.
- Confirm missing public key, entitlement ID, link, server secret or expected
  environment leaves purchase unavailable. Test localized provider prices and
  honest cancel/error/restore states. Do not run a live charge.

## Ads, status and rollback

- Monetag remains disabled pending publisher onboarding and the official
  supported Android/Flutter SDK guide. No provider SDK, test placement or ad
  traffic is expected in this staging run. Verify missing provider configuration
  leaves ads absent. Future AdMob is also inactive; the provider boundary is
  scaffolding, not a working adapter.
- Verify account switching clears premium ad eligibility and no ads show during
  capture, text entry, authentication, checkout, or without consent. No rewarded
  AI allowance may be granted from a client callback.
- If any security assertion fails, stop staging rollout and preserve evidence.
  Use a forward correction. Roll back quota RPC availability by revoking the new
  entry points while preserving counters and reservations. Never restore the
  legacy self-upgrade/quota grants, public image access, or a permissive profile
  policy as rollback.
- Compare aggregate usage/error/latency and provider billing only. Do not claim
  production enforcement, live purchase behavior, or device readiness from this
  staging checklist.

## Current execution record — 2026-11-12

- Verified target: `Everywear-staging`, `aftdbphdobfrshienple`,
  `eu-north-1`; the owner confirmed the existing organization is on Free. The
  CLI's `production` label refers to this staging project's primary branch.
  Production `qxsdwwdrxoyxmnapuqqv` remained read-only; Clameo was untouched.
- All nine repository migrations were applied in order to staging. A subsequent
  migration list matched local and remote timestamps. The eight active Edge
  Functions are the names listed in the deployment record in
  `release-status.md`; gateway JWT verification is on. No provider secrets,
  webhook, payments, or ad integration were configured.
- Hosted synthetic checks passed in separate phases: Auth/PostgREST, protected
  billing fields, self-upgrade denial, user isolation, AI auth/quota behavior,
  and concurrent reservations **52/52**; user-filtered Realtime **5/5**;
  private wardrobe/avatar upload, delivery, replacement, deletion, and complete
  synthetic account deletion **31/31**. The passing phases were separate; the
  full `all` runner was not rerun as one combined command after two early
  assertion/Realtime harness defects were fixed.
- An aggregate query after cleanup found zero synthetic users, image objects,
  wardrobe rows, and outfit rows. No production customer content was queried.
- All five model-backed paths returned authenticated `AI_UNAVAILABLE` (503)
  with no configured provider, and the purchase verifier failed closed (503).
  This proves the no-provider behavior only; no model inference, quality,
  billing lifecycle, or real purchase was tested.
- Earlier local minimal PostgreSQL checks passed 48/48 pgTAP assertions,
  migration transition/rollback, and quota concurrency. The local Storage
  catalog/RLS stub passed 11/11 policy assertions. These are not full Supabase
  service tests; hosted staging API checks above cover the tested Auth,
  PostgREST, Storage, functions, and Realtime paths.
- Physical-device app startup, cold session restoration, export/PDF flows,
  notifications, and UI behavior against staging are still untested. No
  Android device is attached and the current staging debug APK has not been
  built. RevenueCat and Monetag remain disabled.
