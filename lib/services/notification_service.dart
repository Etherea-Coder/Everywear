import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './user_profile_helper.dart';

class NotificationService with UserProfileHelper {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  Future<bool> sendOutfitReminder({
    required String type,
    String? occasion,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final firstName = await getUserFirstName();

      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'type': type,
          'occasion': occasion,
          'firstName': firstName,
        },
      );

      return true;
    } catch (e) {
      debugPrint('NotificationService error: $e');
      return false;
    }
  }
}
