import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isolated package launches and renders without app services', (
    tester,
  ) async {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('STAGING PACKAGE ISOLATION OK')),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('STAGING PACKAGE ISOLATION OK'), findsOneWidget);
  });
}
