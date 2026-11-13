import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './core/utils/app_localizations.dart';
import './core/utils/locale_manager.dart';
import './core/providers.dart';
import './services/supabase_service.dart';
import './services/revenuecat_service.dart';
import './services/subscription_service.dart';
import './services/revenuecat_web_checkout.dart';
import './services/notification_service.dart';
import './services/analytics_service.dart';
import './widgets/custom_error_widget.dart';
import './widgets/staging_build_banner.dart';
import './widgets/startup_diagnostics.dart';
import './presentation/auth_gate.dart';
import 'core/app_export.dart';

const _isStagingBuild = bool.fromEnvironment(
  'EVERYWEAR_STAGING',
  defaultValue: false,
);

void main() {
  if (startupDiagnosticsEnabled) {
    runZonedGuarded<void>(
      _bootstrapAndRunApp,
      (error, stackTrace) => StartupDiagnostics.recordFailure(
        'Uncaught asynchronous startup',
        error,
        stackTrace: stackTrace,
      ),
    );
  } else {
    _bootstrapAndRunApp();
  }
}

void _bootstrapAndRunApp() {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  StartupDiagnostics.setStage('Dart entrypoint reached');

  if (startupDiagnosticsEnabled) {
    FlutterError.onError = (details) => StartupDiagnostics.recordFailure(
      'Flutter framework',
      details.exception,
      stackTrace: details.stack,
    );
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      StartupDiagnostics.recordFailure(
        'Uncaught platform error',
        error,
        stackTrace: stackTrace,
      );
      return true;
    };
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  bool _hasShownError = false;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (startupDiagnosticsEnabled) {
      StartupDiagnostics.recordFailure(
        'Flutter error widget',
        details.exception,
        stackTrace: details.stack,
      );
      return const StartupDiagnosticScreen();
    }
    if (!_hasShownError) {
      _hasShownError = true;
      if (AnalyticsService.instance.reportingEnabled) {
        unawaited(
          Sentry.captureException(details.exception, stackTrace: details.stack),
        );
      }
      Future.delayed(const Duration(seconds: 5), () => _hasShownError = false);
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // Keep the first Flutter frame independent of platform/service startup.
  // Android can otherwise remain on its native launch screen (or black) while
  // Sentry, Supabase, or Hive are still initializing.
  StartupDiagnostics.setStage('Setting screen orientation');
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).catchError((Object error, StackTrace stackTrace) {
      if (startupDiagnosticsEnabled) {
        StartupDiagnostics.recordFailure(
          'Screen orientation',
          error,
          stackTrace: stackTrace,
        );
      } else if (kDebugMode) {
        debugPrint('Unable to set device orientation: $error');
      }
    }),
  );

  final essentialServices = _initializeEssentialServices();
  runApp(
    ProviderScope(
      child: MyApp(
        startupServices: essentialServices,
        diagnosticMode: startupDiagnosticsEnabled,
      ),
    ),
  );

  // Non-critical billing initialization follows essential bootstrap and never
  // gates rendering. Free-beta builds short-circuit this service.
  essentialServices.then((_) => _initializeBackgroundServices()).catchError((
    Object error,
    StackTrace stackTrace,
  ) {
    if (startupDiagnosticsEnabled) {
      StartupDiagnostics.recordFailure(
        'Background services',
        error,
        stackTrace: stackTrace,
      );
    } else if (kDebugMode) {
      debugPrint('⚠️ Background services init failed: $error');
    }
  });
}

// Essential services that the UI depends on immediately
Future<void> _initializeEssentialServices() async {
  await _initializeReportingServices();
  await _initializeSupabaseService();
  await _initializeLocalStorage();
}

Future<void> _initializeReportingServices() async {
  StartupDiagnostics.setStage('Loading reporting preference');
  // Sentry tracking first
  try {
    await AnalyticsService.instance.isAnalyticsEnabled().timeout(
      const Duration(seconds: 2),
    );
    StartupDiagnostics.setStage('Starting error reporting');
    await SentryFlutter.init((options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = kDebugMode ? 0.0 : 1.0;
      options.debug = kDebugMode;
      options.beforeSend = (event, hint) =>
          AnalyticsService.instance.reportingEnabled ? event : null;
      options.beforeSendTransaction = (event, hint) =>
          AnalyticsService.instance.reportingEnabled ? event : null;
    }).timeout(const Duration(seconds: 5));
  } catch (e, stackTrace) {
    if (startupDiagnosticsEnabled) {
      StartupDiagnostics.recordFailure(
        'Reporting initialization',
        e,
        stackTrace: stackTrace,
      );
    } else if (kDebugMode) {
      debugPrint('⚠️ Sentry failed to init: $e');
    }
  }
}

Future<void> _initializeSupabaseService() async {
  StartupDiagnostics.setStage('Connecting to staging backend');
  try {
    final initialized = await SupabaseService.initialize().timeout(
      const Duration(seconds: 10),
    );
    if (!initialized && startupDiagnosticsEnabled) {
      StartupDiagnostics.recordUnavailable('Backend initialization');
    }
  } catch (e, stackTrace) {
    if (startupDiagnosticsEnabled) {
      StartupDiagnostics.recordFailure(
        'Backend initialization',
        e,
        stackTrace: stackTrace,
      );
    } else if (kDebugMode) {
      debugPrint('⚠️ Essential service Supabase failed to init: $e');
    }
  }
}

Future<void> _initializeLocalStorage() async {
  StartupDiagnostics.setStage('Opening local storage');
  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 5));
  } catch (e, stackTrace) {
    if (startupDiagnosticsEnabled) {
      StartupDiagnostics.recordFailure(
        'Local storage initialization',
        e,
        stackTrace: stackTrace,
      );
    } else if (kDebugMode) {
      debugPrint('⚠️ Essential service Hive failed to init: $e');
    }
  }
}

Future<void> initializeReportingForStartupProbe() =>
    _initializeReportingServices();

Future<void> initializeSupabaseForStartupProbe() =>
    _initializeSupabaseService();

Future<void> initializeLocalStorageForStartupProbe() =>
    _initializeLocalStorage();

List<String> get startupFailuresForProbe =>
    List.unmodifiable(StartupDiagnostics.state.value.failures);

ValueListenable<StartupDiagnosticState> get startupDiagnosticsForProbe =>
    StartupDiagnostics.state;

Widget createApplicationForStartupProbe() => ProviderScope(
  child: MyApp(startupServices: Future<void>.value(), diagnosticMode: true),
);

// Non-critical services that can load while splash screen is showing
Future<void> _initializeBackgroundServices() async {
  await RevenueCatService.initialize().timeout(const Duration(seconds: 10));

  final user = SupabaseService.instance.client.auth.currentUser;
  if (user != null) {
    await RevenueCatService.logIn(user.id).timeout(const Duration(seconds: 5));
  }
}

class MyApp extends ConsumerStatefulWidget {
  MyApp({
    Key? key,
    Future<void>? startupServices,
    bool? diagnosticMode,
    this.startupTimeout = const Duration(seconds: 30),
  }) : startupServices = startupServices ?? Future<void>.value(),
       diagnosticMode = diagnosticMode ?? startupDiagnosticsEnabled,
       super(key: key);

  final Future<void> startupServices;
  final bool diagnosticMode;
  final Duration startupTimeout;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;
  bool _startupFailed = false;
  bool _startupTimedOut = false;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  String? _activeBillingRefreshUserId;
  String? _queuedBillingRefreshUserId;
  String? _lastBillingReturnUri;
  DateTime? _lastBillingRefreshAt;
  String? _lastBillingRefreshUserId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_appLinkSubscription?.cancel());
    unawaited(_authStateSubscription?.cancel());
    super.dispose();
  }

  void _listenForSubscriptionRefresh() {
    if (!SupabaseService.isInitialized) return;
    final currentUserId = SupabaseService.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      // Supabase may emit initialSession before this widget subscribes.
      unawaited(
        _refreshSubscriptionFromBackend(currentUserId, showFeedback: false),
      );
    }
    _authStateSubscription = SupabaseService
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen((state) {
          if (!SubscriptionService.shouldVerifyEntitlementForAuthEvent(
            state.event,
          )) {
            return;
          }
          final userId = state.session?.user.id;
          if (userId != null) {
            unawaited(
              _refreshSubscriptionFromBackend(userId, showFeedback: false),
            );
          }
        });
  }

  Future<void> _listenForBillingReturn() async {
    try {
      _appLinkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => unawaited(_handleBillingReturnUri(uri)),
        onError: (Object error) {
          if (kDebugMode) debugPrint('App link stream error: $error');
        },
      );
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) await _handleBillingReturnUri(initialUri);
    } catch (error) {
      if (kDebugMode) debugPrint('Unable to listen for app links: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !SupabaseService.isInitialized) {
      return;
    }
    final currentUserId = SupabaseService.instance.client.auth.currentUser?.id;
    final pendingUserId = RevenueCatWebCheckout.shared.takePendingUserId(
      currentUserId,
    );
    if (pendingUserId != null) {
      unawaited(_refreshSubscriptionFromBackend(pendingUserId));
    }
  }

  Future<void> _handleBillingReturnUri(Uri uri) async {
    if (!SupabaseService.isInitialized) return;
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    final linkValue = uri.toString();
    if (userId == null ||
        !RevenueCatWebCheckout.isBillingReturnFor(uri, userId) ||
        (_lastBillingReturnUri == linkValue &&
            _lastBillingRefreshAt != null &&
            DateTime.now().difference(_lastBillingRefreshAt!) <
                const Duration(seconds: 5))) {
      return;
    }
    _lastBillingReturnUri = linkValue;
    RevenueCatWebCheckout.shared.takePendingUserId(userId);
    await _refreshSubscriptionFromBackend(userId);
  }

  Future<void> _refreshSubscriptionFromBackend(
    String expectedUserId, {
    bool showFeedback = true,
  }) async {
    if (_activeBillingRefreshUserId == expectedUserId) return;
    if (_lastBillingRefreshUserId == expectedUserId &&
        _lastBillingRefreshAt != null &&
        DateTime.now().difference(_lastBillingRefreshAt!) <
            const Duration(seconds: 5)) {
      return;
    }
    if (_activeBillingRefreshUserId != null) {
      _queuedBillingRefreshUserId = expectedUserId;
      return;
    }

    String? userId = expectedUserId;
    try {
      while (userId != null) {
        _activeBillingRefreshUserId = userId;
        _lastBillingRefreshUserId = userId;
        _lastBillingRefreshAt = DateTime.now();
        var result = const SubscriptionActionResult(
          SubscriptionActionStatus.verificationFailed,
        );
        try {
          result = await SubscriptionService().verifyHostedCheckoutReturn(
            userId,
          );
        } catch (error) {
          if (kDebugMode) {
            debugPrint('Unable to refresh subscription status: $error');
          }
        } finally {
          if (mounted &&
              SupabaseService.instance.client.auth.currentUser?.id == userId) {
            ref.invalidate(userTierProvider);
            ref.invalidate(userProfileProvider);
          }
        }
        if (showFeedback &&
            mounted &&
            _isInitialized &&
            SupabaseService.instance.client.auth.currentUser?.id == userId) {
          final l10n = AppLocalizations.of(context);
          final message = switch (result.status) {
            SubscriptionActionStatus.success => l10n.subscriptionStatusVerified,
            SubscriptionActionStatus.noEntitlement =>
              l10n.subscriptionNotVerified,
            _ => l10n.subscriptionStatusCouldNotRefresh,
          };
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        final nextUserId = _queuedBillingRefreshUserId;
        _queuedBillingRefreshUserId = null;
        userId = nextUserId == _activeBillingRefreshUserId ? null : nextUserId;
      }
    } finally {
      _activeBillingRefreshUserId = null;
      _queuedBillingRefreshUserId = null;
    }
  }

  Future<void> _initializeApp() async {
    try {
      StartupDiagnostics.setStage('Waiting for core services');
      if (widget.diagnosticMode) {
        await widget.startupServices.timeout(widget.startupTimeout);
      } else {
        await widget.startupServices;
      }
      if (!mounted) return;
      // Attach listeners only after Supabase bootstrap, while checking the
      // current session handles an initial auth event emitted before listen.
      unawaited(_listenForBillingReturn());
      _listenForSubscriptionRefresh();

      StartupDiagnostics.setStage('Loading saved app preferences');
      final preferenceReads = Future.wait([
        LocaleManager.getSavedLocale(),
        LocaleManager.getSavedThemeMode(),
      ]);
      final results = widget.diagnosticMode
          ? await preferenceReads.timeout(const Duration(seconds: 2))
          : await preferenceReads.timeout(
              const Duration(seconds: 2),
              onTimeout: () => [null, 'light'],
            );

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
        StartupDiagnostics.setStage('Restoring optional settings');
        await NotificationService.instance.restoreIfEnabled();
        await AnalyticsService.instance.applyStoredPreference();
        StartupDiagnostics.setStage('App ready');
      }
    } catch (e, stackTrace) {
      if (widget.diagnosticMode) {
        StartupDiagnostics.recordFailure(
          'Application startup',
          e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          setState(() {
            _startupFailed = true;
            _startupTimedOut = e is TimeoutException;
          });
        }
        return;
      }
      if (kDebugMode) debugPrint('⚠️ App initialization failed: $e');
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
      if (widget.diagnosticMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          home: StartupDiagnosticScreen(
            timedOut: _startupTimedOut,
            startupFailed: _startupFailed,
            timeoutDuration: widget.startupTimeout,
          ),
        );
      }
      return MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
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

    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          key: ValueKey(_locale!.languageCode + _themeMode.toString()),
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'everywear',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            Widget content = MediaQuery(
              // Preserve the system text scale so Android accessibility
              // settings are honored throughout the application.
              data: MediaQuery.of(context),
              child: StagingBuildBanner(
                enabled: _isStagingBuild,
                child: child!,
              ),
            );
            if (widget.diagnosticMode) {
              content = StartupDiagnosticBanner(child: content);
            }
            return content;
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
          home: const AuthGate(),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
