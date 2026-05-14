import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './user_profile_helper.dart';
import './user_tier_service.dart';

class TodaySuggestionService with UserProfileHelper {
  SupabaseClient get _supabase => SupabaseService.instance.client;
  final UserTierService _tierService = UserTierService();

  Future<Map<String, dynamic>> getDailySuggestion({
    required String language,
    Map<String, dynamic>? weatherContext,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final canRequest = await _tierService.canRequestSuggestion(user.id);
      if (!canRequest) {
        return {
          'success': false,
          'error': 'Monthly suggestion limit reached',
        };
      }

      final firstName = await getUserFirstName();

      final response = await _supabase.functions.invoke(
        'today-suggestion',
        body: {
          'language': language,
          'weather': weatherContext,
          'firstName': firstName,
        },
      );

      if (response.data != null) {
        return {
          'success': response.data['success'] ?? false,
          'suggestion': response.data['suggestion'] ?? '',
          'error': response.data['error'],
        };
      }

      return {'success': false, 'error': 'No response from suggestion service'};
    } catch (e) {
      debugPrint('TodaySuggestionService error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
