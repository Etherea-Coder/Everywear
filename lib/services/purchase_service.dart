import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class PurchaseService {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<Map<String, dynamic>>> fetchPurchases({String? category, String? brand, DateTime? startDate, DateTime? endDate}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      var query = _client.from('purchases').select().eq('user_id', userId);
      if (category != null && category != 'All') query = query.eq('category', category);
      if (brand != null && brand != 'All') query = query.eq('brand', brand);
      if (startDate != null) query = query.gte('purchase_date', startDate.toIso8601String());
      if (endDate != null) query = query.lte('purchase_date', endDate.toIso8601String());
      final response = await query.order('purchase_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { debugPrint('Error fetching purchases: $e'); return []; }
  }

  Future<Map<String, dynamic>> fetchMonthlyStats(DateTime month) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'totalSpent': 0.0, 'purchaseCount': 0};
      final start = DateTime(month.year, month.month, 1).toIso8601String();
      final end = DateTime(month.year, month.month + 1, 0).toIso8601String();
      final response = await _client.from('purchases').select('price').eq('user_id', userId).gte('purchase_date', start).lte('purchase_date', end);
      final purchases = List<Map<String, dynamic>>.from(response);
      final totalSpent = purchases.fold(0.0, (sum, p) => sum + (p['price'] as num).toDouble());
      return {'totalSpent': totalSpent, 'purchaseCount': purchases.length};
    } catch (e) { debugPrint('Error fetching monthly stats: $e'); return {'totalSpent': 0.0, 'purchaseCount': 0}; }
  }

  Future<List<Map<String, dynamic>>> fetchMonthlySpending() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final response = await _client.from('purchases').select('price, purchase_date').eq('user_id', userId).gte('purchase_date', sixMonthsAgo.toIso8601String()).order('purchase_date', ascending: true);
      final Map<String, double> monthlyTotals = {};
      for (final purchase in List<Map<String, dynamic>>.from(response)) {
        final date = DateTime.parse(purchase['purchase_date']);
        final key = '${date.year}-${date.month.toString().padLeft(2, "0")}';
        monthlyTotals[key] = (monthlyTotals[key] ?? 0) + (purchase['price'] as num).toDouble();
      }
      return monthlyTotals.entries.map((e) => {'month': e.key, 'total': e.value}).toList();
    } catch (e) { debugPrint('Error fetching monthly spending: $e'); return []; }
  }

  Future<Map<String, dynamic>?> addPurchase({required String name, required double price, required DateTime purchaseDate, String? brand, String? category, String? imageUrl, String? notes, String? wardrobeItemId}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client.from('purchases').insert({
        'user_id': userId, 'name': name, 'price': price,
        'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        'brand': brand, 'category': category, 'image_url': imageUrl,
        'notes': notes, 'wardrobe_item_id': wardrobeItemId,
      }).select().single();
      return Map<String, dynamic>.from(response);
    } catch (e) { debugPrint('Error adding purchase: $e'); return null; }
  }

  Future<bool> deletePurchase(String purchaseId) async {
    try {
      await _client.from('purchases').delete().eq('id', purchaseId);
      return true;
    } catch (e) { debugPrint('Error deleting purchase: $e'); return false; }
  }

  Future<List<String>> fetchBrands() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client.from('purchases').select('brand').eq('user_id', userId).not('brand', 'is', null);
      return List<Map<String, dynamic>>.from(response).map((p) => p['brand'] as String).toSet().toList();
    } catch (e) { debugPrint('Error fetching brands: $e'); return []; }
  }

  double calculateCostPerWear(double price, int wearCount) {
    if (wearCount == 0) return price;
    return price / wearCount;
  }
}
