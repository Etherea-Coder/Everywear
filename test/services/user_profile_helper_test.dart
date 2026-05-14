import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/user_profile_helper.dart';
import 'package:everywear/services/notification_service.dart';
import 'package:everywear/services/style_service.dart';
import 'package:everywear/services/today_suggestion_service.dart';
import 'package:everywear/services/ai_suggestions_service.dart';

void main() {
  group('UserProfileHelper mixin', () {
    test('is mixed into AiSuggestionsService', () {
      final service = AiSuggestionsService();
      expect(service, isA<UserProfileHelper>());
    });

    test('is mixed into TodaySuggestionService', () {
      final service = TodaySuggestionService();
      expect(service, isA<UserProfileHelper>());
    });

    test('is mixed into StyleService', () {
      final service = StyleService();
      expect(service, isA<UserProfileHelper>());
    });

    test('is mixed into NotificationService', () {
      final service = NotificationService();
      expect(service, isA<UserProfileHelper>());
    });

    test('getUserFirstName returns empty string when Supabase not initialized', () async {
      final service = AiSuggestionsService();
      final result = await service.getUserFirstName();
      expect(result, '');
    });

    test('getUserFullName returns empty string when Supabase not initialized', () async {
      final service = AiSuggestionsService();
      final result = await service.getUserFullName();
      expect(result, '');
    });
  });
}
