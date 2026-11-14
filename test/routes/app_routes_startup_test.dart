import 'package:everywear/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('route table can be mounted alongside the app home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: const SizedBox(), routes: AppRoutes.routes),
    );

    expect(tester.takeException(), isNull);
    expect(AppRoutes.routes, isNot(contains(Navigator.defaultRouteName)));
  });
}
