# Email confirmation readiness

## Staging diagnosis

Target: `Everywear-staging` (`aftdbphdobfrshienple`) only.

The signup request previously called `auth.signUp` without `emailRedirectTo`.
Supabase's confirmation template's `{{ .ConfirmationURL }}` points to the
Auth verification endpoint and includes its final redirect URL. When
`emailRedirectTo` is omitted, Auth falls back to its configured Site URL. The
reported `localhost:3000` destination therefore most likely comes from the
staging Site URL; a custom confirmation template could also introduce it. The exact Site
URL and template have not been read: the public `/auth/v1/settings` response
does not expose them, and the read-only Management API request to
`GET /v1/projects/aftdbphdobfrshienple/config/auth` returned HTTP 401.
Consequently `localhost:3000` as the Site URL is the likely cause from the
link observed by the owner, not a confirmed value from project metadata.

The local app now explicitly sends
`io.supabase.everywear://login-callback` as the signup `emailRedirectTo`. The
same constant is used for Google OAuth and password recovery. Supabase Flutter
session URI detection is explicitly enabled. The installed `supabase_flutter`
2.18.3 implementation listens to the AppLinks stream and calls
`auth.getSessionFromUrl(uri)` for callback links containing an auth code or
tokens. The `AuthGate` then shows onboarding when
`onboarding_completed` is false, otherwise home. Android's installed package
resolver maps the callback URI to `com.stylewise.app/.MainActivity`.

Local regression tests verify that signup sends the redirect in the Auth
request, callback detection is enabled, and the URI matches the Android intent
filter. They passed. This does not prove hosted allowlist/template settings or
an actual email confirmation callback.

Before sending a fresh confirmation email, inspect and then set staging only:

1. Set the Auth Site URL fallback to `io.supabase.everywear://login-callback`
   for this app-only staging project, replacing any localhost value.
2. Add the exact `io.supabase.everywear://login-callback` URI to the Auth
   redirect allowlist. Supabase documents mobile deep-link URLs as valid Site
   URLs and requires `redirectTo` to match the allowlist: [redirect URL guide](https://supabase.com/docs/guides/auth/redirect-urls).
3. Inspect the confirmation email template. The verification link should use
   `{{ .ConfirmationURL }}` so the user visits Supabase's verification endpoint
   before returning to the app. Do not replace it with a raw `{{ .SiteURL }}`
   link unless it correctly constructs the Auth verification URL and token
   parameters. Keep email confirmation enabled. See the
   [email template variables](https://supabase.com/docs/guides/auth/auth-email-templates).
4. Confirm the project's email delivery configuration can deliver the new
   message. Supabase's default SMTP is limited to pre-authorized team addresses
   and currently has a 2 emails/hour limit; use a team-owned test inbox for
   staging or configure a staging SMTP service. Do not infer SMTP readiness
   from the setting that enables email signup. See the
   [custom SMTP guide](https://supabase.com/docs/guides/auth/auth-smtp).
5. Rebuild/install the staging APK containing explicit `emailRedirectTo`,
   create a fresh synthetic account with an accessible test inbox, open the
   new email on the phone, verify the link returns to Everywear, and confirm
   the app reaches onboarding or home. Do not use an existing confirmation
   email generated before these changes.

The Management API read was blocked by HTTP 401. To let this agent inspect and
configure staging, provide an existing token locally (never in chat) with
`auth_config_read` and `auth_config_write` on the staging project, or make the
same settings change in the staging Dashboard and report when it is complete.
The Supabase CLI project list being authenticated does not grant or expose this
Management API token. No staging auth configuration has yet been changed. The
API scopes are described in the [Auth configuration read reference](https://supabase.com/docs/reference/api/v1-get-auth-service-config)
and [Auth configuration update reference](https://supabase.com/docs/reference/api/v1-update-auth-service-config).

## Production-branded confirmation email requirements

Production remains untouched and is not ready for email-delivery claims. Before
launch:

- Configure a production custom SMTP provider and test delivery, bounce, and
  rate-limit behavior.
- Verify the production sender domain with the provider. Publish its required
  SPF and DKIM records and align DMARC policy before sending branded mail.
- Replace the generic confirmation template with approved Everywear branding,
  support details, and a working `{{ .ConfirmationURL }}` action link. Test
  rendering and links in real mail clients.
- Set the production Auth Site URL to an owner-controlled production fallback
  (the actual URL still needs owner approval). Add the app callback
  `io.supabase.everywear://login-callback` to the production redirect allowlist
  and keep signup's explicit callback pointed there. Test the production
  fallback and app callback independently before enabling public signup.
- Reconcile these settings against the exact production Supabase project and
  release APK configuration. No production provider, URL, template, or email
  was changed or tested during this recovery.
