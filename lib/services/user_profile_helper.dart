import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

mixin UserProfileHelper {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  Future<String> getUserFirstName() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return '';

      final fullName = user.userMetadata?['full_name'] as String? ?? '';
      if (fullName.isEmpty) return '';

      return fullName.split(' ').first;
    } catch (_) {
      return '';
    }
  }

  Future<String> getUserFullName() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return '';
      return user.userMetadata?['full_name'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
