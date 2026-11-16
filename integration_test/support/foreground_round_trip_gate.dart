/// Requires a sustained loss of foreground before accepting a return.
///
/// Short focus changes, such as an on-screen keyboard transition, must not be
/// mistaken for leaving the test app to inspect the normal app.
class ForegroundRoundTripGate {
  ForegroundRoundTripGate({this.minimumAway = const Duration(seconds: 2)});

  final Duration minimumAway;
  DateTime? _awaySince;
  bool _leftForLongEnough = false;

  bool observe({required bool testAppForeground, required DateTime now}) {
    if (testAppForeground) {
      if (_leftForLongEnough) return true;
      _awaySince = null;
      return false;
    }

    _awaySince ??= now;
    if (now.difference(_awaySince!) >= minimumAway) {
      _leftForLongEnough = true;
    }
    return false;
  }
}
