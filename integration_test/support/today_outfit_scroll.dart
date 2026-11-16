import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the visible Today list to one exact outfit row, with a finite bound.
Future<Finder> scrollToTodayOutfitRow(
  WidgetTester tester,
  String outfitId,
) async {
  final todayScreen = find.byKey(const ValueKey('today_screen'));
  final row = find.byKey(ValueKey('today_outfit_$outfitId'));
  final scrollable = find
      .descendant(of: todayScreen, matching: find.byType(Scrollable))
      .first;

  await tester.scrollUntilVisible(
    row,
    360,
    scrollable: scrollable,
    maxScrolls: 20,
    duration: const Duration(milliseconds: 80),
  );
  await tester.pump();
  return row;
}
