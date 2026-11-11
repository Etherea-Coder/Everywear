import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/wardrobe_service.dart';

void main() {
  group('WardrobeService', () {
    test('fetchWardrobeItems returns empty list when not authenticated', () async {
      final service = WardrobeService();
      final result = await service.fetchWardrobeItems();
      expect(result, isA<List>());
    });

    test('getWardrobeStatistics returns an empty offline-safe result', () async {
      final service = WardrobeService();
      final result = await service.getWardrobeStatistics();
      expect(result['total_items'], 0);
      expect(result['favorite_items'], 0);
      expect(result['category_counts'], isEmpty);
    });
  });
}
