import 'package:flutter/foundation.dart';

/// Runtime guard used only by the debug integration test for staging smoke
/// flows. Normal launches leave it disabled; release builds cannot enable it.
class UiSmokeTestMode {
  UiSmokeTestMode._();

  static bool _enabled = false;

  static bool get isEnabled => kDebugMode && _enabled;

  @visibleForTesting
  static void setEnabledForDebugTest(bool enabled) {
    if (enabled && !kDebugMode) {
      throw StateError('UI smoke mode can only be enabled in a debug build.');
    }
    _enabled = enabled;
  }
}
