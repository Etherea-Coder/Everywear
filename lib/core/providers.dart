import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/wardrobe_repository.dart';
import '../services/user_tier_service.dart';
import './utils/locale_manager.dart';

final wardrobeRepositoryProvider = Provider((ref) => WardrobeRepository());

final userTierServiceProvider = Provider((ref) => UserTierService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseService.isInitialized) {
    // Return a dummy stream that emits a fake state to move provider to 'data' state
    // This prevents the UI from staying in the branded loading screen
    return Stream.value(AuthState(AuthChangeEvent.initialSession, null));
  }
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
    final repository = ref.watch(wardrobeRepositoryProvider);
    return repository.getWardrobeItems();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.watch(wardrobeRepositoryProvider);
      return repository.getWardrobeItems();
    });
  }

  Future<void> addItem(Map<String, dynamic> itemData) async {
    final repository = ref.read(wardrobeRepositoryProvider);
    final result = await repository.addItem(itemData);
    if (result['success'] == true) {
      await refresh();
    }
  }

  Future<void> deleteItem(String itemId) async {
    final repository = ref.read(wardrobeRepositoryProvider);
    await repository.deleteItem(itemId);
    await refresh();
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
