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
  String? operationStarted;
  Duration operationElapsed = Duration.zero;
  bool observationComplete = false;
  String? observationSummary;
  bool _appLibraryLoaded = false;
  Timer? _operationTimer;
  DateTime? _operationStartedAt;

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
    _startOperationTimer();
    notifyListeners();
    try {
      switch (stageIndex) {
        case 0:
          await app.loadLibrary().timeout(const Duration(seconds: 30));
          _appLibraryLoaded = true;
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
          _startOperationTimer(label: 'Mounting ProviderScope and MyApp');
          application = pendingApplication;
          notifyListeners();
          await WidgetsBinding.instance.endOfFrame.timeout(
            const Duration(seconds: 30),
          );
          stageIndex = 6;
          _startOperationTimer(label: 'Observing application startup');
          observationComplete = false;
          observationSummary = null;
          notifyListeners();
          await observeApplicationStartup();
      }
    } catch (error, stackTrace) {
      record(stages[stageIndex], error, stackTrace);
    } finally {
      _stopOperationTimer();
      busy = false;
      notifyListeners();
    }
  }

  Future<void> observeApplicationStartup({
    Duration duration = const Duration(seconds: 30),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < duration) {
      final remaining = duration - DateTime.now().difference(start);
      await Future<void>.delayed(
        remaining < const Duration(seconds: 1)
            ? remaining
            : const Duration(seconds: 1),
      );
      operationElapsed = DateTime.now().difference(start);
      if (_appLibraryLoaded) _syncAppFailures();
      notifyListeners();
    }
    if (_appLibraryLoaded) _syncAppFailures();
    observationComplete = true;
    final internalStage = applicationStage ?? 'no app stage reported';
    observationSummary = failures.isEmpty
        ? 'Observation finished; no sanitized errors were reported. '
              'Latest app stage: $internalStage.'
        : 'Observation finished with ${failures.length} sanitized error(s). '
              'Latest app stage: $internalStage.';
    notifyListeners();
  }

  void _startOperationTimer({String? label}) {
    _operationStartedAt = DateTime.now();
    operationStarted = label ?? stages[stageIndex];
    operationElapsed = Duration.zero;
    _operationTimer?.cancel();
    _operationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _operationStartedAt;
      if (startedAt == null) return;
      operationElapsed = DateTime.now().difference(startedAt);
      notifyListeners();
    });
  }

  void _stopOperationTimer() {
    _operationTimer?.cancel();
    _operationTimer = null;
    operationStarted = null;
    _operationStartedAt = null;
  }

  void _syncAppFailures() {
    final stage = app.startupDiagnosticsForProbe.value.stage;
    // The library's default value predates mounting MyApp and is not progress.
    if (stage != 'Starting Flutter') applicationStage = stage;
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
    operationStarted = null;
    operationElapsed = Duration.zero;
    observationComplete = false;
    observationSummary = null;
    _appLibraryLoaded = false;
    _stopOperationTimer();
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
                if (state.operationStarted != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      '${state.operationStarted}: '
                      '${state.operationElapsed.inSeconds}s',
                      key: const Key('probe-progress'),
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
                if (state.observationSummary != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      state.observationSummary!,
                      key: const Key('probe-observation-result'),
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
