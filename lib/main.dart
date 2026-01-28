import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import './core/utils/app_localizations.dart';
import './core/utils/locale_manager.dart';
import './core/providers.dart';
import './services/payment_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import './presentation/home_screen/home_screen.dart';
import './presentation/splash_screen/splash_screen.dart';
import 'core/app_export.dart';

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
      options.dsn = 'https://2042b302417e66a6d6e0e4814a7de53c@o4510754518138880.ingest.de.sentry.io/4510754526789712';
      options.tracesSampleRate = 1.0;
      options.debug = kDebugMode;
    });
  } catch (_) {}

  // Initialize Supabase and Hive sequentially to ensure stability
  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    print('⚠️ Essential service Supabase failed to init: $e');
  }

  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 5));
  } catch (e) {
    print('⚠️ Essential service Hive failed to init: $e');
  }
}

// Non-critical services that can load while splash screen is showing
Future<void> _initializeBackgroundServices() async {
  try {
    await PaymentService.initialize().timeout(const Duration(seconds: 10)).catchError((_) {});
  } catch (_) {}
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
  bool _showBrandedLoader = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // Safety timeout: Never show the branded loader for more than 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showBrandedLoader) {
        setState(() => _showBrandedLoader = false);
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // SharedPreferences often hangs on poor hardware - 2s limit
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
          // If we finished loading locale, we can potentially hide the branded loader
          // but we still wait for auth if it's very fast (handled by the builder logic)
        });
        
        ref.read(themeModeProvider.notifier).state = _themeMode;
        ref.read(localeProvider.notifier).state = _locale!;
      }
    } catch (_) {
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
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      case 'auto':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  /// Public method to update locale and force complete app rebuild
  void updateLocale(Locale locale) {
    if (_locale?.languageCode != locale.languageCode) {
      setState(() {
        _locale = locale;
      });
      ref.read(localeProvider.notifier).state = locale;
    }
  }

  /// Public method to update theme mode and force complete app rebuild
  void updateThemeMode(String theme) {
    final newThemeMode = _parseThemeMode(theme);
    if (_themeMode != newThemeMode) {
      setState(() {
        _themeMode = newThemeMode;
      });
      ref.read(themeModeProvider.notifier).state = newThemeMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show branded loading screen until locale and auth are loaded
    final authState = ref.watch(authStateProvider);

    // ROBUST BUILD LOGIC:
    // Only show the branded loader if:
    // 1. Initialized is false AND We haven't hit our safety timeout
    // OR 
    // 2. Locale is missing AND We haven't hit our safety timeout
    // OR
    // 3. Auth is specifically LOADING AND We haven't hit our safety timeout
    final stillLoading = !_isInitialized || _locale == null || authState.isLoading;

    if (_showBrandedLoader && stillLoading) {
      debugPrint('📱 Showing branded loader - initialized: $_isInitialized, locale: $_locale, authLoading: ${authState.isLoading}');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF2D5A27), // Branded Primary Light
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
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          // Localization configuration
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
          // Determine home based on auth state
          home: authState.when(
            data: (state) {
              final hasSession = state.session != null;
              debugPrint('🏠 Navigation decision: hasSession=$hasSession, event=${state.event}');
              if (hasSession) {
                return HomeScreen(); 
              }
              return SplashScreen();
            },
            loading: () {
              debugPrint('⏳ Auth state loading, showing SplashScreen');
              return SplashScreen(); 
            },
            error: (error, stack) {
              debugPrint('❌ Auth state error: $error, showing SplashScreen');
              return SplashScreen();
            },
          ),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}