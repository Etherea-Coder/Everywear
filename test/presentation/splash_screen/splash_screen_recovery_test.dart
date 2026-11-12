import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/presentation/splash_screen/splash_screen.dart';
import 'package:everywear/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

const _unavailableMessage =
    'Account services are unavailable right now. Please try again later.';

Future<void> _pumpSplash(WidgetTester tester) async {
  await tester.pumpWidget(
    Sizer(
      builder: (context, orientation, deviceType) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
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
