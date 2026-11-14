import 'package:supabase_flutter/supabase_flutter.dart';

/// Mobile deep link Supabase Auth should use after email confirmation,
/// password recovery, or hosted OAuth.
const appAuthCallbackUri = 'io.supabase.everywear://login-callback';

/// Keep Supabase Flutter's AppLinks observer enabled so confirmation codes
/// returned to [appAuthCallbackUri] are exchanged for a persisted session.
const everywearAuthClientOptions = FlutterAuthClientOptions(
  detectSessionInUri: true,
);

/// Signs up with an explicit mobile callback so Auth never falls back to its
/// Site URL (which may be a web-development URL such as localhost).
Future<AuthResponse> signUpWithEmailRedirect({
  required GoTrueClient auth,
  required String email,
  required String password,
}) {
  return auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: appAuthCallbackUri,
  );
}
