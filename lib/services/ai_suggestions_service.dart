import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import '../services/user_tier_service.dart';

class AiSuggestionsService {
  SupabaseClient get _supabase => SupabaseService.instance.client;
  final UserTierService _tierService = UserTierService();

  /// Generates AI styling suggestions for an outfit image
  ///
  /// Parameters:
  /// - [imageUrl]: URL of the outfit image to analyze
  /// - [language]: Language code for suggestions ('EN', 'FR', or 'ES')
  ///
  /// Returns a map containing:
  /// - 'success': boolean indicating if the operation succeeded
  /// - 'suggestions': string with AI-generated styling tips
  /// - 'error': error message if operation failed
  Future<Map<String, dynamic>> generateSuggestions({
    required String imageUrl,
    required String language,
    Map<String, dynamic>? weatherContext,
    List<Map<String, dynamic>>? itemHistory,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Check suggestion limit before making API call
      final canRequest = await _tierService.canRequestSuggestion(user.id);
      if (!canRequest) {
        final tierInfo = await _tierService.getUserTierInfo(user.id);
        final tier = tierInfo['tier'] as String;
        final limit = tierInfo['suggestions_limit'] as int;

        return {
          'success': false,
          'error':
              'Monthly suggestion limit reached. You have used all $limit suggestions for your $tier tier. '
              'Upgrade to premium for more suggestions.',
        };
      }

      final response = await _supabase.functions.invoke(
        'ai-suggestions',
        body: {
          'imageUrl': imageUrl,
          'language': language,
          'weather': weatherContext,
          'itemsInfo': itemHistory,
        },
      );

      if (response.data != null) {
        return {
          'success': response.data['success'] ?? false,
          'suggestions': response.data['suggestions'] ?? '',
          'error': response.data['error'],
        };
      }

      return {'success': false, 'error': 'No response from AI service'};
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to connect to AI service: ${e.toString()}',
      };
    }
  }
}
