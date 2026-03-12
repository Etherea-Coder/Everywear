import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StyleService {
  SupabaseClient get _client => SupabaseService.instance.client;

  // ── EVENTS ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchUpcomingEvents() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client
          .from('style_events')
          .select()
          .eq('user_id', userId)
          .gte('event_date', DateTime.now().toIso8601String().split('T')[0])
          .order('event_date', ascending: true)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addEvent({
    required String title,
    required DateTime eventDate,
    required String eventType,
    String? dressCode,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client.from('style_events').insert({
        'user_id': userId,
        'title': title,
        'event_date': eventDate.toIso8601String().split('T')[0],
        'event_type': eventType,
        'dress_code': dressCode,
        'notes': notes,
      }).select().single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error adding event: $e');
      return null;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _client.from('style_events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // ── CHALLENGES ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchChallenges() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final challenges = await _client
          .from('style_challenges')
          .select()
          .eq('is_active', true);
      final userChallenges = await _client
          .from('user_challenges')
          .select()
          .eq('user_id', userId);
      final joinedIds = (userChallenges as List)
          .map((uc) => uc['challenge_id'] as String)
          .toSet();
      return (challenges as List).map((c) {
        final uc = (userChallenges as List).firstWhere(
          (uc) => uc['challenge_id'] == c['id'],
          orElse: () => {},
        );
        return {
          ...Map<String, dynamic>.from(c),
          'is_joined': joinedIds.contains(c['id']),
          'progress': uc['progress'] ?? 0,
          'completed_at': uc['completed_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching challenges: $e');
      return [];
    }
  }

  Future<bool> joinChallenge(String challengeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      await _client.from('user_challenges').insert({
        'user_id': userId,
        'challenge_id': challengeId,
        'progress': 0,
      });
      return true;
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      return false;
    }
  }

  // ── INSIGHTS ────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchStyleInsights() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return _emptyInsights();

      // Fetch wardrobe items for color/category analysis
      final items = await _client
          .from('wardrobe_items')
          .select('category, notes')
          .eq('user_id', userId);

      final itemsList = List<Map<String, dynamic>>.from(items);
      if (itemsList.isEmpty) return _emptyInsights();

      // Category distribution
      final Map<String, int> categoryCount = {};
      for (final item in itemsList) {
        final cat = item['category'] as String? ?? 'Other';
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }

      final topCategory = categoryCount.isEmpty ? 'None' :
          categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Outfit logs for wear patterns
      final logs = await _client
          .from('outfit_logs')
          .select('occasion')
          .eq('user_id', userId)
          .limit(50);

      final logsList = List<Map<String, dynamic>>.from(logs);
      final Map<String, int> occasionCount = {};
      for (final log in logsList) {
        final occ = log['occasion'] as String? ?? 'Other';
        occasionCount[occ] = (occasionCount[occ] ?? 0) + 1;
      }
      final topOccasion = occasionCount.isEmpty ? 'Casual' :
          occasionCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return {
        'totalItems': itemsList.length,
        'topCategory': topCategory,
        'topOccasion': topOccasion,
        'categoryDistribution': categoryCount,
        'totalOutfitsLogged': logsList.length,
      };
    } catch (e) {
      debugPrint('Error fetching insights: $e');
      return _emptyInsights();
    }
  }

  Map<String, dynamic> _emptyInsights() => {
    'totalItems': 0,
    'topCategory': 'None',
    'topOccasion': 'Casual',
    'categoryDistribution': {},
    'totalOutfitsLogged': 0,
  };

  // ── QUIZ ────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchQuizResult() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client
          .from('style_quiz_results')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('Error fetching quiz result: $e');
      return null;
    }
  }

  Future<bool> saveQuizResult({
    required String styleProfile,
    required List<String> preferredColors,
    required List<String> styleGoals,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      await _client.from('style_quiz_results').upsert({
        'user_id': userId,
        'style_profile': styleProfile,
        'preferred_colors': preferredColors,
        'style_goals': styleGoals,
        'answers': answers,
        'completed_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
      return false;
    }
  }
}
