import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/outfit_capture_flow/widgets/outfit_confirmation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

Widget _testApp(Widget child) {
  return Sizer(
    builder: (context, orientation, screenType) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('resolves the stable image_ref in wardrobe confirmation', (
    tester,
  ) async {
    final references = <String>[];

    await tester.pumpWidget(
      _testApp(
        OutfitConfirmationWidget(
          selectedItems: [
            {
              'id': 'item-1',
              'name': 'Synthetic Tee',
              'category': 'Tops',
              'image_ref': 'wardrobe-images/user-1/synthetic.png',
            },
          ],
          captureMethod: 'wardrobe',
          onConfirm: (_, _) {},
          onRetake: () {},
          storageUrlResolver: (reference) async {
            references.add(reference);
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(references, contains('wardrobe-images/user-1/synthetic.png'));
    expect(find.text('Synthetic Tee'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps compatibility with image_url and legacy image fields', (
    tester,
  ) async {
    final references = <String>[];

    await tester.pumpWidget(
      _testApp(
        OutfitConfirmationWidget(
          selectedItems: [
            {
              'id': 'item-url',
              'name': 'URL Tee',
              'image_url': 'wardrobe-images/user-1/url.png',
            },
            {
              'id': 'item-legacy',
              'name': 'Legacy Tee',
              'image': 'wardrobe-images/user-1/legacy.png',
            },
          ],
          captureMethod: 'wardrobe',
          onConfirm: (_, _) {},
          onRetake: () {},
          storageUrlResolver: (reference) async {
            references.add(reference);
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      references,
      containsAll([
        'wardrobe-images/user-1/url.png',
        'wardrobe-images/user-1/legacy.png',
      ]),
    );
    expect(tester.takeException(), isNull);
  });
}
