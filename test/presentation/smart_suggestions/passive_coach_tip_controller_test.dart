import 'dart:async';

import 'package:everywear/presentation/smart_suggestions/passive_coach_tip_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'locale change waits for explicit refresh and requests new language',
    () async {
      final requestedLocales = <String>[];
      final controller = PassiveCoachTipController(
        locale: const Locale('en'),
        requestTip: (locale) async {
          requestedLocales.add(locale.languageCode);
          return 'Tip in ${locale.languageCode}';
        },
      );
      addTearDown(controller.dispose);

      await controller.loadInitial();
      expect(requestedLocales, ['en']);
      expect(controller.tip, 'Tip in en');

      controller.updateLocale(const Locale('fr'));
      expect(requestedLocales, ['en']);
      expect(controller.tip, isNull);
      expect(controller.needsRefresh, isTrue);

      await controller.refresh();
      expect(requestedLocales, ['en', 'fr']);
      expect(controller.tip, 'Tip in fr');
      expect(controller.needsRefresh, isFalse);
    },
  );

  test(
    'late response from the previous locale cannot replace refreshed tip',
    () async {
      final oldResponse = Completer<String?>();
      final requestedLocales = <String>[];
      final controller = PassiveCoachTipController(
        locale: const Locale('en'),
        requestTip: (locale) {
          requestedLocales.add(locale.languageCode);
          if (locale.languageCode == 'en') return oldResponse.future;
          return Future.value('Conseil français');
        },
      );
      addTearDown(controller.dispose);

      final oldRequest = controller.loadInitial();
      expect(requestedLocales, ['en']);

      controller.updateLocale(const Locale('fr'));
      await controller.refresh();
      expect(requestedLocales, ['en', 'fr']);
      expect(controller.tip, 'Conseil français');

      oldResponse.complete('Old English tip');
      await oldRequest;
      expect(controller.tip, 'Conseil français');
      expect(controller.isLoading, isFalse);
    },
  );
}
