import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/revenuecat_service.dart';

void main() {
  group('RevenueCat build configuration', () {
    test('free beta disables purchases even with complete provider config', () {
      expect(
        RevenueCatService.canConfigurePurchases(
          freeBeta: true,
          supportedPlatform: true,
          apiKey: 'public-sdk-key',
          requiredEntitlementId: 'premium',
        ),
        isFalse,
      );
    });

    test('normal mobile builds still require an API key and entitlement', () {
      expect(
        RevenueCatService.canConfigurePurchases(
          freeBeta: false,
          supportedPlatform: true,
          apiKey: 'public-sdk-key',
          requiredEntitlementId: 'premium',
        ),
        isTrue,
      );
      expect(
        RevenueCatService.canConfigurePurchases(
          freeBeta: false,
          supportedPlatform: true,
          apiKey: '',
          requiredEntitlementId: 'premium',
        ),
        isFalse,
      );
      expect(
        RevenueCatService.canConfigurePurchases(
          freeBeta: false,
          supportedPlatform: true,
          apiKey: 'public-sdk-key',
          requiredEntitlementId: '',
        ),
        isFalse,
      );
      expect(
        RevenueCatService.canConfigurePurchases(
          freeBeta: false,
          supportedPlatform: false,
          apiKey: 'public-sdk-key',
          requiredEntitlementId: 'premium',
        ),
        isFalse,
      );
    });
  });
}
