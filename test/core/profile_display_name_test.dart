import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/utils/profile_display_name.dart';

void main() {
  group('normalizeProfileName', () {
    test('trims a provided name', () {
      expect(normalizeProfileName('  Ada Lovelace  '), 'Ada Lovelace');
    });

    test('ignores empty or whitespace-only values', () {
      expect(normalizeProfileName(null), isNull);
      expect(normalizeProfileName('   '), isNull);
    });
  });

  group('resolveProfileDisplayName', () {
    test('prefers a non-empty authentication name', () {
      expect(
        resolveProfileDisplayName(
          authMetadataName: '  Ada Lovelace  ',
          profileName: 'Ada Byron',
          email: 'ada@example.invalid',
        ),
        'Ada Lovelace',
      );
    });

    test('uses the profile name when legacy auth metadata is absent', () {
      expect(
        resolveProfileDisplayName(
          profileName: 'Ada Lovelace',
          email: 'ada@example.invalid',
        ),
        'Ada Lovelace',
      );
    });

    test('falls back to email only when no name is available', () {
      expect(
        resolveProfileDisplayName(
          authMetadataName: ' ',
          profileName: null,
          email: ' ada@example.invalid ',
        ),
        'ada@example.invalid',
      );
    });
  });
}
