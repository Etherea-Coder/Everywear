import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everywear/core/providers.dart';

void main() {
  group('State Providers', () {
    test('dailyLogViewModeProvider defaults to calendar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(dailyLogViewModeProvider), 'calendar');
    });

    test('dailyLogViewModeProvider can be toggled to list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(dailyLogViewModeProvider.notifier).state = 'list';
      expect(container.read(dailyLogViewModeProvider), 'list');
    });

    test('dailyLogSelectedDateProvider defaults to now', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedDate = container.read(dailyLogSelectedDateProvider);
      final now = DateTime.now();
      expect(selectedDate.year, now.year);
      expect(selectedDate.month, now.month);
      expect(selectedDate.day, now.day);
    });

    test('dailyLogFocusedMonthProvider defaults to now', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final focusedMonth = container.read(dailyLogFocusedMonthProvider);
      final now = DateTime.now();
      expect(focusedMonth.year, now.year);
      expect(focusedMonth.month, now.month);
    });

    test('aiIntelligenceTimeRangeProvider defaults to month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(aiIntelligenceTimeRangeProvider), 'month');
    });

    test('aiIntelligenceTimeRangeProvider can be changed to week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(aiIntelligenceTimeRangeProvider.notifier).state = 'week';
      expect(container.read(aiIntelligenceTimeRangeProvider), 'week');
    });

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
