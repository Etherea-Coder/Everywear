import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/subscription_service.dart';

void main() {
  group('subscription verification result', () {
    bool accepted({
      String expected = 'user-a',
      String? current = 'user-a',
      String? store = 'user-a',
      int status = 200,
      dynamic body = const {'success': true},
    }) => SubscriptionService.acceptsVerifiedResult(
      expectedUserId: expected,
      currentUserId: current,
      revenueCatUserId: store,
      responseStatus: status,
      responseBody: body,
    );

    test('accepts only the current authenticated store identity', () {
      expect(accepted(), isTrue);
      expect(accepted(current: 'user-b'), isFalse);
      expect(accepted(store: 'user-b'), isFalse);
    });

    test('requires successful backend verification response', () {
      expect(accepted(status: 402), isFalse);
      expect(accepted(body: const {'success': false}), isFalse);
      expect(accepted(body: const {}), isFalse);
      expect(accepted(body: 'success'), isFalse);
    });
  });
}
