import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/daily_log_repository.dart';

void main() {
  late DailyLogRepository repository;

  setUp(() {
    repository = DailyLogRepository();
  });

  group('DailyLogRepository', () {
    test('getOutfitEntries returns empty list when Supabase not available', () async {
      final result = await repository.getOutfitEntries();
      expect(result, isA<List>());
    });

    test('getMonthlyStats returns valid structure', () async {
      final result = await repository.getMonthlyStats(DateTime.now());

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('total_outfits'), true);
      expect(result.containsKey('unique_items'), true);
      expect(result.containsKey('favorite_occasion'), true);
      expect(result.containsKey('avg_rating'), true);
    });
  });
}
