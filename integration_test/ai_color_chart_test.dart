import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:everywear/core/utils/app_localizations.dart';
import 'package:everywear/core/providers.dart';
import 'package:everywear/presentation/ai_intelligence/ai_intelligence.dart';
import 'package:everywear/presentation/ai_intelligence/widgets/style_trends_card_widget.dart';
import 'package:everywear/services/supabase_service.dart';
import 'package:everywear/theme/app_theme.dart';

const _smokeChannel = MethodChannel('com.everywear/ui_smoke_test');
const _approvedProjectHost = 'aftdbphdobfrshienple.supabase.co';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'staging French insights chart displays the canonical synthetic color',
    (tester) async {
      if (!const bool.fromEnvironment('EVERYWEAR_STAGING') ||
          !const bool.fromEnvironment('EVERYWEAR_STAGING_TEST') ||
          const bool.fromEnvironment('EVERYWEAR_ADS_ENABLED') ||
          const String.fromEnvironment('APP_DISTRIBUTION') != 'uptodown' ||
          const String.fromEnvironment('REVENUECAT_BILLING_ENVIRONMENT') !=
              'unavailable') {
        throw StateError(
          'Refusing to run outside the guarded staging test build.',
        );
      }
      if (Uri.parse(SupabaseService.cleanSupabaseUrl).host !=
          _approvedProjectHost) {
        throw StateError('Refusing a non-staging Supabase project.');
      }

      final initialized = await SupabaseService.initialize();
      expect(initialized, isTrue, reason: 'staging Supabase initializes');
      final client = Supabase.instance.client;
      expect(client.auth.currentUser, isNull);

      final credentials = await _smokeChannel.invokeMapMethod<String, dynamic>(
        'consumeStagingSmokeLoginCredentials',
      );
      final email = credentials?['email'];
      final password = credentials?['password'];
      if (email is! String ||
          password is! String ||
          email.isEmpty ||
          password.isEmpty) {
        throw StateError('Private staging test credentials are unavailable.');
      }
      await client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 30));
      expect(client.auth.currentUser, isNotNull);

      final accountId = client.auth.currentUser!.id;
      final rows = await client
          .from('wardrobe_items')
          .select('semantic_label,brand')
          .eq('user_id', accountId)
          .eq('brand', 'Everywear synthetic QA')
          .like('name', 'SYNTHETIC FRENCH COLOR TEST TOP%')
          .order('created_at', ascending: false)
          .limit(1);
      expect(
        rows,
        isNotEmpty,
        reason: 'The synthetic analyzed item was saved.',
      );
      final semanticLabel = rows.first['semantic_label'] as String? ?? '';
      expect(
        semanticLabel.split(RegExp(r'\s+')).first,
        'blue',
        reason: 'Persisted machine-readable color is canonical English.',
      );

      final allowance = await client.rpc('get_ai_allowance');
      final allowanceMap = allowance is List ? allowance.first : allowance;
      expect(allowanceMap, isA<Map<String, dynamic>>());
      final values = Map<String, dynamic>.from(allowanceMap as Map);
      expect(values['month_remaining'], greaterThanOrEqualTo(1));
      expect(values['day_remaining'], greaterThanOrEqualTo(1));
      expect(values['burst_remaining'], greaterThanOrEqualTo(1));

      final container = ProviderContainer();
      container.read(localeProvider.notifier).state = const Locale('fr');
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Sizer(
            builder: (context, orientation, screenType) => MaterialApp(
              locale: const Locale('fr'),
              theme: AppTheme.lightTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AIIntelligence(),
            ),
          ),
        ),
      );

      final chart = find.byType(StyleTrendsCardWidget);
      await _waitUntil(
        tester,
        () => chart.evaluate().isNotEmpty,
        reason: 'AI insights chart mount',
      );
      await _waitUntil(
        tester,
        () => find
            .descendant(of: chart, matching: find.text('Bleu'))
            .evaluate()
            .isNotEmpty,
        reason: 'French localization of canonical Blue in the chart',
        timeout: const Duration(seconds: 120),
      );

      final chartWidget = tester.widget<StyleTrendsCardWidget>(chart);
      expect(chartWidget.dominantColors, contains('Blue'));
      expect(
        find.descendant(of: chart, matching: find.text('Bleu')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chart, matching: find.text('Blue')),
        findsNothing,
      );
      // ignore: avoid_print
      print(
        'PASS: synthetic saved color=blue; chart source=Blue; French label=Bleu',
      );

      final after = await client.rpc('get_ai_allowance');
      final afterMap = after is List ? after.first : after;
      final afterValues = Map<String, dynamic>.from(afterMap as Map);
      expect(afterValues['month_remaining'], values['month_remaining'] - 1);
      expect(afterValues['day_remaining'], values['day_remaining'] - 1);
      // ignore: avoid_print
      print('PASS: insights chart used one authenticated quota action');
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  throw TestFailure('Timed out waiting for $reason.');
}
