import 'package:everywear/startup_stage_probe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  testWidgets('app stage updates during child build do not invalidate parent', (
    tester,
  ) async {
    final state = StartupProbeState.instance;
    var notifiedDuringBuild = false;
    state.addListener(() {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        notifiedDuringBuild = true;
      }
    });
    state.application = const _AppStageUpdateOnBuild();

    await tester.pumpWidget(const StartupStageProbeApp());
    expect(tester.takeException(), isNull);
    expect(notifiedDuringBuild, isFalse);

    await tester.pump();
    expect(
      find.text('Application stage: Waiting for core services'),
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
        '#0 report (package:flutter/src/widgets/framework.dart:100:5)\n'
        '#0 initialize (package:everywear/services/startup.dart:17:4)\n'
        '#1 build (package:everywear/presentation/auth_gate.dart:44:10)\n'
        '#1 read /home/personal/private.json',
      ),
    );

    expect(failure, contains('StateError'));
    expect(
      failure,
      contains(
        'package:everywear/services/startup.dart:17:4 <- '
        'package:everywear/presentation/auth_gate.dart:44:10',
      ),
    );
    expect(failure, isNot(contains('secret')));
    expect(failure, isNot(contains('private')));
    expect(failure, isNot(contains('/home')));
  });

  test('assertion diagnostics keep allowlisted source coordinates only', () {
    final failure = sanitizedProbeFailure(
      'Widget build',
      _FakeAssertionError(),
      null,
    );

    expect(
      failure,
      'Widget build: _FakeAssertionError at '
      'package:everywear/screens/home_screen.dart:47:8',
    );
    expect(failure, isNot(contains('secret')));
    expect(failure, isNot(contains('private')));
  });
}

class _AppStageUpdateOnBuild extends StatelessWidget {
  const _AppStageUpdateOnBuild();

  @override
  Widget build(BuildContext context) {
    StartupProbeState.instance.updateApplicationDiagnostics(
      'Waiting for core services',
      const [],
    );
    return const Text('App root building');
  }
}

class _FakeAssertionError implements AssertionError {
  @override
  StackTrace? get stackTrace => null;

  @override
  Object? get message => 'secret private assertion message';

  @override
  String toString() =>
      "'package:everywear/screens/home_screen.dart': Failed assertion: "
      "line 47 pos 8: 'secret expression': private user data";
}
