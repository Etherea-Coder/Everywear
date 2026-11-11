import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/user_tier_service.dart';

void main() {
  group('UserTierService', () {
    late UserTierService service;

    setUp(() {
      service = UserTierService();
    });

    test('getUserTierInfo fails closed on backend error', () async {
      final result = await service.getUserTierInfo('nonexistent-user-id');

      expect(result['tier'], 'free');
      expect(result['suggestions_limit'], 1);
      expect(result['suggestions_remaining'], 0);
      expect(result['coaching_remaining'], 0);
      expect(result['outfit_logs_remaining'], 0);
      expect(result['error'], true);
    });

    test('isPremium returns false when not authenticated', () async {
      final result = await service.isPremium();
      expect(result, false);
    });

    test('upgradeToPremium returns false for invalid user', () async {
      final result = await service.upgradeToPremium('nonexistent-user-id');
      expect(result, false);
    });

    test('canRequestSuggestion fails closed when backend is unavailable', () async {
      final result = await service.canRequestSuggestion('nonexistent-user-id');
      expect(result, false);
      expect(service.lastCheckError, isNotNull);
    });
  });
}
