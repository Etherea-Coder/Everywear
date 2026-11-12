import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/ai_request_id.dart';

void main() {
  test('generates distinct UUID v4 request identifiers', () {
    final first = newAiRequestId();
    final second = newAiRequestId();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    expect(uuidV4.hasMatch(first), isTrue);
    expect(uuidV4.hasMatch(second), isTrue);
    expect(first, isNot(second));
  });
}
