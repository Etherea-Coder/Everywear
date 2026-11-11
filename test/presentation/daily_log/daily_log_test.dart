import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:everywear/presentation/daily_log/widgets/empty_daily_log_widget.dart';
import 'package:everywear/presentation/daily_log/widgets/quick_log_button_widget.dart';

void main() {
  group('EmptyDailyLogWidget', () {
    testWidgets('shows empty state message', (tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, screenType) {
            return const MaterialApp(
              home: Scaffold(body: EmptyDailyLogWidget()),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No outfits logged for this day'), findsOneWidget);
      expect(find.text('Tap the + button to log your outfit'), findsOneWidget);
    });
  });

  group('QuickLogButtonWidget', () {
    testWidgets('renders FAB with add icon', (tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
              home: Scaffold(
                body: QuickLogButtonWidget(
                  onQuickLog: () {},
                  onFullLog: () {},
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onQuickLog when tapped', (tester) async {
      var quickLogCalled = false;
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
              home: Scaffold(
                body: QuickLogButtonWidget(
                  onQuickLog: () => quickLogCalled = true,
                  onFullLog: () {},
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(quickLogCalled, true);
    });
  });

}
