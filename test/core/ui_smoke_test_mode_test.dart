import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/ui_smoke_test_mode.dart';

void main() {
  test('smoke mode is opt-in and can be reset after the test flow', () {
    UiSmokeTestMode.setEnabledForDebugTest(false);
    expect(UiSmokeTestMode.isEnabled, isFalse);
    expect(UiSmokeTestMode.allowsAutomaticWeatherLocation, isTrue);

    UiSmokeTestMode.setEnabledForDebugTest(true);
    expect(UiSmokeTestMode.isEnabled, isTrue);
    expect(UiSmokeTestMode.allowsAutomaticWeatherLocation, isFalse);

    UiSmokeTestMode.setEnabledForDebugTest(false);
    expect(UiSmokeTestMode.isEnabled, isFalse);
    expect(UiSmokeTestMode.allowsAutomaticWeatherLocation, isTrue);
  });
}
