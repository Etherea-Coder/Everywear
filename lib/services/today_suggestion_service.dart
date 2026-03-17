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
        final result = Map<String, dynamic>.from(response.data);
        // Re-attach wardrobe image URLs and IDs to every item the AI picked.
        // The Edge Function returns names but loses the image_url — we fix
        // that here by matching each returned item name back to the wardrobe
        // index we already have in memory.
        return _reattachWardrobeData(result, wardrobeItems);
      }
      return null;
    } catch (e) {
      debugPrint('Today suggestion error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Wardrobe data reattachment
  // ---------------------------------------------------------------------------

  /// Builds a case-insensitive name → wardrobe item lookup once, then uses it
  /// to enrich every slot (anchor + items) in the AI response.
  Map<String, dynamic> _reattachWardrobeData(
    Map<String, dynamic> result,
    List<Map<String, dynamic>> wardrobeItems,
  ) {
    // Build lookup: lowercased name → wardrobe row
    final lookup = <String, Map<String, dynamic>>{};
    for (final w in wardrobeItems) {
      final name = (w['name'] ?? '').toString().toLowerCase().trim();
      if (name.isNotEmpty) lookup[name] = w;
    }

    Map<String, dynamic> enrich(Map<String, dynamic> item) {
      final mutable = Map<String, dynamic>.from(item);
      final name = (mutable['name'] ?? '').toString().toLowerCase().trim();

      // Try exact match first, then partial
      final match = lookup[name] ??
          lookup.entries
              .firstWhere(
                (e) => e.key.contains(name) || name.contains(e.key),
                orElse: () => const MapEntry('', {}),
              )
              .value;

      if (match.isNotEmpty) {
        final imageUrl = (match['image_url'] ?? match['imageUrl'] ?? '').toString();
        if (imageUrl.isNotEmpty) mutable['imageUrl'] = imageUrl;
        // Also carry the wardrobe ID so "Save Displayed Outfit" can log it
        mutable['id'] ??= match['id'];
      }
      return mutable;
    }

    // Enrich anchor
    if (result['anchor'] is Map) {
      result = {
        ...result,
        'anchor': enrich(Map<String, dynamic>.from(result['anchor'] as Map)),
      };
    }

    // Enrich item slots
    if (result['items'] is List) {
      result = {
        ...result,
        'items': (result['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(enrich)
            .toList(),
      };
    }

    return result;
  }
}