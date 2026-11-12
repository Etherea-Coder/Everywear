import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/widgets/staging_build_banner.dart';

void main() {
  testWidgets('staging builds show a persistent staging banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StagingBuildBanner(
          enabled: true,
          child: Scaffold(body: Text('Everywear')),
        ),
      ),
    );

    final banner = tester.widget<Banner>(
      find.byWidgetPredicate(
        (widget) => widget is Banner && widget.message == 'STAGING',
      ),
    );
    expect(banner.message, 'STAGING');
  });

  testWidgets('non-staging builds do not show a staging banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StagingBuildBanner(
          enabled: false,
          child: Scaffold(body: Text('Everywear')),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Banner && widget.message == 'STAGING',
      ),
      findsNothing,
    );
    expect(find.text('Everywear'), findsOneWidget);
  });
}
