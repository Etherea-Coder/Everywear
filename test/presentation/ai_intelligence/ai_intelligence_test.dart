import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:everywear/core/providers.dart';
import 'package:everywear/presentation/ai_intelligence/ai_intelligence.dart';

void main() {
  group('AIIntelligence Widget', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
              home: const AIIntelligence(),
            );
          },
        ),
      );
    }

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('AI Intelligence'), findsOneWidget);
    });

    testWidgets('renders time range selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Season'), findsOneWidget);
    });

    testWidgets('renders generate insights button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Generate New Insights'), findsOneWidget);
    });

    testWidgets('tapping time range chip updates provider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(home: const AIIntelligence());
          },
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(container.read(aiIntelligenceTimeRangeProvider), 'week');
    });
  });
}
