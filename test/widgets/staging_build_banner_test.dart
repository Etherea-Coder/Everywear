import 'package:everywear/widgets/staging_build_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the painted staging banner only when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: StagingBuildBanner(enabled: true, child: Text('App')),
        ),
      ),
    );

    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'STAGING');
    expect(find.text('STAGING'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: StagingBuildBanner(enabled: false, child: Text('App')),
        ),
      ),
    );
    expect(find.byType(Banner), findsNothing);
  });
}
