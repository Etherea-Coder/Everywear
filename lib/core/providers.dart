import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/wardrobe_repository.dart';
import '../services/wardrobe_service.dart';
import '../services/user_tier_service.dart';
import '../services/daily_log_service.dart';
import '../services/daily_log_repository.dart';
import '../services/ai_intelligence_service.dart';
import '../services/ai_suggestions_service.dart';
import '../services/weather_service.dart';
import '../services/lookbook_service.dart';
import '../services/today_suggestion_service.dart';
import '../services/style_service.dart';
import '../services/notification_service.dart';
import '../services/ai/stylist_engine_service.dart';
import '../services/ai/vision_engine_service.dart';
import '../services/ai/model_download_service.dart';
import './utils/locale_manager.dart';

final wardrobeRepositoryProvider = Provider((ref) => WardrobeRepository());

final userTierServiceProvider = Provider((ref) => UserTierService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseService.isInitialized) {
    debugPrint('authStateProvider: Supabase not initialized, returning empty stream');
    return const Stream.empty();
  }

  debugPrint('authStateProvider: Listening to auth state changes');
  return SupabaseService.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  if (!SupabaseService.isInitialized) {
    return null;
  }
  // Safe watch with fallback
  return ref.watch(authStateProvider).maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

class WardrobeItemsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    try {
      final repository = ref.watch(wardrobeRepositoryProvider);
      return await repository.getWardrobeItems().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    } catch (e) {
      debugPrint('WardrobeItemsNotifier build error: $e');
      return []; // Return empty list on error to prevent white screens
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(wardrobeRepositoryProvider);
      return await repository.getWardrobeItems().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    });
  }

  Future<void> addItem(Map<String, dynamic> itemData) async {
    try {
      final repository = ref.read(wardrobeRepositoryProvider);
      final result = await repository.addItem(itemData).timeout(
        const Duration(seconds: 8),
        onTimeout: () => {'success': false, 'error': 'Timeout'},
      );
      if (result['success'] == true) {
        await refresh();
      }
    } catch (e) {
      debugPrint('WardrobeItemsNotifier addItem error: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final repository = ref.read(wardrobeRepositoryProvider);
      await repository.deleteItem(itemId).timeout(
        const Duration(seconds: 8),
        onTimeout: () => debugPrint('Delete timeout for item: $itemId'),
      );
      await refresh();
    } catch (e) {
      debugPrint('WardrobeItemsNotifier deleteItem error: $e');
    }
  }
}

final wardrobeItemsProvider = AsyncNotifierProvider<WardrobeItemsNotifier, List<Map<String, dynamic>>>(() {
  return WardrobeItemsNotifier();
});

final wardrobeSearchQueryProvider = StateProvider<String>((ref) => '');
final wardrobeCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredWardrobeItemsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final itemsAsync = ref.watch(wardrobeItemsProvider);
  final searchQuery = ref.watch(wardrobeSearchQueryProvider);
  final category = ref.watch(wardrobeCategoryProvider);

  return itemsAsync.whenData((items) {
    var filtered = items;
    if (category != 'All') {
      filtered = filtered.where((item) => item['category'] == category).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((item) => 
        (item['name']?.toString().toLowerCase().contains(query) ?? false) || 
        (item['brand']?.toString().toLowerCase().contains(query) ?? false)
      ).toList();
    }
    return filtered;
  });
});

final userTierProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(userTierServiceProvider);
  return service.getUserTierInfo(user.id);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  SettingsNotifier() : super(const AsyncValue.data(null));

  Future<void> updateTheme(ThemeMode mode) async {
    state = const AsyncValue.loading();
    await LocaleManager.saveThemeMode(mode.toString().split('.').last);
    state = const AsyncValue.data(null);
  }

  Future<void> updateLocale(Locale locale) async {
    state = const AsyncValue.loading();
    await LocaleManager.saveLocale(locale);
    state = const AsyncValue.data(null);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier();
});

final dailyLogServiceProvider = Provider((ref) => DailyLogService());

final dailyLogRepositoryProvider = Provider((ref) => DailyLogRepository());

final dailyLogSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyLogFocusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyLogViewModeProvider = StateProvider<String>((ref) => 'calendar');

class DailyLogEntriesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    try {
      final repository = ref.watch(dailyLogRepositoryProvider);
      return await repository.getOutfitEntries().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    } catch (e) {
      debugPrint('DailyLogEntriesNotifier build error: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dailyLogRepositoryProvider);
      return await repository.getOutfitEntries().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    });
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      final repository = ref.read(dailyLogRepositoryProvider);
      await repository.deleteOutfitEntry(entryId);
      await refresh();
    } catch (e) {
      debugPrint('DailyLogEntriesNotifier deleteEntry error: $e');
    }
  }

  Future<void> addEntry({
    required List<String> itemIds,
    String? outfitName,
    int? rating,
    String? notes,
    String? weather,
    String? occasion,
    DateTime? wornDate,
  }) async {
    try {
      final repository = ref.read(dailyLogRepositoryProvider);
      await repository.addOutfitEntry(
        itemIds: itemIds,
        outfitName: outfitName,
        rating: rating,
        notes: notes,
        weather: weather,
        occasion: occasion,
        wornDate: wornDate,
      );
      await refresh();
    } catch (e) {
      debugPrint('DailyLogEntriesNotifier addEntry error: $e');
    }
  }
}

final dailyLogEntriesProvider = AsyncNotifierProvider<DailyLogEntriesNotifier, List<Map<String, dynamic>>>(() {
  return DailyLogEntriesNotifier();
});

final dailyLogMonthlyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final focusedMonth = ref.watch(dailyLogFocusedMonthProvider);
  final repository = ref.read(dailyLogRepositoryProvider);
  return repository.getMonthlyStats(focusedMonth);
});

final aiIntelligenceServiceProvider = Provider((ref) => AIIntelligenceService());

final aiIntelligenceTimeRangeProvider = StateProvider<String>((ref) => 'month');

final aiInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final timeRange = ref.watch(aiIntelligenceTimeRangeProvider);
  final service = ref.read(aiIntelligenceServiceProvider);
  return service.getInsights(timeRange: timeRange);
});

final wardrobeServiceProvider = Provider((ref) => WardrobeService());

final aiSuggestionsServiceProvider = Provider((ref) => AiSuggestionsService());

final weatherServiceProvider = Provider((ref) => WeatherService());

final lookbookServiceProvider = Provider((ref) => LookbookService());

final todaySuggestionServiceProvider = Provider((ref) => TodaySuggestionService());

final styleServiceProvider = Provider((ref) => StyleService());

final notificationServiceProvider = Provider((ref) => NotificationService());

final stylistEngineServiceProvider = Provider((ref) => StylistEngineService());

final visionEngineServiceProvider = Provider((ref) => VisionEngineService());

final modelDownloadServiceProvider = Provider((ref) => ModelDownloadService());
