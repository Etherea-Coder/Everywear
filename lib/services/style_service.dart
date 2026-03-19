import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StyleService {
  SupabaseClient get _client => SupabaseService.instance.client;
  
  // Public getter for accessing client
  SupabaseClient get client => _client;

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

  Future<Map<String, dynamic>?> updateEvent({
    required String eventId,
    required String title,
    required DateTime eventDate,
    required String eventType,
    String? dressCode,
    String? notes,
  }) async {
    try {
      final response = await _client
          .from('style_events')
          .update({
            'title': title,
            'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
            'event_type': eventType,
            'dress_code': dressCode,
            'notes': (notes != null && notes.isNotEmpty) ? notes : null,
            // outfit_id is intentionally omitted — we never overwrite it here
          })
          .eq('id', eventId)
          .select()
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return null;
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
    String? styleIntention,
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
        'style_intention': styleIntention,
        'completed_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
      return false;
    }
  }
  // ── COACH ───────────────────────────────────────────────
  Future<String> fetchPassiveCoachTip({
    required Map<String, dynamic> insights,
    Map<String, dynamic>? quizResult,
  }) async {
    try {
      final profile = quizResult != null ? {
        'styleProfile': quizResult['style_profile'],
        'preferredColors': quizResult['preferred_colors']?.toString(),
        'styleGoals': quizResult['style_goals']?.toString(),
        'styleIntention': quizResult['style_intention']?.toString(),
      } : null;

      final wardrobeSummary = _buildWardrobeSummary(insights);

      final response = await _client.functions.invoke(
        'style-coach',
        body: {
          'mode': 'passive',
          'userProfile': profile,
          'insights': insights,
          'wardrobeSummary': wardrobeSummary,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['tip'] as String? ?? _localPassiveTip(insights, quizResult);
      }
      return _localPassiveTip(insights, quizResult);
    } catch (e) {
      debugPrint('Coach passive tip error: $e');
      return _localPassiveTip(insights, quizResult);
    }
  }

  Future<Map<String, dynamic>> askCoach({
    required String question,
    required Map<String, dynamic> insights,
    Map<String, dynamic>? quizResult,
  }) async {
    try {
      final profile = quizResult != null ? {
        'styleProfile': quizResult['style_profile'],
        'preferredColors': quizResult['preferred_colors']?.toString(),
        'styleGoals': quizResult['style_goals']?.toString(),
        'styleIntention': quizResult['style_intention']?.toString(),
      } : null;

      final response = await _client.functions.invoke(
        'style-coach',
        body: {
          'mode': 'active',
          'userProfile': profile,
          'insights': insights,
          'wardrobeSummary': _buildWardrobeSummary(insights),
          'question': question,
        },
      );

      debugPrint('Coach response status: ${response.status}');
      debugPrint('Coach response data: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return {
          'answer': response.data['answer'] ?? response.data['tip'] ?? 'No answer received.',
          'next_step': response.data['next_step'] ?? '',
        };
      }
      final errMsg = response.data?['error'] ?? 'Unknown error (status ${response.status})';
      return {'answer': 'Coach error: $errMsg', 'next_step': ''};
    } catch (e) {
      debugPrint('Coach active error: $e');
      return {'answer': 'ERROR: ${e.runtimeType}: ${e.toString()}', 'next_step': ''};
    }
  }

  Future<Map<String, dynamic>> fetchEventCoaching({
    required Map<String, dynamic> event,
    required Map<String, dynamic> insights,
    Map<String, dynamic>? quizResult,
  }) async {
    try {
      final date = DateTime.parse(event['event_date']);
      final daysLeft = date.difference(DateTime.now()).inDays;
      final profile = quizResult != null ? {
        'styleProfile': quizResult['style_profile'],
        'preferredColors': quizResult['preferred_colors']?.toString(),
        'styleGoals': quizResult['style_goals']?.toString(),
        'styleIntention': quizResult['style_intention']?.toString(),
      } : null;

      final response = await _client.functions.invoke(
        'style-coach',
        body: {
          'mode': 'event',
          'userProfile': profile,
          'insights': insights,
          'wardrobeSummary': _buildWardrobeSummary(insights),
          'event': {
            'title': event['title'],
            'type': event['event_type'],
            'date': event['event_date'],
            'daysLeft': daysLeft,
            'dressCode': event['dress_code'] ?? 'Not specified',
          },
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data as Map<String, dynamic>;
      }
      return {'error': 'Coach response unsuccessful'};
    } catch (e) {
      return {'error': 'ERROR: ${e.runtimeType}: ${e.toString()}'};
    }
  }

  String _buildWardrobeSummary(Map<String, dynamic> insights) {
    final total = insights['totalItems'] ?? 0;
    final topCat = insights['topCategory'] ?? 'Unknown';
    final topOcc = insights['topOccasion'] ?? 'Casual';
    final dist = insights['categoryDistribution'] as Map? ?? {};
    final distStr = dist.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return 'Total: $total items. Distribution: $distStr. Top category: $topCat. Top occasion: $topOcc.';
  }

  String _localPassiveTip(Map<String, dynamic> insights, Map<String, dynamic>? quiz) {
    final profile = (quiz?['style_profile'] ?? '').toString().toLowerCase();
    final topCat = insights['topCategory'] ?? 'your wardrobe';
    if (profile.contains('classic')) return 'Your style leans polished and timeless. Try one softer texture this week to add depth without losing elegance.';
    if (profile.contains('bold')) return 'You enjoy expressive style. Balance one statement piece with a simpler base to make it stand out even more.';
    if (profile.contains('sport')) return 'Your style is practical. Try elevating one look with a more structured layer for a sharper finish.';
    if (profile.contains('minimal')) return 'Your style is clean and intentional. Focus on contrast this week with one richer tone or texture.';
    return 'You have a strong base in $topCat. Try combining a familiar piece with something you wear less often this week.';
  }

}
