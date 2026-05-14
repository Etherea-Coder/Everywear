import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

/// Service for managing user tier limits and usage tracking
/// Handles item limits (30 free/100 premium) and suggestion limits
class UserTierService {
  SupabaseClient get _supabase => SupabaseService.instance.client;

  /// Check if user can add more items to wardrobe based on tier
  /// Returns true if user hasn't reached their tier limit
  Future<bool> canAddItem(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('tier, items_count, items_limit')
          .eq('id', userId)
          .single();

      final itemsCount = response['items_count'] as int? ?? 0;
      final itemsLimit = response['items_limit'] as int? ?? 30;

      return itemsCount < itemsLimit;
    } catch (e) {
      debugPrint('canAddItem check failed: $e');
      return false;
    }
  }

  /// Check if user can request AI suggestions based on monthly limit
  /// Returns true if user hasn't exceeded their monthly suggestion limit
  Future<bool> canRequestSuggestion(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('monthly_suggestions_used, suggestions_limit')
          .eq('id', userId)
          .single();

      final suggestionsUsed = response['monthly_suggestions_used'] as int? ?? 0;
      final suggestionsLimit = response['suggestions_limit'] as int? ?? 10;

      return suggestionsUsed < suggestionsLimit;
    } catch (e) {
      debugPrint('canRequestSuggestion check failed: $e');
      return false;
    }
  }

  /// Get user's current tier information
  /// Returns map with tier details including limits and usage
  Future<Map<String, dynamic>> getUserTierInfo(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select(
            'tier, items_count, items_limit, monthly_suggestions_used, suggestions_limit',
          )
          .eq('id', userId)
          .single();

      return {
        'tier': response['tier'] ?? 'free',
        'items_count': response['items_count'] ?? 0,
        'items_limit': response['items_limit'] ?? 30,
        'monthly_suggestions_used': response['monthly_suggestions_used'] ?? 0,
        'suggestions_limit': response['suggestions_limit'] ?? 10,
        'items_remaining':
            (response['items_limit'] ?? 30) - (response['items_count'] ?? 0),
        'suggestions_remaining':
            (response['suggestions_limit'] ?? 10) -
            (response['monthly_suggestions_used'] ?? 0),
      };
    } catch (e) {
      // Return default free tier if error
      return {
        'tier': 'free',
        'items_count': 0,
        'items_limit': 30,
        'monthly_suggestions_used': 0,
        'suggestions_limit': 10,
        'items_remaining': 30,
        'suggestions_remaining': 10,
      };
    }
  }

  /// Upgrade user to premium tier
  /// Sets items_limit to 100 and suggestions_limit to higher value
  Future<bool> upgradeToPremium(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != userId) {
        throw Exception('Only the authenticated user can request tier changes');
      }

      final result = await _supabase
          .rpc('upgrade_user_to_premium', params: {'user_uuid': userId});

      if (result == null) {
        throw Exception('RPC call returned null');
      }

      return true;
    } catch (e) {
      debugPrint('upgradeToPremium failed: $e');
      return false;
    }
  }

  /// Check if current user is premium
  /// Returns true if user has premium tier
  Future<bool> isPremium() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('tier')
          .eq('id', user.id)
          .single();

      return response['tier'] == 'premium';
    } catch (e) {
      return false;
    }
  }
}
