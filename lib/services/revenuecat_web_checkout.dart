import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppDistribution { uptodown, googlePlay, unavailable }

enum BillingEnvironment { production, sandbox, unavailable }

class RevenueCatWebCheckoutConfig {
  const RevenueCatWebCheckoutConfig({
    required this.distribution,
    required this.environment,
    required this.productionLink,
    required this.sandboxLink,
    required this.isReleaseBuild,
    this.freeBeta = false,
  });

  factory RevenueCatWebCheckoutConfig.fromEnvironment() {
    const distribution = String.fromEnvironment('APP_DISTRIBUTION');
    const environment = String.fromEnvironment(
      'REVENUECAT_BILLING_ENVIRONMENT',
    );
    const freeBeta = bool.fromEnvironment(
      'EVERYWEAR_FREE_BETA',
      defaultValue: false,
    );
    return RevenueCatWebCheckoutConfig(
      distribution: switch (distribution) {
        'uptodown' => AppDistribution.uptodown,
        'google_play' => AppDistribution.googlePlay,
        _ => AppDistribution.unavailable,
      },
      environment: switch (environment) {
        'production' => BillingEnvironment.production,
        'sandbox' => BillingEnvironment.sandbox,
        _ => BillingEnvironment.unavailable,
      },
      productionLink: const String.fromEnvironment(
        'REVENUECAT_WEB_PURCHASE_LINK_PRODUCTION',
      ),
      sandboxLink: const String.fromEnvironment(
        'REVENUECAT_WEB_PURCHASE_LINK_SANDBOX',
      ),
      isReleaseBuild: kReleaseMode,
      freeBeta: freeBeta,
    );
  }

  final AppDistribution distribution;
  final BillingEnvironment environment;
  final String productionLink;
  final String sandboxLink;
  final bool isReleaseBuild;
  final bool freeBeta;

  bool get environmentMatchesBuild => isReleaseBuild
      ? environment == BillingEnvironment.production
      : environment == BillingEnvironment.sandbox;

  bool get isAvailable =>
      !freeBeta &&
      distribution == AppDistribution.uptodown &&
      environmentMatchesBuild &&
      _parsePurchaseLink(
            environment == BillingEnvironment.production
                ? productionLink
                : sandboxLink,
          ) !=
          null;

  Uri? checkoutUriFor(String appUserId) {
    if (!isAvailable || !_isUuid(appUserId)) return null;
    final link = _parsePurchaseLink(
      environment == BillingEnvironment.production
          ? productionLink
          : sandboxLink,
    );
    if (link == null) return null;
    return link.replace(pathSegments: [...link.pathSegments, appUserId]);
  }

  static Uri? _parsePurchaseLink(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'pay.rev.cat' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.length != 1 ||
        !RegExp(r'^[A-Za-z0-9_-]{4,200}$').hasMatch(uri.pathSegments.single)) {
      return null;
    }
    return uri;
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

class RevenueCatWebCheckout {
  static final RevenueCatWebCheckout shared = RevenueCatWebCheckout();

  RevenueCatWebCheckout({
    RevenueCatWebCheckoutConfig? config,
    Future<bool> Function(Uri uri)? launch,
  }) : config = config ?? RevenueCatWebCheckoutConfig.fromEnvironment(),
       _launch = launch ?? _launchExternally;

  static final Uri billingReturnUri = Uri(
    scheme: 'io.supabase.everywear',
    host: 'billing-return',
  );

  final RevenueCatWebCheckoutConfig config;
  final Future<bool> Function(Uri uri) _launch;
  String? _pendingUserId;

  String? takePendingUserId(String? currentUserId) {
    final pending = _pendingUserId;
    _pendingUserId = null;
    return pending != null && pending == currentUserId ? pending : null;
  }

  void clearPendingCheckout() => _pendingUserId = null;

  Future<bool> openForUser(String appUserId) async {
    final uri = config.checkoutUriFor(appUserId);
    if (uri == null) return false;
    final opened = await _launch(uri);
    _pendingUserId = opened ? appUserId : null;
    return opened;
  }

  Future<bool> openManagementUri(Uri uri) async {
    final safeUri = validatedManagementUri(uri.toString());
    if (safeUri == null) return false;
    return _launch(safeUri);
  }

  Future<bool> openManagementUrl(String? value) async {
    final uri = validatedManagementUri(value);
    if (uri == null) return false;
    return _launch(uri);
  }

  static bool isBillingReturnFor(Uri uri, String appUserId) =>
      uri.scheme == billingReturnUri.scheme &&
      uri.host == billingReturnUri.host &&
      uri.path.isEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment &&
      uri.queryParameters.length == 1 &&
      uri.queryParameters['app_user_id'] == appUserId &&
      RevenueCatWebCheckoutConfig._isUuid(appUserId);

  static Uri? validatedManagementUri(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return null;
    }
    if (uri.host == 'api.revenuecat.com' &&
        uri.path.startsWith('/rcbilling/v1/customerportal/')) {
      return uri;
    }
    if (uri.host == 'billing.revenuecat.com' && uri.pathSegments.length >= 2) {
      return uri;
    }
    if (uri.host == 'play.google.com' &&
        uri.path.startsWith('/store/account/subscriptions')) {
      return uri;
    }
    if (uri.host == 'apps.apple.com' && uri.path == '/account/subscriptions') {
      return uri;
    }
    return null;
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
