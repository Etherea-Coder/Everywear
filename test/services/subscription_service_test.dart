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

  group('hosted subscription verification', () {
    test(
      'requires the same signed-in account and successful backend result',
      () {
        expect(
          SubscriptionService.acceptsBackendVerification(
            expectedUserId: 'user-a',
            currentUserId: 'user-a',
            responseStatus: 200,
            responseBody: const {'success': true},
          ),
          isTrue,
        );
        expect(
          SubscriptionService.acceptsBackendVerification(
            expectedUserId: 'user-a',
            currentUserId: 'user-b',
            responseStatus: 200,
            responseBody: const {'success': true},
          ),
          isFalse,
        );
        expect(
          SubscriptionService.acceptsBackendVerification(
            expectedUserId: 'user-a',
            currentUserId: 'user-a',
            responseStatus: 402,
            responseBody: const {'success': false},
          ),
          isFalse,
        );
      },
    );
  });
}
