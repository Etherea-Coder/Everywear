import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/ai_allowance_service.dart';

void main() {
  test('parses server allowance snapshots and UTC reset timestamps', () {
    final value = AiAllowanceSnapshot.tryParse({
      'month_remaining': 7,
      'month_limit': 20,
      'day_remaining': 2,
      'burst_remaining': 1,
      'month_resets_at': '2030-03-01T00:00:00Z',
    });

    expect(value?.monthRemaining, 7);
    expect(value?.monthLimit, 20);
    expect(value?.dayRemaining, 2);
    expect(value?.burstRemaining, 1);
    expect(value?.canRequest, isTrue);
    expect(value?.monthResetsAt?.isUtc, isTrue);
  });

  test('fails closed on malformed server allowance data', () {
    expect(AiAllowanceSnapshot.tryParse({'month_remaining': '20'}), isNull);
    expect(
      AiAllowanceSnapshot.tryParse({
        'month_remaining': 0,
        'month_limit': 20,
        'day_remaining': 0,
        'burst_remaining': 0,
      })?.canRequest,
      isFalse,
    );
    expect(AiAllowanceSnapshot.tryParse(null), isNull);
  });
}
