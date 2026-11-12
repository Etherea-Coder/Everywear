# Everywear backend staging verification

This checklist is for a disposable, isolated Supabase staging project. It is not
a production rollout authorization. Production project `qxsdwwdrxoyxmnapuqqv`
remains read-only, and the local PostgreSQL harness is not a full Supabase
staging environment.

## Before provisioning

- Obtain owner approval for a separate Supabase project and RevenueCat sandbox
  project/entitlement. Do not clone production user data, Storage objects,
  secrets, or migration history.
- Configure staging-only Supabase URL/anon key, Edge Function service key,
  RevenueCat API/webhook credentials, exact entitlement ID and
  `REVENUECAT_EXPECTED_ENVIRONMENT=sandbox`. Keep all keys private.
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
4. Deploy compatible Edge Function revisions only after migrations are
   verified. Deploy authenticated AI handlers, purchase verifier, webhook and
   deletion function as a coordinated staging release.
5. Do not start private-image cutover in this test. The two existing hosted
   buckets are public; keep private-image migration and legacy-reference
   conversion as a separately reviewed rollout after its client/storage matrix
   passes.

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

## Current execution record

- Local minimal PostgreSQL: 48/48 pgTAP assertions passed; legacy profile
  transition and transactional rollback passed; direct authenticated invocation
  of the overloaded self-upgrade function was denied; free/premium concurrent
  reservations passed at 1/1 and 3/4 respectively.
- The review-only private-image policy SQL and 11/11 Storage-policy assertions
  also passed against a local Storage catalog/RLS stub made only for this test.
  It does not exercise Supabase Storage API, signed URL behavior, or object
  delivery/deletion services.
- Supabase Auth, PostgREST, Storage, Edge Runtime, Realtime delivery, and RevenueCat
  sandbox behavior remain untested. No staging project was provisioned and no
  production data or configuration was changed.
