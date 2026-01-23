import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import './core/utils/app_localizations.dart';
import './core/utils/locale_manager.dart';
import './core/providers.dart';
import './services/payment_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize services with a timeout to avoid hanging the app start
    final initFuture = _initializeAllServices();
    
    // We don't await initFuture here to ensure Sentry and runApp start immediately
    // but we can monitor it later if needed.
    
    // Initialize Sentry and run the app
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://2042b302417e66a6d6e0e4814a7de53c@o4510754518138880.ingest.de.sentry.io/4510754526789712';
        options.tracesSampleRate = 1.0;
        options.debug = kDebugMode;
      },
      appRunner: () {
        bool _hasShownError = false;

        // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (!_hasShownError) {
            _hasShownError = true;

            // Report error to Sentry
            Sentry.captureException(details.exception,
                stackTrace: details.stack);

            // Reset flag after 5 seconds to allow error widget on new screens
            Future.delayed(const Duration(seconds: 5), () {
              _hasShownError = false;
            });

            return CustomErrorWidget(errorDetails: details);
          }
          return const SizedBox.shrink();
        };

        runApp(
          const ProviderScope(
            child: MyApp(),
          ),
        );
      },
    );
  } catch (e, stack) {
    if (kDebugMode) {
      print('Fatal error during startup: $e\n$stack');
    }
    // Final fallback to ensure something is rendered
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization Error: $e'),
          ),
        ),
      ),
    );
  }
}

/// Helper to initialize internal services without blocking the main event loop
Future<void> _initializeAllServices() async {
  // Initialize Supabase
  try {
    await SupabaseService.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    if (kDebugMode) {
      print('Supabase initialization failed: $e');
    }
  }

  // Initialize Stripe payment service
  try {
    await PaymentService.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    if (kDebugMode) {
      print('Stripe initialization failed: $e');
    }
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();

  /// Static method to access _MyAppState from anywhere in the widget tree
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

  /// Initialize app with saved settings before first build
  Future<void> _initializeApp() async {
    final savedLocale = await LocaleManager.getSavedLocale();
    final savedTheme = await LocaleManager.getSavedThemeMode();

    if (mounted) {
      setState(() {
        _locale = savedLocale ?? const Locale('en');
        _themeMode = _parseThemeMode(savedTheme);
        _isInitialized = true;
      });
      
      // Sync providers
      ref.read(themeModeProvider.notifier).state = _themeMode;
      ref.read(localeProvider.notifier).state = _locale!;
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
    // Show loading screen until locale is loaded
    if (!_isInitialized || _locale == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
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
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}