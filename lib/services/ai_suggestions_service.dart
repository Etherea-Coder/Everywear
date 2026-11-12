import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_request_id.dart';
import './ai_image_payload.dart';
import './supabase_service.dart';
import './style_service.dart';

class AiSuggestionsService {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  /// Generates AI styling suggestions for an outfit image
  ///
  /// Parameters:
  /// - [imageFile]: image selected or captured by this device
  /// - [language]: Language code for suggestions ('EN', 'FR', or 'ES')
  ///
  /// Returns a map containing:
  /// - 'success': boolean indicating if the operation succeeded
  /// - 'suggestions': string with AI-generated styling tips
  /// - 'error': error message if operation failed
  Future<Map<String, dynamic>> generateSuggestions({
    required XFile imageFile,
    required String language,
    Map<String, dynamic>? weatherContext,
    List<Map<String, dynamic>>? itemHistory,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (await imageFile.length() > maxAiSourceImageBytes) {
        return {
          'success': false,
          'error': 'Image is too large for AI suggestions',
        };
      }

      final compressedImage = await FlutterImageCompress.compressWithList(
        await imageFile.readAsBytes(),
        minWidth: 1280,
        minHeight: 1280,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      final imageBase64 = encodeAiImageBase64(compressedImage);
      if (imageBase64 == null) {
        return {
          'success': false,
          'error': 'Image is too large or unavailable for AI suggestions',
        };
      }

      final userName = _getUserFirstName(user);

      // Fetch quiz result to inject style profile if available
      Map<String, dynamic>? profile;
      try {
        final quizResult = await StyleService().fetchQuizResult();
        if (quizResult != null) {
          profile = {
            'styleProfile': quizResult['style_profile'],
            'preferredColors': quizResult['preferred_colors']?.toString(),
            'styleGoals': quizResult['style_goals']?.toString(),
            'styleIntention': quizResult['style_intention']?.toString(),
          };
        }
      } catch (e) {
        // Ignore failure, we'll just not send profile data
      }

      final response = await _supabase.functions.invoke(
        'ai-suggestions',
        body: {
          'requestId': newAiRequestId(),
          'imageBase64': imageBase64,
          'language': language,
          'userName': userName,
          'userProfile': profile,
          'weather': weatherContext,
          'itemsInfo': itemHistory,
        },
      );

      if (response.data != null) {
        final success = response.data['success'] ?? false;
        return {
          'success': success,
          'suggestions': response.data['suggestions'] ?? '',
          'error': response.data['error'],
          'errorCode': response.data['code'],
        };
      }

      return {'success': false, 'error': 'No response from AI service'};
    } catch (e) {
      return {
        'success': false,
        'errorCode': RegExp(r'AI_[A-Z_]+').firstMatch(e.toString())?.group(0),
        'error': 'Failed to prepare or generate AI suggestions',
      };
    }
  }

  String? _getUserFirstName(User? user) {
    if (user == null) return null;
    final fullName =
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String?;
    if (fullName == null || fullName.trim().isEmpty) return null;
    return fullName.trim().split(' ').first;
  }
}
