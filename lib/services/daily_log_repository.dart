import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './daily_log_service.dart';
import './local_database_service.dart';

class DailyLogRepository {
  final DailyLogService _remoteService = DailyLogService();
  final LocalDatabaseService _localService = LocalDatabaseService();

  Future<List<Map<String, dynamic>>> getOutfitEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          final remoteEntries = await _remoteService.fetchOutfitEntries(
            startDate: startDate,
            endDate: endDate,
          ).timeout(const Duration(seconds: 8));
          return remoteEntries;
        } catch (e) {
          debugPrint('Remote daily log fetch failed, falling back to local: $e');
          return _fetchLocalEntries(startDate, endDate);
        }
      } else {
        return _fetchLocalEntries(startDate, endDate);
      }
    } catch (e) {
      debugPrint('Complete daily log fetch failure: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLocalEntries(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final localItems = await _localService.getLocalItems();
      return localItems.map((item) => {
        'id': item.remoteId ?? item.id.toString(),
        'name': item.name,
        'category': item.category,
        'image_url': item.imageUrl,
        'semantic_label': item.semanticLabel,
      }).toList();
    } catch (e) {
      debugPrint('Local daily log fetch error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addOutfitEntry({
    required List<String> itemIds,
    String? outfitName,
    int? rating,
    String? notes,
    String? weather,
    String? occasion,
    DateTime? wornDate,
  }) async {
    return _remoteService.createOutfitEntry(
      itemIds: itemIds,
      outfitName: outfitName,
      rating: rating,
      notes: notes,
      weather: weather,
      occasion: occasion,
      wornDate: wornDate,
    );
  }

  Future<void> deleteOutfitEntry(String entryId) async {
    await _remoteService.deleteOutfitEntry(entryId);
  }

  Future<Map<String, dynamic>?> updateOutfitEntry({
    required String entryId,
    String? outfitName,
    int? rating,
    String? notes,
    String? occasion,
  }) async {
    return _remoteService.updateOutfitEntry(
      entryId: entryId,
      outfitName: outfitName,
      rating: rating,
      notes: notes,
      occasion: occasion,
    );
  }

  Future<Map<String, dynamic>> getMonthlyStats(DateTime month) async {
    return _remoteService.getMonthlyStats(month);
  }

  RealtimeChannel subscribeToChanges({
    required void Function(PostgresChangePayload payload) onInsert,
    required void Function(PostgresChangePayload payload) onUpdate,
    required void Function(PostgresChangePayload payload) onDelete,
  }) {
    return _remoteService.subscribeToOutfitChanges(
      onInsert: onInsert,
      onUpdate: onUpdate,
      onDelete: onDelete,
    );
  }
}
