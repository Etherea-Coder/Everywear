import 'dart:convert';
import 'dart:io';

import 'package:everywear/services/auth_redirects.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Auth observes mobile callback links', () {
    expect(everywearAuthClientOptions.detectSessionInUri, isTrue);
  });

  test(
    'email signup sends the Android confirmation redirect to Auth',
    () async {
      http.Request? capturedRequest;
      final client = GoTrueClient(
        url: 'https://staging.example.test/auth/v1',
        autoRefreshToken: false,
        flowType: AuthFlowType.implicit,
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'id': '00000000-0000-4000-8000-000000000001',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'staging@example.invalid',
              'app_metadata': {
                'provider': 'email',
                'providers': ['email'],
              },
              'user_metadata': {},
              'created_at': '2026-01-01T00:00:00.000Z',
              'identities': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      await signUpWithEmailRedirect(
        auth: client,
        email: 'staging@example.invalid',
        password: 'test-only-password',
        fullName: 'Staging Tester',
      );

      expect(capturedRequest?.url.path, '/auth/v1/signup');
      expect(
        capturedRequest?.url.queryParameters['redirect_to'],
        appAuthCallbackUri,
      );
      final requestBody =
          jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(
        (requestBody['data'] as Map<String, dynamic>)['full_name'],
        'Staging Tester',
      );
    },
  );

  test('mobile auth callback matches the Android intent filter', () {
    final uri = Uri.parse(appAuthCallbackUri);
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(uri.scheme, 'io.supabase.everywear');
    expect(uri.host, 'login-callback');
    expect(manifest, contains('android:scheme="${uri.scheme}"'));
    expect(manifest, contains('android:host="${uri.host}"'));
  });
}
