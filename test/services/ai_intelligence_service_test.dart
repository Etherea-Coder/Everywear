import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/ai_intelligence_service.dart';

void main() {
  group('AIIntelligenceService', () {
    test('exposes one shared instance', () {
      expect(
        identical(AIIntelligenceService.instance, AIIntelligenceService.instance),
        isTrue,
      );
    });

    test('cache can be cleared before authentication', () {
      expect(AIIntelligenceService.instance.clearCache, returnsNormally);
    });
  });
}
