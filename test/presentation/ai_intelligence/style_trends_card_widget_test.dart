import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/ai_intelligence/widgets/style_trends_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

void main() {
  for (final (locale, label) in [
    (const Locale('fr'), 'Bleu'),
    (const Locale('es'), 'Azul'),
  ]) {
    testWidgets('canonical Blue renders $label in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, screenType) => MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: StyleTrendsCardWidget(
                dominantColors: ['Blue'],
                colorPercentages: [100],
                silhouetteEvolution: [],
                emergingStyles: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StyleTrendsCardWidget), findsOneWidget);
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(find.text(label), findsOneWidget);
      expect(find.text('Blue'), findsNothing);
      expect(find.text('100%'), findsOneWidget);
    });
  }
}
