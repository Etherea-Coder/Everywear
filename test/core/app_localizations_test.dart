import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/utils/app_localizations.dart';

void main() {
  group('AppLocalizations auth strings', () {
    test(
      'loads the forgot password label for every supported locale',
      () async {
        final expectedLabels = <String, String>{
          'en': 'Forgot Password?',
          'fr': 'Mot de passe oublié?',
          'es': '¿Olvidaste tu contraseña?',
        };

        for (final locale in AppLocalizations.supportedLocales) {
          final localizations = AppLocalizations(locale);
          await localizations.load();
          expect(
            localizations.forgotPassword,
            expectedLabels[locale.languageCode],
            reason: 'locale ${locale.languageCode}',
          );
        }
      },
    );
  });
}
