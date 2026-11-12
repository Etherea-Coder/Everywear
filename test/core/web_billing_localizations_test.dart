import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/utils/app_localizations.dart';

void main() {
  test(
    'hosted billing states are localized in every supported language',
    () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final strings = AppLocalizations(locale);
        await strings.load();

        expect(strings.hostedCheckoutTitle, isNot('hosted_checkout_title'));
        expect(
          strings.hostedCheckoutUnavailable,
          isNot('hosted_checkout_unavailable'),
        );
        expect(strings.continueToCheckout, isNot('continue_to_checkout'));
        expect(strings.hostedCheckoutOpened, isNot('hosted_checkout_opened'));
        expect(strings.manageSubscription, isNot('manage_subscription'));
        expect(
          strings.subscriptionManagementUnavailable,
          isNot('subscription_management_unavailable'),
        );
        expect(
          strings.subscriptionStatusVerified,
          isNot('subscription_status_verified'),
        );
        expect(
          strings.subscriptionNotVerified,
          isNot('subscription_not_verified'),
        );
        expect(
          strings.subscriptionStatusCouldNotRefresh,
          isNot('subscription_status_could_not_refresh'),
        );
      }
    },
  );
}
