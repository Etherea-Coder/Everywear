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
      final wardrobeItems = await _wardrobeService.fetchWardrobeItems();
      if (wardrobeItems.isEmpty) return null;

      // Recent items to nudge Gemini away from repeats
      final recentLogs = await _outfitLogService.fetchOutfitLogsForDate(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      final recentItems = recentLogs
          .expand((log) => (log['outfit_items'] as List? ?? []))
          .map((oi) => oi['wardrobe_items']?['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      final compactWardrobe = wardrobeItems.map((item) => {
        'id': item['id'],
        'name': item['name'],
        'category': item['category'],
        'color': item['color'],
        'image_url': item['image_url'],
        'times_worn': item['times_worn'] ?? 0,
        'last_worn': item['last_worn'],
      }).toList();

      final profile = quizResult != null ? {
        'styleProfile': quizResult['style_profile'],
        'preferredColors': quizResult['preferred_colors']?.toString(),
        'styleGoals': quizResult['style_goals']?.toString(),
        'styleIntention': quizResult['style_intention']?.toString(),
      } : null;

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

      final user = _client.auth.currentUser;
      final userName = _getUserFirstName(user);

      final response = await _client.functions.invoke(
        'today-suggestion',
        body: {
          'userName': userName,
          'localHour': DateTime.now().hour,
          'userProfile': profile,
          'weather': weather,
          'occasion': occasion,
          'mood': mood,
          'wardrobeItems': compactWardrobe,
          'recentItems': recentItems,
          'nextEvent': eventSummary,
        },
      );

      if (kDebugMode) debugPrint('Today suggestion response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        final result = Map<String, dynamic>.from(response.data);
        return _clientSidePatch(result, wardrobeItems);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Today suggestion error: $e');
      return null;
    }
  }

  /// Client-side safety net: if Edge Function returned empty imageUrl for a
  /// known id, fill it from the wardrobe list already in memory.
  Map<String, dynamic> _clientSidePatch(
    Map<String, dynamic> result,
    List<Map<String, dynamic>> wardrobeItems,
  ) {
    final byId = <String, Map<String, dynamic>>{
      for (final w in wardrobeItems)
        if ((w['id'] ?? '').toString().isNotEmpty)
          w['id'].toString(): w,
    };

    Map<String, dynamic> patch(Map<String, dynamic> item) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) return item;
      final row = byId[id];
      if (row == null) return item;
      final url = (row['image_url'] ?? row['imageUrl'] ?? '').toString();
      if (url.isEmpty) return item;
      if ((item['imageUrl'] ?? '').toString().isNotEmpty) return item;
      return {...item, 'imageUrl': url};
    }

    return {
      ...result,
      if (result['anchor'] is Map)
        'anchor': patch(Map<String, dynamic>.from(result['anchor'] as Map)),
      if (result['items'] is List)
        'items': (result['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(patch)
            .toList(),
    };
  }

  String? _getUserFirstName(User? user) {
    if (user == null) return null;
    final fullName = user.userMetadata?['full_name'] as String? ?? 
                     user.userMetadata?['name'] as String?;
    if (fullName == null || fullName.trim().isEmpty) return null;
    return fullName.trim().split(' ').first;
  }
}