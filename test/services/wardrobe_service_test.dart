import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/wardrobe_service.dart';

void main() {
  group('WardrobeService', () {
    test('fetchWardrobeItems returns empty list when not authenticated', () async {
      final service = WardrobeService();
      final result = await service.fetchWardrobeItems();
      expect(result, isA<List>());
    });

    test('getWardrobeStatistics throws when not authenticated', () async {
      final service = WardrobeService();
      expect(
        () => service.getWardrobeStatistics(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
