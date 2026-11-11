import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/wardrobe_repository.dart';
import '../services/user_tier_service.dart';
import '../services/outfit_log_service.dart';
import '../services/ai/model_download_service.dart';
import './utils/locale_manager.dart';

final wardrobeRepositoryProvider = Provider((ref) => WardrobeRepository());

final userTierServiceProvider = Provider((ref) => UserTierService());

// Auth user — derived from authStateProvider, no second stream subscription
final supabaseAuthProvider = Provider<User?>((ref) {
  return ref
      .watch(authStateProvider)
      .maybeWhen(data: (state) => state.session?.user, orElse: () => null);
});

// Profile from `user_profiles` (membership tier, etc.)
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(supabaseAuthProvider);
  if (user == null) return null;

  try {
    final data = await Supabase.instance.client
        .from('user_profiles')
        .select('onboarding_completed')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    // Resolve entitlement state through the server-owned status/expiry fields.
    // A stale tier flag or a backend schema that has not received the reviewed
    // entitlement migration must never make the UI present paid access.
    final tier = await UserTierService().getUserTier(expectedUserId: user.id);
    if (Supabase.instance.client.auth.currentUser?.id != user.id) return null;
    return {...data, 'membership_tier': tier};
  } catch (e) {
    if (kDebugMode)
      debugPrint('Unable to load profile for user ${user.id}: $e');
    rethrow;
  }
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseService.isInitialized) {
    if (kDebugMode)
      debugPrint(
        '⚠️ authStateProvider: Supabase not initialized, returning signedOut state',
      );
    // Return a stream that immediately emits signedOut so the UI shows the Splash/Login
    return Stream.value(const AuthState(AuthChangeEvent.signedOut, null));
  }
  if (kDebugMode)
    debugPrint('✅ authStateProvider: Listening to auth state changes');
  return SupabaseService.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  if (!SupabaseService.isInitialized) {
    return null;
  }
  // Safe watch with fallback
  return ref
      .watch(authStateProvider)
      .maybeWhen(data: (state) => state.session?.user, orElse: () => null);
});

class WardrobeItemsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repository = ref.watch(wardrobeRepositoryProvider);
    return repository.getWardrobeItems().timeout(const Duration(seconds: 10));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(wardrobeRepositoryProvider);
      return repository.getWardrobeItems().timeout(const Duration(seconds: 10));
    });
  }

  Future<void> addItem(Map<String, dynamic> itemData) async {
    try {
      final repository = ref.read(wardrobeRepositoryProvider);
      final result = await repository
          .addItem(itemData)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => {'success': false, 'error': 'Timeout'},
          );
      if (result['success'] == true) {
        await refresh();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('WardrobeItemsNotifier addItem error: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final repository = ref.read(wardrobeRepositoryProvider);
      await repository
          .deleteItem(itemId)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              if (kDebugMode) debugPrint('Delete timeout for item: $itemId');
            },
          );
      await refresh();
    } catch (e) {
      if (kDebugMode) debugPrint('WardrobeItemsNotifier deleteItem error: $e');
    }
  }
}

final wardrobeItemsProvider =
    AsyncNotifierProvider<WardrobeItemsNotifier, List<Map<String, dynamic>>>(
      () {
        return WardrobeItemsNotifier();
      },
    );

final wardrobeSearchQueryProvider = StateProvider<String>((ref) => '');
final wardrobeCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredWardrobeItemsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
      final itemsAsync = ref.watch(wardrobeItemsProvider);
      final searchQuery = ref.watch(wardrobeSearchQueryProvider);
      final category = ref.watch(wardrobeCategoryProvider);

      return itemsAsync.whenData((items) {
        var filtered = items;
        if (category != 'All' && category != 'all') {
          filtered = filtered
              .where(
                (item) =>
                    (item['category']?.toString().toLowerCase() ?? '') ==
                    category.toLowerCase(),
              )
              .toList();
        }
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filtered = filtered
              .where(
                (item) =>
                    (item['name']?.toString().toLowerCase().contains(query) ??
                        false) ||
                    (item['brand']?.toString().toLowerCase().contains(query) ??
                        false),
              )
              .toList();
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

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
      return SettingsNotifier();
    });

/// Daily log entry operations (delete, etc.)
class DailyLogEntriesNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];

  Future<bool> deleteEntry(String entryId) async {
    final service = OutfitLogService();
    return await service.deleteOutfitLog(entryId);
  }
}

final dailyLogEntriesProvider =
    AsyncNotifierProvider<DailyLogEntriesNotifier, List<Map<String, dynamic>>>(
      () => DailyLogEntriesNotifier(),
    );

/// AI model download service
final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});
