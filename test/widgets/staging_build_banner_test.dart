import 'package:everywear/widgets/staging_build_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows normal staging ribbon when enabled', (tester) async {
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

  testWidgets('test app has a persistent full-width identity marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: StagingBuildBanner(
            enabled: true,
            testBuild: true,
            child: Text('App'),
          ),
        ),
      ),
    );

    final marker = tester.widget<Text>(
      find.text('AUTOMATED TEST APP  •  STAGING'),
    );
    expect(marker.style?.fontSize, 15);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('automated_staging_test_identity')),
          )
          .height,
      44,
    );
    expect(find.byType(Banner), findsNothing);
    expect(find.text('App'), findsOneWidget);
  });
}
