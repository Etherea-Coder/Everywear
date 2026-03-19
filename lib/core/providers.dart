import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/wardrobe_repository.dart';
import '../services/user_tier_service.dart';
import './utils/locale_manager.dart';

final wardrobeRepositoryProvider = Provider((ref) => WardrobeRepository());

final userTierServiceProvider = Provider((ref) => UserTierService());

// Auth user — derived from authStateProvider, no second stream subscription
final supabaseAuthProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

// Profile from your `profiles` table (membership tier, etc.)
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(supabaseAuthProvider);
  if (user == null) return null;

  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('membership_tier')
        .eq('id', user.id)
        .single();

    return data;
  } catch (e) {
    // Profile may not exist yet, return null
    debugPrint('Profile not found for user ${user.id}: $e');
    return null;
  }
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseService.isInitialized) {
    debugPrint('⚠️ authStateProvider: Supabase not initialized, returning empty stream');
    return const Stream.empty();
  }
  debugPrint('✅ authStateProvider: Listening to auth state changes');
  // Return the stream directly — NO secondary .listen() call
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
      try {
        final repository = ref.read(wardrobeRepositoryProvider);
        return await repository.getWardrobeItems().timeout(
          const Duration(seconds: 10),
          onTimeout: () => [],
        );
      } catch (e) {
        debugPrint('WardrobeItemsNotifier refresh error: $e');
        return []; // Return empty list on error
      }
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
    if (category != 'All' && category != 'all') {
      filtered = filtered.where((item) => 
        (item['category']?.toString().toLowerCase() ?? '') == category.toLowerCase()
      ).toList();
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
