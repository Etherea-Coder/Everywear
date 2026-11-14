import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/personalization_setup/widgets/wardrobe_upload_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('optional photo tile grows for larger text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, screenType) => MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('Personalize Your Experience')),
            body: Column(
              children: [
                const SizedBox(height: 52),
                Expanded(
                  child: WardrobeUploadStep(
                    photos: const [],
                    onPhotosChanged: (_) {},
                    onSkip: () {},
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
