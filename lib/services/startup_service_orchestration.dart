import 'dart:async';

/// Starts optional reporting without holding up the services needed by the UI.
Future<void> initializeCoreStartupServices({
  required Future<void> Function() initializeReporting,
  required Future<void> Function() initializeSupabase,
  required Future<void> Function() initializeLocalStorage,
}) async {
  unawaited(initializeReporting().catchError((Object _) {}));
  await initializeSupabase();
  await initializeLocalStorage();
}
