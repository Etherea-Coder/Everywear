import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/revenuecat_web_checkout.dart';
import 'package:everywear/services/subscription_service.dart';

const userA = '9f2f8050-41d6-4c55-a707-64d5a06714a3';
const userB = '7a8e03ab-ecdf-4420-8c40-6535b46a4388';

RevenueCatWebCheckoutConfig config({
  AppDistribution distribution = AppDistribution.uptodown,
  BillingEnvironment environment = BillingEnvironment.production,
  String productionLink = 'https://pay.rev.cat/AbCd1234',
  String sandboxLink = 'https://pay.rev.cat/Test1234',
  bool isReleaseBuild = true,
}) => RevenueCatWebCheckoutConfig(
  distribution: distribution,
  environment: environment,
  productionLink: productionLink,
  sandboxLink: sandboxLink,
  isReleaseBuild: isReleaseBuild,
);

void main() {
  group('RevenueCat hosted checkout routing', () {
    test(
      'uses the selected production link and authenticated Supabase UUID',
      () {
        final uri = config().checkoutUriFor(userA);

        expect(uri?.origin, 'https://pay.rev.cat');
        expect(uri?.pathSegments, ['AbCd1234', userA]);
      },
    );

    test('requires sandbox in debug and production in release', () {
      expect(config().isAvailable, isTrue);
      expect(
        config(environment: BillingEnvironment.sandbox).isAvailable,
        isFalse,
      );
      expect(
        config(
          environment: BillingEnvironment.sandbox,
          isReleaseBuild: false,
        ).checkoutUriFor(userA)?.pathSegments,
        ['Test1234', userA],
      );
      expect(config(isReleaseBuild: false).checkoutUriFor(userA), isNull);
    });

    test(
      'keeps checkout unavailable for unsupported distribution or config',
      () {
        expect(
          config(
            distribution: AppDistribution.googlePlay,
          ).checkoutUriFor(userA),
          isNull,
        );
        expect(config(productionLink: '').checkoutUriFor(userA), isNull);
        expect(config().checkoutUriFor('not-a-user-id'), isNull);
      },
    );

    test(
      'rejects lookalike, credentialed, parameterized and malformed links',
      () {
        for (final value in [
          'https://pay.rev.cat.attacker.example/AbCd1234',
          'https://attacker.example/pay.rev.cat/AbCd1234',
          'http://pay.rev.cat/AbCd1234',
          'https://user@pay.rev.cat/AbCd1234',
          'https://pay.rev.cat/AbCd1234/other',
          'https://pay.rev.cat/AbCd1234?redirect=https://attacker.example',
        ]) {
          expect(
            config(productionLink: value).checkoutUriFor(userA),
            isNull,
            reason: value,
          );
        }
      },
    );

    test('does not treat browser cancellation as checkout success', () async {
      final checkout = RevenueCatWebCheckout(
        config: config(),
        launch: (_) async => false,
      );

      expect(await checkout.openForUser(userA), isFalse);
      expect(checkout.takePendingUserId(userA), isNull);
    });

    test(
      'app resume after checkout still requires backend verification',
      () async {
        final checkout = RevenueCatWebCheckout(
          config: config(),
          launch: (_) async => true,
        );
        expect(await checkout.openForUser(userA), isTrue);

        // Returning from the browser (including Cancel/Back) only consumes the
        // matching account marker. A negative verifier response grants nothing.
        expect(checkout.takePendingUserId(userA), userA);
        expect(
          SubscriptionService.acceptsBackendVerification(
            expectedUserId: userA,
            currentUserId: userA,
            responseStatus: 402,
            responseBody: const {'error': 'Required entitlement is not active'},
          ),
          isFalse,
        );
      },
    );

    test('consumes pending return only for the same account', () async {
      final checkout = RevenueCatWebCheckout(
        config: config(),
        launch: (_) async => true,
      );
      expect(await checkout.openForUser(userA), isTrue);
      expect(checkout.takePendingUserId(userB), isNull);
      expect(checkout.takePendingUserId(userA), isNull);
    });

    test('matches only the registered callback and current App User ID', () {
      expect(
        RevenueCatWebCheckout.isBillingReturnFor(
          Uri.parse(
            'io.supabase.everywear://billing-return?app_user_id=$userA',
          ),
          userA,
        ),
        isTrue,
      );
      expect(
        RevenueCatWebCheckout.isBillingReturnFor(
          Uri.parse(
            'io.supabase.everywear://billing-return?app_user_id=$userB',
          ),
          userA,
        ),
        isFalse,
      );
      expect(
        RevenueCatWebCheckout.isBillingReturnFor(
          Uri.parse(
            'io.supabase.everywear://billing-return?app_user_id=$userA&redirect=x',
          ),
          userA,
        ),
        isFalse,
      );
      expect(
        RevenueCatWebCheckout.isBillingReturnFor(
          Uri.parse('io.supabase.everywear://other?app_user_id=$userA'),
          userA,
        ),
        isFalse,
      );
    });

    test('does not accept a return callback as entitlement verification', () {
      expect(
        SubscriptionService.acceptsBackendVerification(
          expectedUserId: userA,
          currentUserId: userA,
          responseStatus: 402,
          responseBody: const {'success': false},
        ),
        isFalse,
      );
      expect(
        SubscriptionService.acceptsBackendVerification(
          expectedUserId: userA,
          currentUserId: userB,
          responseStatus: 200,
          responseBody: const {'success': true},
        ),
        isFalse,
      );
      expect(
        SubscriptionService.acceptsBackendVerification(
          expectedUserId: userA,
          currentUserId: userA,
          responseStatus: 200,
          responseBody: const {'success': true},
        ),
        isTrue,
      );
    });

    test('accepts management URLs only from RevenueCat Billing hosts', () {
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'https://api.revenuecat.com/rcbilling/v1/customerportal/sub_123/portal',
        ),
        isNotNull,
      );
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'https://billing.revenuecat.com/app/subscription?token=single-use',
        ),
        isNotNull,
      );
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'https://play.google.com/store/account/subscriptions?sku=product&package=com.stylewise.app',
        ),
        isNotNull,
      );
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'https://apps.apple.com/account/subscriptions',
        ),
        isNotNull,
      );
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'https://billing.revenuecat.com.evil.example/app/subscription',
        ),
        isNull,
      );
      expect(
        RevenueCatWebCheckout.validatedManagementUri(
          'http://billing.revenuecat.com/app/subscription',
        ),
        isNull,
      );
    });
  });
}
