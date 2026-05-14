import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './user_profile_helper.dart';

class StyleService with UserProfileHelper {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  Future<Map<String, dynamic>> getStyleRecommendations({
    required String occasion,
    required String language,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final firstName = await getUserFirstName();

      final response = await _supabase.functions.invoke(
        'style-recommendations',
        body: {
          'occasion': occasion,
          'language': language,
          'firstName': firstName,
        },
      );

      if (response.data != null) {
        return {
          'success': response.data['success'] ?? false,
          'recommendations': response.data['recommendations'] ?? [],
          'error': response.data['error'],
        };
      }

      return {'success': false, 'error': 'No response from style service'};
    } catch (e) {
      debugPrint('StyleService error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
