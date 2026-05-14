import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/user_tier_service.dart';

void main() {
  group('UserTierService', () {
    late UserTierService service;

    setUp(() {
      service = UserTierService();
    });

    test('canAddItem returns true when Supabase unavailable (fail open)', () async {
      final result = await service.canAddItem('nonexistent-user-id');
      expect(result, true);
    });

    test('getUserTierInfo returns default free tier on error', () async {
      final result = await service.getUserTierInfo('nonexistent-user-id');

      expect(result['tier'], 'free');
      expect(result['items_limit'], 30);
      expect(result['suggestions_limit'], 10);
      expect(result['items_remaining'], 30);
      expect(result['suggestions_remaining'], 10);
    });

    test('isPremium returns false when not authenticated', () async {
      final result = await service.isPremium();
      expect(result, false);
    });

    test('upgradeToPremium returns false for invalid user', () async {
      final result = await service.upgradeToPremium('nonexistent-user-id');
      expect(result, false);
    });

    test('canRequestSuggestion returns true when Supabase unavailable (fail open)', () async {
      final result = await service.canRequestSuggestion('nonexistent-user-id');
      expect(result, true);
    });
  });
}
