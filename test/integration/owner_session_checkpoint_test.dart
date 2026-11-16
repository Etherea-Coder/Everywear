import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/owner_session_checkpoint.dart';

void main() {
  testWidgets('checkpoint requires explicit confirmation and returns true', (
    tester,
  ) async {
    Future<bool>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                result = showOwnerSessionCheckpoint(
                  context,
                  title: 'Normal app session',
                  message: 'Check the normal app before continuing.',
                );
              },
              child: const Text('Open checkpoint'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open checkpoint'));
    await tester.pumpAndSettle();
    expect(find.text('Normal app session'), findsOneWidget);
    expect(
      find.text('Check the normal app before continuing.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('confirm_normal_session_checkpoint')),
    );
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}
