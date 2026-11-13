import 'dart:async';

import 'package:everywear/main.dart';
import 'package:everywear/widgets/startup_diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    StartupDiagnostics.state.value = const StartupDiagnosticState();
  });

  testWidgets('shows diagnostic identity and sanitized initialization errors', (
    tester,
  ) async {
    StartupDiagnostics.setStage('Connecting to staging backend');
    StartupDiagnostics.recordFailure(
      'Backend initialization',
      StateError('token=private-value user=personal-data'),
    );

    await tester.pumpWidget(
      const MaterialApp(home: StartupDiagnosticScreen(startupFailed: true)),
    );

    expect(find.text('EVERYWEAR • STAGING DIAGNOSTIC'), findsOneWidget);
    expect(find.text('Startup failed'), findsOneWidget);
    expect(
      find.textContaining('Backend initialization: StateError'),
      findsOneWidget,
    );
    expect(find.textContaining('private-value'), findsNothing);
    expect(find.textContaining('personal-data'), findsNothing);
  });

  testWidgets('shows a visible timeout state when bootstrap never finishes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MyApp(
          startupServices: Completer<void>().future,
          diagnosticMode: true,
          startupTimeout: const Duration(seconds: 1),
        ),
      ),
    );

    expect(find.text('Flutter UI is running'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Startup timed out'), findsOneWidget);
    expect(find.textContaining('Startup exceeded 1 second.'), findsOneWidget);
    expect(find.textContaining('TimeoutException'), findsOneWidget);
  });
}
