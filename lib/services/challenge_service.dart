import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Handles all challenge-related Supabase operations.
/// Follows the same pattern as [WardrobeService] — no state, pure async methods.
class ChallengeService {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ── READ ─────────────────────────────────────────────────────────────────

  /// Returns the current week's challenge (based on ISO week number mod 4)
  /// merged with the user's participation row if it exists.
  Future<Map<String, dynamic>?> fetchCurrentChallenge() async {
    try {
      final uid = _userId;
      if (uid == null) return null;

      // Pick which week slot to show (1-4 rotation)
      final weekSlot = (DateTime.now().weekOfYear % 4) + 1;

      final challenges = await _client
          .from('challenges')
          .select()
          .eq('week_number', weekSlot)
          .limit(1);

      if (challenges.isEmpty) return null;
      final challenge = Map<String, dynamic>.from(challenges.first);

      // Try to find an active user_challenge for this challenge
      final userRows = await _client
          .from('user_challenges')
          .select()
          .eq('user_id', uid)
          .eq('challenge_id', challenge['id'] as String)
          .limit(1);

      if (userRows.isNotEmpty) {
        final uc = userRows.first;
        challenge['is_joined'] = true;
        challenge['progress'] = uc['progress'] ?? 0;
        challenge['completed_at'] = uc['completed_at'];
        challenge['insight'] = uc['insight'];
        challenge['user_challenge_id'] = uc['id'];
        challenge['anchor_item_id'] = uc['anchor_item_id'];
      } else {
        challenge['is_joined'] = false;
        challenge['progress'] = 0;
        challenge['completed_at'] = null;
        challenge['insight'] = null;
        challenge['user_challenge_id'] = null;
        challenge['anchor_item_id'] = null;
      }

      return challenge;
    } catch (e) {
      debugPrint('ChallengeService.fetchCurrentChallenge error: $e');
      return null;
    }
  }

  /// Returns all challenges the user has ever joined (for history/insights).
  Future<List<Map<String, dynamic>>> fetchUserChallengeHistory() async {
    try {
      final uid = _userId;
      if (uid == null) return [];

      final rows = await _client
          .from('user_challenges')
          .select('*, challenges(*)')
          .eq('user_id', uid)
          .order('started_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('ChallengeService.fetchUserChallengeHistory error: $e');
      return [];
    }
  }

  // ── JOIN ─────────────────────────────────────────────────────────────────

  /// Joins a challenge. For anchor_piece type, [anchorItemId] is required.
  Future<bool> joinChallenge(
    String challengeId, {
    String? anchorItemId,
  }) async {
    try {
      final uid = _userId;
      if (uid == null) return false;

      await _client.from('user_challenges').upsert({
        'user_id': uid,
        'challenge_id': challengeId,
        'progress': 0,
        'started_at': DateTime.now().toIso8601String(),
        'anchor_item_id': anchorItemId,
      });
      return true;
    } catch (e) {
      debugPrint('ChallengeService.joinChallenge error: $e');
      return false;
    }
  }

  // ── PROGRESS ─────────────────────────────────────────────────────────────

  /// Increments progress by 1 for [userChallengeId].
  /// Marks as completed and generates an insight when goal is reached.
  Future<Map<String, dynamic>> incrementProgress({
    required String userChallengeId,
    required int currentProgress,
    required int goal,
    required String challengeType,
    String? anchorItemName,
  }) async {
    try {
      final newProgress = currentProgress + 1;
      final isComplete = newProgress >= goal;

      final updatePayload = <String, dynamic>{
        'progress': newProgress,
      };

      if (isComplete) {
        updatePayload['completed_at'] = DateTime.now().toIso8601String();
        updatePayload['insight'] = _generateInsight(
          challengeType: challengeType,
          anchorItemName: anchorItemName,
        );
      }

      await _client
          .from('user_challenges')
          .update(updatePayload)
          .eq('id', userChallengeId);

      return {
        'progress': newProgress,
        'is_complete': isComplete,
        'insight': updatePayload['insight'],
      };
    } catch (e) {
      debugPrint('ChallengeService.incrementProgress error: $e');
      return {'progress': currentProgress, 'is_complete': false};
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  String _generateInsight({
    required String challengeType,
    String? anchorItemName,
  }) {
    switch (challengeType) {
      case 'anchor_piece':
        final item = anchorItemName ?? 'that piece';
        return 'Style insight unlocked — $item proved incredibly versatile. '
            'You built 3 distinct outfits around it. '
            'It\'s one of your most flexible wardrobe pieces.';
      case 'rediscover':
        return 'Wardrobe discovery — you gave a forgotten piece a second life. '
            'Try revisiting your wardrobe every 30 days to keep your style feeling fresh.';
      case 'color_outfit':
        return 'Color insight — you\'re comfortable building tonal outfits. '
            'Monochromatic dressing is one of the easiest ways to look put-together.';
      case 'capsule':
        return 'Capsule insight — you created 5 outfits from just 7 items. '
            'This is the core skill of a truly efficient wardrobe.';
      default:
        return 'Challenge complete — great work experimenting with your style this week.';
    }
  }

  /// Returns the wardrobe item that was unworn the longest (for rediscover hint).
  Future<Map<String, dynamic>?> fetchLongestUnwornItem() async {
    try {
      final uid = _userId;
      if (uid == null) return null;

      // Items with last_worn set — pick the oldest
      final withDate = await _client
          .from('wardrobe_items')
          .select('id, name, image_url, last_worn')
          .eq('user_id', uid)
          .not('last_worn', 'is', null)
          .order('last_worn', ascending: true)
          .limit(1);

      if (withDate.isNotEmpty) return withDate.first;

      // Fallback: item with no last_worn date at all
      final withoutDate = await _client
          .from('wardrobe_items')
          .select('id, name, image_url, last_worn')
          .eq('user_id', uid)
          .isFilter('last_worn', null)
          .limit(1);

      if (withoutDate.isNotEmpty) {
        return Map<String, dynamic>.from(withoutDate.first);
      }

      return null;
    } catch (e) {
      debugPrint('ChallengeService.fetchLongestUnwornItem error: $e');
      return null;
    }
  }
}

// ── Extension ────────────────────────────────────────────────────────────────

extension _DateTimeWeek on DateTime {
  /// ISO 8601 week-of-year (1-53).
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final dayOfYear = difference(startOfYear).inDays;
    return ((dayOfYear + startOfYear.weekday - 1) / 7).ceil();
  }
}