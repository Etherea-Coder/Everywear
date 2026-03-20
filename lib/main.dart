import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './core/utils/app_localizations.dart';
import './core/utils/locale_manager.dart';
import './core/providers.dart';
import './services/supabase_service.dart';
import './services/revenuecat_service.dart';
import './services/notification_service.dart';
import './services/analytics_service.dart';
import './widgets/custom_error_widget.dart';
import './presentation/home_screen/home_screen.dart';
import './presentation/splash_screen/splash_screen.dart';
import 'core/app_export.dart';
import './ads/ad_service.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  bool _hasShownError = false;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;
      Sentry.captureException(details.exception, stackTrace: details.stack);
      Future.delayed(const Duration(seconds: 5), () => _hasShownError = false);
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initial service bootstrapper - Critical services first
  await _initializeEssentialServices();

  // ✅ NEW: Initialize Ad Service
  await AdService.instance.initialize(testMode: !kReleaseMode);

  // Run the app after critical services are ready
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // Initialize remaining non-critical services in the background
  _initializeBackgroundServices();
}

// Essential services that the UI depends on immediately
Future<void> _initializeEssentialServices() async {
  // Sentry tracking first
  try {
    await SentryFlutter.init((options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = kDebugMode ? 0.0 : 1.0;
      options.debug = kDebugMode;
    });
  } catch (e) {
    debugPrint('⚠️ Sentry failed to init: $e');
  }

  // Initialize Supabase and Hive sequentially to ensure stability
  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('⚠️ Essential service Supabase failed to init: $e');
  }

  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('⚠️ Essential service Hive failed to init: $e');
  }
}

// Non-critical services that can load while splash screen is showing
Future<void> _initializeBackgroundServices() async {
  try {
    await RevenueCatService.initialize().timeout(const Duration(seconds: 10)).catchError((_) {});
  } catch (e) {
    debugPrint('⚠️ RevenueCat failed to init: $e');
  }

  // Log in to RevenueCat if user already has active session
  try {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user != null) {
      await RevenueCatService.logIn(user.id).timeout(const Duration(seconds: 5)).catchError((_) {});
    }
  } catch (e) {
    debugPrint('⚠️ RevenueCat login failed: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends ConsumerState<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final results = await Future.wait([
        LocaleManager.getSavedLocale(),
        LocaleManager.getSavedThemeMode(),
      ]).timeout(const Duration(seconds: 2), onTimeout: () => [null, 'light']);

      final savedLocale = results[0] as Locale?;
      final savedTheme = results[1] as String;

      if (mounted) {
        setState(() {
          _locale = savedLocale ?? const Locale('en');
          _themeMode = _parseThemeMode(savedTheme);
          _isInitialized = true;
        });
        ref.read(themeModeProvider.notifier).state = _themeMode;
        ref.read(localeProvider.notifier).state = _locale!;
        await NotificationService.instance.restoreIfEnabled();
        await AnalyticsService.instance.applyStoredPreference();
      }
    } catch (e) {
      debugPrint('⚠️ App initialization failed: $e');
      if (mounted) {
        setState(() {
          _locale = const Locale('en');
          _themeMode = ThemeMode.light;
          _isInitialized = true;
        });
      }
    }
  }

  ThemeMode _parseThemeMode(String theme) {
    switch (theme.toLowerCase()) {
      case 'dark':   return ThemeMode.dark;
      case 'system':
      case 'auto':   return ThemeMode.system;
      case 'light':
      default:       return ThemeMode.light;
    }
  }

  void updateLocale(Locale locale) {
    if (_locale?.languageCode != locale.languageCode) {
      setState(() => _locale = locale);
      ref.read(localeProvider.notifier).state = locale;
    }
  }

  void updateThemeMode(String theme) {
    final newThemeMode = _parseThemeMode(theme);
    if (_themeMode != newThemeMode) {
      setState(() => _themeMode = newThemeMode);
      ref.read(themeModeProvider.notifier).state = newThemeMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show plain loader until locale is ready
    if (!_isInitialized || _locale == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF2D5A27),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    'assets/images/icon-1768225114910.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    final authState = ref.watch(authStateProvider);

    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          key: ValueKey(_locale!.languageCode + _themeMode.toString()),
          title: 'everywear',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return supportedLocales.first;
          },
          home: authState.when(
            data: (state) {
              final hasSession = state.session != null;
              return hasSession ? const HomeScreen() : const SplashScreen();
            },
            // During loading, check current session directly —
            // avoids rebuilding SplashScreen and resetting the login form
            loading: () {
              final hasSession = SupabaseService
                  .instance.client.auth.currentSession != null;
              return hasSession
                  ? const HomeScreen()
                  : const SplashScreen();
            },
            error: (_, __) => const SplashScreen(),
          ),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}