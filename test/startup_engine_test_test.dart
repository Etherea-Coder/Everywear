import 'package:everywear/startup_engine_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the isolation entrypoint paints its plain engine screen', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupEngineTestApp());

    expect(find.text('EVERYWEAR ENGINE TEST'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF1565C0),
    );
  });
}
