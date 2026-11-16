import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the visible Today list to one exact outfit row, with a finite bound.
Future<Finder> scrollToTodayOutfitRow(
  WidgetTester tester,
  String outfitId,
) async {
  final todayScreen = find.byKey(const ValueKey('today_screen'));
  final row = find.byKey(ValueKey('today_outfit_$outfitId'));
  final scrollables = find.descendant(
    of: todayScreen,
    matching: find.byType(Scrollable),
  );
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (scrollables.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (scrollables.evaluate().isEmpty) {
    throw TestFailure(
      'Today did not finish loading into its scrollable list after returning '
      'from outfit save.',
    );
  }

  await tester.scrollUntilVisible(
    row,
    360,
    scrollable: scrollables.first,
    maxScrolls: 20,
    duration: const Duration(milliseconds: 80),
  );
  await tester.pump();
  return row;
}
