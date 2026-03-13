import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './wardrobe_service.dart';
import './outfit_log_service.dart';

class TodaySuggestionService {
  SupabaseClient get _client => SupabaseService.instance.client;
  final WardrobeService _wardrobeService = WardrobeService();
  final OutfitLogService _outfitLogService = OutfitLogService();

  Future<Map<String, dynamic>?> fetchTodaySuggestion({
    required Map<String, dynamic> weather,
    required Map<String, dynamic>? quizResult,
    required Map<String, dynamic>? nextEvent,
    String? occasion,
    String? mood,
  }) async {
    try {
      // Load wardrobe items
      final wardrobeItems = await _wardrobeService.fetchWardrobeItems();
      if (wardrobeItems.isEmpty) return null;

      // Load recent outfit logs to get recently worn items
      final recentLogs = await _outfitLogService.fetchOutfitLogsForDate(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      final recentItems = recentLogs
          .expand((log) => (log['outfit_items'] as List? ?? []))
          .map((oi) => oi['wardrobe_items']?['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      // Build compact wardrobe list for prompt
      final compactWardrobe = wardrobeItems.map((item) => {
        'id': item['id'],
        'name': item['name'],
        'category': item['category'],
        'color': item['color'],
        'image_url': item['image_url'],
        'times_worn': item['times_worn'] ?? 0,
        'last_worn': item['last_worn'],
      }).toList();

      // Build user profile from quiz
      final profile = quizResult != null ? {
        'styleProfile': quizResult['style_profile'],
        'preferredColors': quizResult['preferred_colors']?.toString(),
        'styleGoals': quizResult['style_goals']?.toString(),
        'styleIntention': quizResult['style_intention']?.toString(),
      } : null;

      // Build next event summary
      Map<String, dynamic>? eventSummary;
      if (nextEvent != null) {
        final date = DateTime.parse(nextEvent['event_date']);
        final daysLeft = date.difference(DateTime.now()).inDays;
        eventSummary = {
          'title': nextEvent['title'],
          'event_type': nextEvent['event_type'],
          'dress_code': nextEvent['dress_code'],
          'daysLeft': daysLeft,
        };
      }

      final response = await _client.functions.invoke(
        'today-suggestion',
        body: {
          'userProfile': profile,
          'weather': weather,
          'occasion': occasion,
          'mood': mood,
          'wardrobeItems': compactWardrobe,
          'recentItems': recentItems,
          'nextEvent': eventSummary,
        },
      );

      debugPrint('Today suggestion response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Today suggestion error: $e');
      return null;
    }
  }
}
