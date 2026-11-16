import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/today_outfit_scroll.dart';

void main() {
  testWidgets('scrolls the Today list to the exact saved outfit row', (
    tester,
  ) async {
    const outfitId = 'saved-outfit-42';
    final listView = find
        .descendant(
          of: find.byKey(const ValueKey('today_screen')),
          matching: find.byType(ListView),
        )
        .first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: const ValueKey('today_screen'),
          body: ListView(
            children: [
              ...List<Widget>.generate(30, (_) => const SizedBox(height: 180)),
              const Card(
                key: ValueKey('today_outfit_saved-outfit-42'),
                child: Text('Synthetic test outfit'),
              ),
            ],
          ),
        ),
      ),
    );

    final visibleRow = await scrollToTodayOutfitRow(tester, outfitId);

    expect(visibleRow, findsOneWidget);
    expect(
      find.descendant(
        of: visibleRow,
        matching: find.text('Synthetic test outfit'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(visibleRow).overlaps(tester.getRect(listView)),
      isTrue,
    );
  });
}
