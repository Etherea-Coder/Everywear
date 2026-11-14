import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/ui_smoke_test_mode.dart';

void main() {
  test('smoke mode is opt-in and can be reset after the test flow', () {
    UiSmokeTestMode.setEnabledForDebugTest(false);
    expect(UiSmokeTestMode.isEnabled, isFalse);

    UiSmokeTestMode.setEnabledForDebugTest(true);
    expect(UiSmokeTestMode.isEnabled, isTrue);

    UiSmokeTestMode.setEnabledForDebugTest(false);
    expect(UiSmokeTestMode.isEnabled, isFalse);
  });
}
