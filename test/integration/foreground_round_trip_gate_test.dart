import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/foreground_round_trip_gate.dart';

void main() {
  test('ignores brief focus loss and requires sustained leave then return', () {
    final gate = ForegroundRoundTripGate(
      minimumAway: const Duration(seconds: 2),
    );
    final start = DateTime(2026, 11, 16, 12);

    expect(gate.observe(testAppForeground: true, now: start), isFalse);
    expect(
      gate.observe(
        testAppForeground: false,
        now: start.add(const Duration(milliseconds: 250)),
      ),
      isFalse,
    );
    expect(
      gate.observe(
        testAppForeground: true,
        now: start.add(const Duration(seconds: 1)),
      ),
      isFalse,
      reason: 'A brief focus change must not satisfy the normal-app check.',
    );
    expect(
      gate.observe(
        testAppForeground: false,
        now: start.add(const Duration(seconds: 2)),
      ),
      isFalse,
    );
    expect(
      gate.observe(
        testAppForeground: false,
        now: start.add(const Duration(seconds: 4)),
      ),
      isFalse,
    );
    expect(
      gate.observe(
        testAppForeground: true,
        now: start.add(const Duration(seconds: 4, milliseconds: 250)),
      ),
      isTrue,
    );
  });
}
