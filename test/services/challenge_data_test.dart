import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/challenge_data.dart';

void main() {
  group('mergeChallengeData', () {
    test('uses the actual style_challenges relation for joined history', () {
      final result = mergeChallengeData(
        history: [
          {
            'id': 'user-challenge-1',
            'challenge_id': 'challenge-1',
            'progress': 3,
            'completed_at': null,
            'insight': null,
            'anchor_item_id': 'wardrobe-1',
            'style_challenges': {
              'id': 'challenge-1',
              'title': 'Wear a new color',
              'type': 'color_outfit',
            },
          },
        ],
      );

      expect(result, hasLength(1));
      expect(result.single['title'], 'Wear a new color');
      expect(result.single['is_joined'], isTrue);
      expect(result.single['progress'], 3);
      expect(result.single['user_challenge_id'], 'user-challenge-1');
      expect(result.single['anchor_item_id'], 'wardrobe-1');
    });

    test('does not duplicate the current challenge from history', () {
      final result = mergeChallengeData(
        current: {'id': 'challenge-1', 'title': 'Current'},
        history: [
          {
            'challenge_id': 'challenge-1',
            'style_challenges': {'id': 'challenge-1', 'title': 'History'},
          },
        ],
      );

      expect(result, hasLength(1));
      expect(result.single['title'], 'Current');
    });

    test('skips history rows with a missing relationship safely', () {
      final result = mergeChallengeData(
        history: [
          {'challenge_id': 'missing-relation', 'style_challenges': null},
        ],
      );

      expect(result, isEmpty);
    });
  });
}
