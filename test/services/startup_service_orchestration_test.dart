import 'dart:async';

import 'package:everywear/services/startup_service_orchestration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'slow optional reporting does not delay core startup services',
    () async {
      final reporting = Completer<void>();
      var supabaseInitialized = false;
      var localStorageInitialized = false;

      await initializeCoreStartupServices(
        initializeReporting: () => reporting.future,
        initializeSupabase: () async => supabaseInitialized = true,
        initializeLocalStorage: () async => localStorageInitialized = true,
      );

      expect(supabaseInitialized, isTrue);
      expect(localStorageInitialized, isTrue);
      expect(reporting.isCompleted, isFalse);

      reporting.complete();
    },
  );

  test('reporting errors do not fail core startup services', () async {
    var supabaseInitialized = false;
    var localStorageInitialized = false;

    await initializeCoreStartupServices(
      initializeReporting: () async => throw TimeoutException('preference'),
      initializeSupabase: () async => supabaseInitialized = true,
      initializeLocalStorage: () async => localStorageInitialized = true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(supabaseInitialized, isTrue);
    expect(localStorageInitialized, isTrue);
  });
}
