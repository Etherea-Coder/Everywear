import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/utils/app_localizations.dart';

void main() {
  group('AppLocalizations auth strings', () {
    test('loads the forgot password label for every supported locale', () async {
      final expectedLabels = <String, String>{
        'en': 'Forgot Password?',
        'fr': 'Mot de passe oublié?',
        'es': '¿Olvidaste tu contraseña?',
      };
      final expectedChallengeErrors = <String, String>{
        'en': 'Could not load challenges. Check your connection and try again.',
        'fr':
            'Impossible de charger les défis. Vérifiez votre connexion et réessayez.',
        'es':
            'No se pudieron cargar los desafíos. Comprueba tu conexión e inténtalo de nuevo.',
      };

      for (final locale in AppLocalizations.supportedLocales) {
        final localizations = AppLocalizations(locale);
        await localizations.load();
        expect(
          localizations.forgotPassword,
          expectedLabels[locale.languageCode],
          reason: 'locale ${locale.languageCode}',
        );
        expect(
          localizations.failedToLoadChallenges,
          expectedChallengeErrors[locale.languageCode],
          reason: 'challenge error locale ${locale.languageCode}',
        );
      }
    });
  });
}
