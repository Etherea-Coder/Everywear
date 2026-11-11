import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/user_profile_helper.dart';

class _ProfileHelperHost with UserProfileHelper {}

void main() {
  group('UserProfileHelper', () {
    test('returns empty first name when Supabase is unavailable', () async {
      expect(await _ProfileHelperHost().getUserFirstName(), '');
    });

    test('returns empty full name when Supabase is unavailable', () async {
      expect(await _ProfileHelperHost().getUserFullName(), '');
    });
  });
}
