import 'package:flutter/material.dart';

const startupDiagnosticsEnabled = bool.fromEnvironment(
  'EVERYWEAR_STARTUP_DIAGNOSTICS',
  defaultValue: false,
);

@immutable
class StartupDiagnosticState {
  const StartupDiagnosticState({
    this.stage = 'Starting Flutter',
    this.failures = const [],
  });

  final String stage;
  final List<String> failures;

  StartupDiagnosticState withStage(String next) =>
      StartupDiagnosticState(stage: next, failures: failures);

  StartupDiagnosticState withFailure(String failure) => StartupDiagnosticState(
    stage: stage,
    failures: List.unmodifiable([...failures, failure].take(6)),
  );
}

class StartupDiagnostics {
  StartupDiagnostics._();

  static final ValueNotifier<StartupDiagnosticState> state = ValueNotifier(
    const StartupDiagnosticState(),
  );

  static void setStage(String stage) {
    state.value = state.value.withStage(_safeLabel(stage));
  }

  static void recordFailure(String stage, Object error) {
    final type = error.runtimeType.toString().replaceAll(
      RegExp(r'[^A-Za-z0-9_]'),
      '',
    );
    state.value = state.value.withFailure(
      '${_safeLabel(stage)}: ${type.isEmpty ? 'UnknownError' : type}',
    );
  }

  static void recordUnavailable(String stage) {
    state.value = state.value.withFailure(
      '${_safeLabel(stage)}: ServiceUnavailable',
    );
  }

  static String _safeLabel(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9 /_-]'), '').trim();
    return safe.length <= 48 ? safe : safe.substring(0, 48);
  }
}

class StartupDiagnosticScreen extends StatelessWidget {
  const StartupDiagnosticScreen({
    super.key,
    this.timedOut = false,
    this.startupFailed = false,
    this.timeoutDuration = const Duration(seconds: 30),
  });

  final bool timedOut;
  final bool startupFailed;
  final Duration timeoutDuration;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: StartupDiagnostics.state,
    builder: (context, diagnostic, _) => Scaffold(
      backgroundColor: const Color(0xFF17212B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DiagnosticBadge(),
                  const SizedBox(height: 28),
                  const Icon(
                    Icons.bug_report_outlined,
                    color: Color(0xFFFFC857),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    timedOut
                        ? 'Startup timed out'
                        : startupFailed
                        ? 'Startup failed'
                        : 'Flutter UI is running',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    timedOut
                        ? 'Initialization did not finish in time. The stage below shows where startup stopped.'
                        : startupFailed
                        ? 'Initialization stopped with a sanitized error. No raw exception or configuration is shown.'
                        : 'This diagnostic screen is visible only after Flutter has drawn its first frame.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _DiagnosticDetails(
                    state: diagnostic,
                    timedOut: timedOut,
                    timeoutDuration: timeoutDuration,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class StartupDiagnosticBanner extends StatelessWidget {
  const StartupDiagnosticBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: StartupDiagnostics.state,
    builder: (context, state, _) => Column(
      children: [
        Material(
          color: const Color(0xFFB54708),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'STARTUP DIAGNOSTIC BUILD • ${state.stage}'
                  '${state.failures.isEmpty ? '' : ' • ${state.failures.last}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _DiagnosticDetails extends StatelessWidget {
  const _DiagnosticDetails({
    required this.state,
    required this.timedOut,
    required this.timeoutDuration,
  });

  final StartupDiagnosticState state;
  final bool timedOut;
  final Duration timeoutDuration;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF243442),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF526575)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current stage: ${state.stage}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        if (timedOut) ...[
          const SizedBox(height: 8),
          Text(
            'Startup exceeded ${timeoutDuration.inSeconds} '
            '${timeoutDuration.inSeconds == 1 ? 'second' : 'seconds'}.',
            style: const TextStyle(color: Color(0xFFFFC857)),
          ),
        ],
        if (state.failures.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Sanitized initialization failures:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final failure in state.failures)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $failure',
                style: const TextStyle(color: Color(0xFFFFD8A8)),
              ),
            ),
        ],
      ],
    ),
  );
}

class _DiagnosticBadge extends StatelessWidget {
  const _DiagnosticBadge();

  @override
  Widget build(BuildContext context) => Align(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFB54708),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'EVERYWEAR • STAGING DIAGNOSTIC',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
    ),
  );
}
