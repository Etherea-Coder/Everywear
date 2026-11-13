import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Keep the full application library deferred so the probe can paint a Flutter
// frame before importing its providers, services, and application routes.
import 'main.dart' deferred as app;

void main() {
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) => StartupProbeState.instance.record(
        'Flutter framework',
        details.exception,
        details.stack,
      );
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        StartupProbeState.instance.record('Platform error', error, stackTrace);
        return true;
      };
      ErrorWidget.builder = (details) {
        StartupProbeState.instance.record(
          'Widget build',
          details.exception,
          details.stack,
        );
        return const _ProbeErrorCard();
      };

      // Binding setup and runApp share this zone. The visible shell is the first
      // Flutter widget tree and does not depend on the deferred app library.
      runApp(const StartupStageProbeApp());
    },
    (error, stackTrace) {
      StartupProbeState.instance.record(
        'Uncaught asynchronous error',
        error,
        stackTrace,
      );
    },
  );
}

@visibleForTesting
String sanitizedProbeFailure(
  String stage,
  Object error,
  StackTrace? stackTrace,
) {
  final safeStage = stage.replaceAll(RegExp(r'[^A-Za-z0-9 /_-]'), '').trim();
  final type = error.runtimeType.toString().replaceAll(
    RegExp(r'[^A-Za-z0-9_]'),
    '',
  );
  final location = stackTrace == null
      ? null
      : RegExp(
          r'(?:package:[A-Za-z0-9_./-]+\.dart|dart:[A-Za-z0-9_./-]+):\d+:\d+',
        ).firstMatch(stackTrace.toString())?.group(0);
  final label = safeStage.isEmpty
      ? 'Startup'
      : safeStage.substring(0, safeStage.length.clamp(0, 48));
  return '$label: ${type.isEmpty ? 'UnknownError' : type}'
      '${location == null ? '' : ' at $location'}';
}

class StartupProbeState extends ChangeNotifier {
  StartupProbeState._();

  static final instance = StartupProbeState._();

  static const stages = <String>[
    'Load application library',
    'Initialize reporting',
    'Initialize staging backend',
    'Initialize local storage',
    'Construct provider and app root widgets',
    'Mount root and draw its first frame',
    'Observe application startup for 30 seconds',
  ];

  final failures = <String>[];
  int stageIndex = -1;
  bool busy = false;
  Widget? application;
  Widget? pendingApplication;
  String? applicationStage;

  String get stage =>
      stageIndex < 0 ? 'Flutter first frame visible' : stages[stageIndex];

  void record(String stage, Object error, [StackTrace? stackTrace]) {
    final failure = sanitizedProbeFailure(stage, error, stackTrace);
    if (!failures.contains(failure)) {
      failures.add(failure);
      if (failures.length > 8) failures.removeAt(0);
      notifyListeners();
    }
  }

  Future<void> runNextStage() async {
    if (busy || stageIndex + 1 >= stages.length) return;
    busy = true;
    stageIndex += 1;
    notifyListeners();
    try {
      switch (stageIndex) {
        case 0:
          await app.loadLibrary().timeout(const Duration(seconds: 30));
          app.startupDiagnosticsForProbe.addListener(_syncAppFailures);
          _syncAppFailures();
        case 1:
          await app.initializeReportingForStartupProbe().timeout(
            const Duration(seconds: 30),
          );
        case 2:
          await app.initializeSupabaseForStartupProbe().timeout(
            const Duration(seconds: 30),
          );
        case 3:
          await app.initializeLocalStorageForStartupProbe().timeout(
            const Duration(seconds: 30),
          );
        case 4:
          pendingApplication = app.createApplicationForStartupProbe();
        case 5:
          application = pendingApplication;
          notifyListeners();
          await WidgetsBinding.instance.endOfFrame.timeout(
            const Duration(seconds: 30),
          );
        case 6:
          await Future<void>.delayed(const Duration(seconds: 30));
          _syncAppFailures();
      }
    } catch (error, stackTrace) {
      record(stages[stageIndex], error, stackTrace);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _syncAppFailures() {
    applicationStage = app.startupDiagnosticsForProbe.value.stage;
    for (final failure in app.startupFailuresForProbe) {
      if (!failures.contains(failure)) {
        failures.add(failure);
        if (failures.length > 8) failures.removeAt(0);
      }
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    stageIndex = -1;
    busy = false;
    application = null;
    pendingApplication = null;
    applicationStage = null;
    failures.clear();
    notifyListeners();
  }
}

class StartupStageProbeApp extends StatelessWidget {
  const StartupStageProbeApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StartupProbeState.instance,
    builder: (context, _) {
      final state = StartupProbeState.instance;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFFE36A32)),
        home: Scaffold(
          backgroundColor: const Color(0xFFF3F6FA),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFE36A32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: const Text(
                    'EVERYWEAR STARTUP PROBE (STAGING)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Stage: ${state.stage}',
                    key: const Key('probe-stage'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton(
                    onPressed:
                        state.busy ||
                            state.stageIndex + 1 >=
                                StartupProbeState.stages.length
                        ? null
                        : state.runNextStage,
                    child: Text(
                      state.busy ? 'Stage running…' : 'Run next stage',
                    ),
                  ),
                ),
                if (state.applicationStage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text('Application stage: ${state.applicationStage}'),
                  ),
                if (state.failures.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Text(
                      state.failures.join('\n'),
                      key: const Key('probe-errors'),
                      style: const TextStyle(color: Color(0xFF9D2A1E)),
                    ),
                  ),
                Expanded(
                  child:
                      state.application ??
                      const Center(
                        child: Text(
                          'Application initialization has not started.',
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProbeErrorCard extends StatelessWidget {
  const _ProbeErrorCard();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text('A widget failed. See the sanitized startup probe details.'),
  );
}
