import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/splash_screen/splash_screen.dart';
import 'package:everywear/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:everywear/core/providers.dart';
import 'package:everywear/core/utils/locale_manager.dart';
import 'package:everywear/services/ai_locale_context.dart';

const _unavailableMessage =
    'Account services are unavailable right now. Please try again later.';

Future<void> _pumpSplash(
  WidgetTester tester, {
  Locale initialLocale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localeProvider.overrideWith((ref) => initialLocale)],
      child: Consumer(
        builder: (context, ref, _) => Sizer(
          builder: (context, orientation, deviceType) => MaterialApp(
            locale: ref.watch(localeProvider),
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
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('French device fallback reaches the welcome UI and AI request', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final initialLocale = LocaleManager.resolveInitialLocale(
      await LocaleManager.getSavedLocale(),
      const Locale('fr', 'FR'),
    );
    await _pumpSplash(tester, initialLocale: initialLocale);

    expect(find.text('Comprenez votre style'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    final visibleLocale = Localizations.localeOf(
      tester.element(find.byType(SplashScreen)),
    );
    expect(AiLocaleContext.styleCoach(visibleLocale)['responseLocale'], 'fr');
    expect(AiLocaleContext.suggestions(visibleLocale)['language'], 'FR');
    expect(
      AiLocaleContext.proseResponse(visibleLocale)['responseLocale'],
      'fr',
    );

    await tester.tap(find.byKey(const Key('welcome-language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsWidgets);
  });

  testWidgets('saved Spanish beats French device for UI and AI requests', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'es'});
    final initialLocale = LocaleManager.resolveInitialLocale(
      await LocaleManager.getSavedLocale(),
      const Locale('fr', 'FR'),
    );
    await _pumpSplash(tester, initialLocale: initialLocale);

    expect(find.text('Entiende Tu Estilo'), findsOneWidget);
    final visibleLocale = Localizations.localeOf(
      tester.element(find.byType(SplashScreen)),
    );
    expect(AiLocaleContext.styleCoach(visibleLocale)['responseLocale'], 'es');
    expect(AiLocaleContext.suggestions(visibleLocale)['language'], 'ES');
    expect(
      AiLocaleContext.proseResponse(visibleLocale)['responseLocale'],
      'es',
    );

    await tester.tap(find.byKey(const Key('welcome-language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Español'), findsWidgets);
  });

  testWidgets('changing language changes later AI request locale immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
    await _pumpSplash(tester, initialLocale: const Locale('fr'));

    Locale requestLocale() =>
        Localizations.localeOf(tester.element(find.byType(SplashScreen)));

    expect(AiLocaleContext.styleCoach(requestLocale())['responseLocale'], 'fr');
    await tester.tap(find.byKey(const Key('welcome-language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    expect(find.text('Entiende Tu Estilo'), findsOneWidget);
    expect(AiLocaleContext.styleCoach(requestLocale())['responseLocale'], 'es');
    expect(AiLocaleContext.suggestions(requestLocale())['language'], 'ES');
    expect(
      AiLocaleContext.proseResponse(requestLocale())['responseLocale'],
      'es',
    );
  });

  testWidgets('language can change before login and persists for restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpSplash(tester);

    expect(SupabaseService.isInitialized, isFalse);
    await tester.tap(find.byKey(const Key('welcome-language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();

    expect(find.text('Comprenez votre style'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(await LocaleManager.getSavedLocale(), const Locale('fr'));

    await _tapVisible(tester, find.text('Continuer avec email'));
    expect(find.text('Bon retour'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome-language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(await LocaleManager.getSavedLocale(), const Locale('es'));
    expect(
      LocaleManager.resolveInitialLocale(
        await LocaleManager.getSavedLocale(),
        const Locale('en'),
      ),
      const Locale('es'),
    );
  });

  test('fresh-install locale uses supported device language or English', () {
    expect(
      LocaleManager.resolveInitialLocale(null, const Locale('fr', 'FR')),
      const Locale('fr'),
    );
    expect(
      LocaleManager.resolveInitialLocale(null, const Locale('de', 'DE')),
      const Locale('en'),
    );
    expect(
      LocaleManager.resolveInitialLocale(
        const Locale('es'),
        const Locale('fr'),
      ),
      const Locale('es'),
    );
  });

  testWidgets('welcome controls fit a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpSplash(tester, textScale: 1.8);

    expect(find.byKey(const Key('welcome-language-selector')), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash logo loads as a raster asset', (tester) async {
    await _pumpSplash(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google sign-in fails clearly when Supabase is unconfigured', (
    tester,
  ) async {
    await _pumpSplash(tester);
    expect(SupabaseService.isInitialized, isFalse);

    await _tapVisible(tester, find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(_unavailableMessage), findsOneWidget);
    expect(SupabaseService.isInitialized, isFalse);
  });

  testWidgets('password recovery fails clearly when Supabase is unconfigured', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await _tapVisible(tester, find.text('Continue with Email'));
    final emailField = find.byType(TextFormField).first;
    await tester.ensureVisible(emailField);
    await tester.pump();
    await tester.enterText(emailField, 'reader@example.com');
    await _tapVisible(tester, find.text('Forgot Password?'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(_unavailableMessage), findsOneWidget);
    expect(SupabaseService.isInitialized, isFalse);
  });

  testWidgets('email sign-in fails clearly when Supabase is unconfigured', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await _tapVisible(tester, find.text('Continue with Email'));
    final emailField = find.byType(TextFormField).first;
    await tester.ensureVisible(emailField);
    await tester.pump();
    await tester.enterText(emailField, 'reader@example.com');
    final passwordField = find.byType(TextFormField).last;
    await tester.ensureVisible(passwordField);
    await tester.pump();
    await tester.enterText(passwordField, 'not-a-real-password');
    await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(_unavailableMessage), findsOneWidget);
    expect(SupabaseService.isInitialized, isFalse);
  });
}
