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
      final expectedLearningErrors = <String, String>{
        'en':
            'Could not load your learning progress. Check your connection and try again.',
        'fr':
            'Impossible de charger votre progression. Vérifiez votre connexion et réessayez.',
        'es':
            'No se pudo cargar tu progreso de aprendizaje. Comprueba tu conexión e inténtalo de nuevo.',
      };
      final expectedCompletionLabels = <String, String>{
        'en': 'Mark Module Complete',
        'fr': 'Terminer le module',
        'es': 'Marcar módulo como completado',
      };
      final expectedProgressSaveErrors = <String, String>{
        'en': 'Could not save module progress. Please try again.',
        'fr': 'Impossible d’enregistrer la progression. Veuillez réessayer.',
        'es': 'No se pudo guardar el progreso del módulo. Inténtalo de nuevo.',
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
        expect(
          localizations.failedToLoadLearning,
          expectedLearningErrors[locale.languageCode],
          reason: 'learning error locale ${locale.languageCode}',
        );
        expect(
          localizations.markModuleComplete,
          expectedCompletionLabels[locale.languageCode],
          reason: 'module completion locale ${locale.languageCode}',
        );
        expect(
          localizations.failedToSaveModuleProgress,
          expectedProgressSaveErrors[locale.languageCode],
          reason: 'module save error locale ${locale.languageCode}',
        );
      }
    });
  });
}
