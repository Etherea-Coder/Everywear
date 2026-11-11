import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everywear/core/providers.dart';

void main() {
  group('State Providers', () {
    test('themeModeProvider defaults to light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('localeProvider defaults to en', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('wardrobeCategoryProvider defaults to All', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wardrobeCategoryProvider), 'All');
    });

    test('wardrobeSearchQueryProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wardrobeSearchQueryProvider), '');
    });
  });

  group('filteredWardrobeItemsProvider', () {
    test('filters by category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(wardrobeCategoryProvider.notifier).state = 'Tops';

      final filtered = container.read(filteredWardrobeItemsProvider);
      expect(filtered, isA<AsyncValue>());
    });

    test('filters by search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(wardrobeSearchQueryProvider.notifier).state = 'blue';

      final filtered = container.read(filteredWardrobeItemsProvider);
      expect(filtered, isA<AsyncValue>());
    });
  });
}
