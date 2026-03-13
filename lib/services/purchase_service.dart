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
        'brand': brand, 'image_url': imageUrl,
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
  // ── BUDGET ──────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchBudget() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {'monthly_budget': 0.0, 'currency': 'EUR'};
      final response = await _client
          .from('user_budget')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return {'monthly_budget': 0.0, 'currency': 'EUR'};
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching budget: $e');
      return {'monthly_budget': 0.0, 'currency': 'EUR'};
    }
  }

  Future<bool> saveBudget({
    required double monthlyBudget,
    String currency = 'EUR',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      await _client.from('user_budget').upsert({
        'user_id': userId,
        'monthly_budget': monthlyBudget,
        'currency': currency,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving budget: $e');
      return false;
    }
  }

  // ── WISHLIST ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchWishlist() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      final response = await _client
          .from('wishlist')
          .select()
          .eq('user_id', userId)
          .eq('is_purchased', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addWishlistItem({
    required String name,
    String? brand,
    String? category,
    double? targetPrice,
    double? currentPrice,
    String? url,
    String? imageUrl,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client.from('wishlist').insert({
        'user_id': userId,
        'name': name,
        'brand': brand,
        'category': category,
        'target_price': targetPrice,
        'current_price': currentPrice,
        'url': url,
        'image_url': imageUrl,
        'notes': notes,
      }).select().single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error adding wishlist item: $e');
      return null;
    }
  }

  Future<bool> deleteWishlistItem(String id) async {
    try {
      await _client.from('wishlist').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting wishlist item: $e');
      return false;
    }
  }

  Future<bool> markWishlistItemPurchased(String id, double finalPrice) async {
    try {
      await _client.from('wishlist').update({
        'is_purchased': true,
        'current_price': finalPrice,
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error marking wishlist item purchased: $e');
      return false;
    }
  }

  Future<bool> updateWishlistPrice(String id, double newPrice) async {
    try {
      await _client.from('wishlist').update({
        'current_price': newPrice,
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating wishlist price: $e');
      return false;
    }
  }

  // ── REAL CPW ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchCPWLeaderboard() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Get purchases with wardrobe_item_id
      final purchases = await _client
          .from('purchases')
          .select()
          .eq('user_id', userId)
          .not('wardrobe_item_id', 'is', null);

      final result = <Map<String, dynamic>>[];

      for (final purchase in purchases as List) {
        final wardrobeItemId = purchase['wardrobe_item_id'] as String;
        // Count wear times from outfit_items
        final wearData = await _client
            .from('outfit_items')
            .select('id')
            .eq('wardrobe_item_id', wardrobeItemId);

        final wearCount = (wearData as List).length;
        final price = (purchase['price'] as num).toDouble();
        final cpw = wearCount > 0 ? price / wearCount : price;

        result.add({
          'id': purchase['id'],
          'name': purchase['name'],
          'brand': purchase['brand'],
          'price': price,
          'wearCount': wearCount,
          'cpw': cpw,
          'category': purchase['category'],
          'image_url': purchase['image_url'],
          'wardrobe_item_id': wardrobeItemId,
        });
      }

      // Sort by CPW ascending (best value first)
      result.sort((a, b) => (a['cpw'] as double).compareTo(b['cpw'] as double));
      return result;
    } catch (e) {
      debugPrint('Error fetching CPW leaderboard: $e');
      return [];
    }
  }

  // Category spending breakdown
  Future<Map<String, double>> fetchCategorySpending() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final purchases = await _client
          .from('purchases')
          .select('category, price')
          .eq('user_id', userId)
          .gte('purchase_date', start);
      final Map<String, double> result = {};
      for (final p in purchases as List) {
        final cat = p['category'] as String? ?? 'Other';
        result[cat] = (result[cat] ?? 0) + (p['price'] as num).toDouble();
      }
      return result;
    } catch (e) {
      debugPrint('Error fetching category spending: $e');
      return {};
    }
  }

}
