import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/ai_intelligence_service.dart';

void main() {
  late AIIntelligenceService service;

  setUp(() {
    service = AIIntelligenceService();
  });

  group('_computeInsights', () {
    test('returns default insights when wardrobe and logs are empty', () {
      final result = service.computeInsights([], []);

      expect(result['confidenceScore'], 0);
      expect(result['styleProfile'], 'Undetermined');
      expect((result['dominantColors'] as List).isEmpty, true);
      expect((result['colorPercentages'] as List).isEmpty, true);
      expect((result['versatilityScores'] as List).isEmpty, true);
      expect((result['underutilizedItems'] as List).isEmpty, true);
    });

    test('assigns Uncategorized when category key is null', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': null, 'color': null},
      ];

      final result = service.computeInsights(wardrobe, []);

      expect(result['confidenceScore'], 0);
      expect(result['styleProfile'], 'Eclectic Mix');
      expect((result['dominantColors'] as List), contains('Unknown'));
    });

    test('assigns Unknown when color key is null', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'color': null},
      ];

      final result = service.computeInsights(wardrobe, []);

      expect((result['dominantColors'] as List), contains('Unknown'));
    });

    test('computes confidence score from outfit logs', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'color': 'Blue'},
      ];
      final logs = List.generate(
        5,
        (_) => <String, dynamic>{'outfit_items': []},
      );

      final result = service.computeInsights(wardrobe, logs);

      expect(result['confidenceScore'], 50);
    });

    test('clamps confidence score to max 100', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'color': 'Blue'},
      ];
      final logs = List.generate(
        15,
        (_) => <String, dynamic>{'outfit_items': []},
      );

      final result = service.computeInsights(wardrobe, logs);

      expect(result['confidenceScore'], 100);
    });

    test('derives style profile from dominant category', () {
      final wardrobe = [
        {'id': '1', 'name': 'Dress', 'category': 'Dresses', 'color': 'Red'},
      ];

      final result = service.computeInsights(wardrobe, []);

      expect(result['styleProfile'], 'Elegant Classic');
    });

    test('derives Sporty Chic for Activewear category', () {
      final wardrobe = [
        {'id': '1', 'name': 'Leggings', 'category': 'Activewear', 'color': 'Black'},
      ];

      final result = service.computeInsights(wardrobe, []);

      expect(result['styleProfile'], 'Sporty Chic');
      expect((result['emergingStyles'] as List), contains('Athleisure'));
    });

    test('computes versatility scores with default Unknown Item for null name', () {
      final wardrobe = [
        {'id': '1', 'name': null, 'category': 'Tops', 'color': 'Blue'},
      ];

      final result = service.computeInsights(wardrobe, []);

      final scores = result['versatilityScores'] as List;
      expect(scores.first['item'], 'Unknown Item');
    });

    test('computes sustainability metrics with zero wears', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'purchase_price': 50.0},
      ];

      final result = service.computeInsights(wardrobe, []);

      final metrics = result['sustainabilityMetrics'] as Map<String, dynamic>;
      expect(metrics['avgCostPerWear'], 0.0);
    });

    test('computes sustainability metrics with wears', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'purchase_price': 100.0},
      ];
      final logs = List.generate(
        4,
        (_) => <String, dynamic>{'outfit_items': []},
      );

      final result = service.computeInsights(wardrobe, logs);

      final metrics = result['sustainabilityMetrics'] as Map<String, dynamic>;
      expect(metrics['avgCostPerWear'], 25.0);
    });

    test('generates gap recommendation for missing categories', () {
      final wardrobe = [
        {'id': '1', 'name': 'Shirt', 'category': 'Tops', 'color': 'Blue'},
      ];

      final result = service.computeInsights(wardrobe, []);

      final recs = result['recommendations'] as List;
      final gapRec = recs.firstWhere((r) => (r as Map)['type'] == 'gap');
      expect(gapRec['title'], contains('Bottoms'));
    });

    test('generates silhouette evolution with 3 months', () {
      final result = service.computeInsights([], []);

      final silhouettes = result['silhouetteEvolution'] as List;
      expect(silhouettes.length, 3);
    });

    test('color percentages sum to approximately 100', () {
      final wardrobe = [
        {'id': '1', 'category': 'Tops', 'color': 'Blue'},
        {'id': '2', 'category': 'Tops', 'color': 'Blue'},
        {'id': '3', 'category': 'Tops', 'color': 'Black'},
      ];

      final result = service.computeInsights(wardrobe, []);

      final percentages = (result['colorPercentages'] as List).cast<int>();
      final sum = percentages.fold(0, (a, b) => a + b);
      expect(sum, 100);
    });
  });

  group('getDefaultInsights', () {
    test('never stores null values', () {
      final result = service.getDefaultInsights();

      for (final entry in result.entries) {
        expect(entry.value, isNotNull,
            reason: 'Key "${entry.key}" should not be null');
      }
    });

    test('returns empty collections not null', () {
      final result = service.getDefaultInsights();

      expect(result['dominantColors'], isA<List>());
      expect(result['colorPercentages'], isA<List>());
      expect(result['versatilityScores'], isA<List>());
      expect(result['underutilizedItems'], isA<List>());
      expect(result['recommendations'], isA<List>());
    });

    test('sustainability metrics has no null values', () {
      final result = service.getDefaultInsights();
      final metrics = result['sustainabilityMetrics'] as Map<String, dynamic>;

      for (final entry in metrics.entries) {
        expect(entry.value, isNotNull,
            reason: 'sustainabilityMetrics["${entry.key}"] should not be null');
      }
    });
  });
}
