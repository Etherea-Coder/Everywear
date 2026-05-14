import 'package:supabase_flutter/supabase_flutter.dart';
import './wardrobe_service.dart';

class LookbookService {
  final WardrobeService _wardrobeService = WardrobeService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generates a summary of the best outfits for the current month
  Future<Map<String, dynamic>> generateMonthlyLookbook() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Fetch outfit history
      final history = await _wardrobeService.fetchOutfitHistory(limit: 100);
      
      // Filter for current month and high ratings
      final monthlyOutfits = history.where((outfit) {
        final wornDate = outfit['worn_date'] != null 
            ? DateTime.parse(outfit['worn_date']) 
            : DateTime.now();
        return wornDate.isAfter(firstDayOfMonth) && (outfit['rating'] ?? 0) >= 3;
      }).toList();

      // Aggregate top items
      final itemUsage = <String, int>{};
      for (var outfit in monthlyOutfits) {
        final items = outfit['outfit_items'] as List?;
        if (items != null) {
          for (var item in items) {
            final itemName = item['wardrobe_items']['name'] as String;
            itemUsage[itemName] = (itemUsage[itemName] ?? 0) + 1;
          }
        }
      }

      // Sort items by usage
      final sortedItems = itemUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'month': _getMonthName(now.month),
        'year': now.year,
        'outfitCount': monthlyOutfits.length,
        'bestOutfits': monthlyOutfits.take(5).toList(),
        'mostWornItems': sortedItems.take(3).map((e) => {'name': e.key, 'count': e.value}).toList(),
      };
    } catch (e) {
      throw Exception('Failed to generate lookbook: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
