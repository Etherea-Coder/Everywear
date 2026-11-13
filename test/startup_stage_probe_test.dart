import 'package:everywear/startup_stage_probe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(StartupProbeState.instance.resetForTest);

  testWidgets('probe shell draws before loading application services', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupStageProbeApp());

    expect(find.text('EVERYWEAR STARTUP PROBE (STAGING)'), findsOneWidget);
    expect(find.text('Stage: Flutter first frame visible'), findsOneWidget);
    expect(
      find.text('Application initialization has not started.'),
      findsOneWidget,
    );
    expect(find.text('Run next stage'), findsOneWidget);
  });

  testWidgets('probe shell stays visible around the mounted app root', (
    tester,
  ) async {
    final state = StartupProbeState.instance;
    state.applicationStage = 'Loading saved app preferences';
    state.application = const MaterialApp(
      home: Scaffold(body: Text('Nested application root')),
    );

    await tester.pumpWidget(const StartupStageProbeApp());

    expect(find.text('EVERYWEAR STARTUP PROBE (STAGING)'), findsOneWidget);
    expect(find.text('Nested application root'), findsOneWidget);
    expect(
      find.text('Application stage: Loading saved app preferences'),
      findsOneWidget,
    );
  });

  test('observation reports a visible completion result', () async {
    final state = StartupProbeState.instance;
    state.applicationStage = 'Loading saved app preferences';

    await state.observeApplicationStartup(
      duration: const Duration(milliseconds: 10),
    );

    expect(state.observationComplete, isTrue);
    expect(state.observationSummary, contains('Observation finished'));
    expect(state.observationSummary, contains('Loading saved app preferences'));
  });

  test('failure details expose only a safe type and package location', () {
    final failure = sanitizedProbeFailure(
      'Supabase token=hidden',
      StateError('token=secret user=private'),
      StackTrace.fromString(
        '#0 initialize (package:everywear/services/startup.dart:17:4)\n'
        '#1 read /home/personal/private.json',
      ),
    );

    expect(
      failure,
      'Supabase tokenhidden: StateError at package:everywear/services/startup.dart:17:4',
    );
    expect(failure, isNot(contains('secret')));
    expect(failure, isNot(contains('private')));
    expect(failure, isNot(contains('/home')));
  });
}
