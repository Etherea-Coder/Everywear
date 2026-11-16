import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/owner_session_checkpoint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.everywear/ui_smoke_test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'asks native UI for the sign-in checkpoint and returns confirmation',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return true;
          });

      final confirmed = await requestOwnerSessionCheckpoint(
        channel,
        checkpoint: 'after_test_sign_in',
      );

      expect(confirmed, isTrue);
      expect(received?.method, 'confirmOwnerSessionCheckpoint');
      expect(received?.arguments, {'checkpoint': 'after_test_sign_in'});
    },
  );

  test('does not treat a rejected native checkpoint as confirmation', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);

    expect(
      await requestOwnerSessionCheckpoint(
        channel,
        checkpoint: 'after_test_local_sign_out',
      ),
      isFalse,
    );
  });
}
