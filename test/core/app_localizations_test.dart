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
      final expectedAuthServiceUnavailable = <String, String>{
        'en':
            'Account services are unavailable right now. Please try again later.',
        'fr':
            'Les services de compte sont indisponibles. Veuillez réessayer plus tard.',
        'es':
            'Los servicios de cuenta no están disponibles ahora. Inténtalo de nuevo más tarde.',
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
      final expectedAiAllowance = <String, String>{
        'en': '4 AI actions left this month',
        'fr': '4 actions IA restantes ce mois-ci',
        'es': 'Quedan 4 acciones de IA este mes',
      };
      final expectedAiUnavailable = <String, String>{
        'en': 'AI is unavailable right now. You can continue without AI.',
        'fr':
            'Le service IA n’est pas disponible actuellement. Vous pouvez continuer sans IA.',
        'es': 'La IA no está disponible ahora. Puedes continuar sin IA.',
      };
      final expectedFreeBetaPaymentsUnavailable = <String, String>{
        'en': 'Purchases are disabled in this free beta.',
        'fr': 'Les achats sont désactivés dans cette bêta gratuite.',
        'es': 'Las compras están desactivadas en esta beta gratuita.',
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
          localizations.authServiceUnavailable,
          expectedAuthServiceUnavailable[locale.languageCode],
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
        expect(
          localizations.aiAllowanceRemaining(4),
          expectedAiAllowance[locale.languageCode],
          reason: 'AI allowance locale ${locale.languageCode}',
        );
        expect(
          localizations.aiServiceUnavailable,
          expectedAiUnavailable[locale.languageCode],
          reason: 'AI unavailable locale ${locale.languageCode}',
        );
        expect(
          localizations.freeBetaPurchasesUnavailable,
          expectedFreeBetaPaymentsUnavailable[locale.languageCode],
          reason: 'free beta payments locale ${locale.languageCode}',
        );
        expect(
          localizations.aiStatusMessage('AI_LIMIT_DAILY'),
          localizations.aiAllowanceExhausted,
        );
        expect(
          localizations.aiStatusMessage('AI_UNAVAILABLE'),
          localizations.aiServiceUnavailable,
        );
      }
    });
  });
}
