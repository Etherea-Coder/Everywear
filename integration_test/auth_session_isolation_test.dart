import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:everywear/main.dart' as app;
import 'package:everywear/services/supabase_service.dart';
import 'support/foreground_round_trip_gate.dart';

const _foreground = MethodChannel('com.everywear/ui_smoke_test');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'isolated sign-in and local sign-out do not clear the normal app session',
    (tester) async {
      if (!const bool.fromEnvironment('EVERYWEAR_STAGING') ||
          const bool.fromEnvironment('EVERYWEAR_ADS_ENABLED') ||
          const String.fromEnvironment('APP_DISTRIBUTION') != 'uptodown' ||
          const String.fromEnvironment('REVENUECAT_BILLING_ENVIRONMENT') !=
              'unavailable' ||
          Uri.parse(SupabaseService.cleanSupabaseUrl).host !=
              'aftdbphdobfrshienple.supabase.co') {
        throw StateError(
          'Refusing auth isolation check outside staging safeguards.',
        );
      }

      app.main();
      await _waitForForeground(tester);
      await _waitFor(tester, find.text('AUTOMATED TEST APP  •  STAGING'));
      await _waitForPredicate(
        tester,
        () => SupabaseService.isInitialized,
        timeout: const Duration(seconds: 30),
      );

      final auth = SupabaseService.instance.client.auth;
      if (auth.currentUser == null) {
        // The auth-only test makes no user/profile/wardrobe writes. The owner
        // signs in privately in the isolated staging-test package.
        // ignore: avoid_print
        print(
          'SIGN_IN_REQUIRED: authenticate in Everywear UI Smoke Test (STAGING) '
          '(com.stylewise.app.stagingtest). This auth-only test remains alive; '
          'no app data will be written.',
        );
        final priorPointerPropagation =
            binding.shouldPropagateDevicePointerEvents;
        binding.shouldPropagateDevicePointerEvents = true;
        try {
          await _waitForPredicate(
            tester,
            () => auth.currentUser != null,
            timeout: const Duration(minutes: 15),
          );
        } finally {
          binding.shouldPropagateDevicePointerEvents = priorPointerPropagation;
        }
      }

      expect(auth.currentUser, isNotNull);
      // Let the owner inspect the normal app while the isolated sign-in is
      // active. The process remains alive and checks that the user returns to
      // this app before it performs the explicit local sign-out below.
      // ignore: avoid_print
      print(
        'NORMAL_SESSION_CHECK_REQUIRED_AFTER_TEST_SIGNIN: switch to normal '
        'Everywear, confirm it is still authenticated, then return to '
        'Everywear UI Smoke Test (STAGING). Reply with what you see before '
        'returning. Do not sign the normal app in if it shows sign-in.',
      );
      await _waitForNormalAppInspection(
        tester,
        binding,
        auth,
        expectedTestSession: true,
      );
      await _waitForOwnerConfirmation(
        tester,
        binding,
        title: 'Normal Everywear check',
        message:
            'The isolated test app is signed in. Confirm the normal app still '
            'shows your signed-in screen before allowing this test to continue.',
      );
      expect(auth.currentUser, isNotNull);

      await auth.signOut(scope: SignOutScope.local);
      await _waitForPredicate(
        tester,
        () => auth.currentUser == null,
        timeout: const Duration(seconds: 15),
      );
      expect(auth.currentUser, isNull);
      // ignore: avoid_print
      print(
        'TEST_APP_LOCAL_SIGNOUT_COMPLETE: event should be signedOut with '
        'session absent. Switch to normal Everywear, confirm it remains '
        'authenticated, reply with what you see, then return to the staging '
        'test app.',
      );
      await _waitForNormalAppInspection(
        tester,
        binding,
        auth,
        expectedTestSession: false,
      );
      await _waitForOwnerConfirmation(
        tester,
        binding,
        title: 'Local test sign-out check',
        message:
            'The isolated test app has signed out locally. Confirm the normal '
            'app still shows your signed-in screen before cleanup continues.',
      );
      expect(auth.currentUser, isNull);
      // ignore: avoid_print
      print('PASS: test app sign-in and explicit local sign-out completed');
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );
}

Future<void> _waitForOwnerConfirmation(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  required String title,
  required String message,
}) async {
  final priorPointerPropagation = binding.shouldPropagateDevicePointerEvents;
  binding.shouldPropagateDevicePointerEvents = true;
  var confirmed = false;
  try {
    final context = tester.element(find.byType(MaterialApp).first);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            key: const ValueKey('confirm_normal_session_checkpoint'),
            onPressed: () {
              confirmed = true;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('I checked — continue'),
          ),
        ],
      ),
    );
    await tester.pump();
    await _waitForPredicate(
      tester,
      () => confirmed,
      timeout: const Duration(minutes: 10),
    );
  } finally {
    binding.shouldPropagateDevicePointerEvents = priorPointerPropagation;
  }
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Staging test-app identity banner did not appear.');
}

Future<void> _waitForNormalAppInspection(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  GoTrueClient auth, {
  required bool expectedTestSession,
}) async {
  var leftTestApp = false;
  final deadline = DateTime.now().add(const Duration(minutes: 10));
  final priorPointerPropagation = binding.shouldPropagateDevicePointerEvents;
  final roundTrip = ForegroundRoundTripGate();
  binding.shouldPropagateDevicePointerEvents = true;
  try {
    while (DateTime.now().isBefore(deadline)) {
      final foreground =
          tester.binding.lifecycleState == AppLifecycleState.resumed &&
          await _foreground.invokeMethod<bool>('isForeground') == true;
      leftTestApp = leftTestApp || !foreground;
      final returnedAfterInspection = roundTrip.observe(
        testAppForeground: foreground,
        now: DateTime.now(),
      );
      final sessionMatches = (auth.currentUser != null) == expectedTestSession;
      if (leftTestApp && returnedAfterInspection && sessionMatches) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  } finally {
    binding.shouldPropagateDevicePointerEvents = priorPointerPropagation;
  }
  throw TestFailure(
    'Timed out waiting for normal-app inspection and return to the isolated app.',
  );
}

Future<void> _waitForForeground(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    if (tester.binding.lifecycleState == AppLifecycleState.resumed) {
      try {
        if (await _foreground.invokeMethod<bool>('isForeground') == true) {
          return;
        }
      } on MissingPluginException {
        throw StateError(
          'Auth isolation test stopped: native foreground probe is unavailable.',
        );
      }
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  throw TestFailure(
    'Auth isolation test stopped: isolated Everywear activity did not become foregrounded.',
  );
}

Future<void> _waitForPredicate(
  WidgetTester tester,
  FutureOr<bool> Function() predicate, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await predicate()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out waiting for isolated auth state.');
}
