import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../user_tier_service.dart';

enum AdProviderSelection { disabled, monetag, admob }

enum AdConsentState { unknown, required, granted, denied }

enum AdAccessLevel { free, premium, promotionalAccess, unknown }

enum AdInteractionContext {
  safeContentBreak,
  photoCapture,
  textEntry,
  authentication,
  checkout,
  otherAd,
}

enum AdPlacement { interstitial }

enum AdDisplayResult { displayed, unavailable, failed }

enum AdRequestOutcome { displayed, unavailable, failed, suppressed }

AdAccessLevel classifyAdAccess({
  required String? tier,
  required String? status,
  required String? expiresAt,
  DateTime? now,
}) {
  if (tier == 'free') return AdAccessLevel.free;
  if (tier != 'premium') return AdAccessLevel.unknown;
  if (status == 'inactive' || status == 'expired') return AdAccessLevel.free;
  if (status != 'active' && status != 'grace_period' && status != 'cancelled') {
    return AdAccessLevel.unknown;
  }
  if (expiresAt == null || DateTime.tryParse(expiresAt) == null) {
    return AdAccessLevel.unknown;
  }
  return UserTierService.hasVerifiedPremiumAccess(
        tier: tier,
        status: status,
        expiresAt: expiresAt,
        now: now,
      )
      ? AdAccessLevel.premium
      : AdAccessLevel.free;
}

extension AdProviderSelectionParsing on AdProviderSelection {
  static AdProviderSelection parse(String value) =>
      switch (value.trim().toLowerCase()) {
        'monetag' => AdProviderSelection.monetag,
        'admob' => AdProviderSelection.admob,
        'disabled' || '' => AdProviderSelection.disabled,
        _ => AdProviderSelection.disabled,
      };
}

class AdsConfiguration {
  const AdsConfiguration({
    this.enabled = false,
    this.provider = AdProviderSelection.disabled,
  });

  static const _environmentEnabled = bool.fromEnvironment(
    'EVERYWEAR_ADS_ENABLED',
    defaultValue: false,
  );
  static const _environmentProvider = String.fromEnvironment(
    'EVERYWEAR_AD_PROVIDER',
    defaultValue: 'disabled',
  );

  factory AdsConfiguration.fromEnvironment() => AdsConfiguration(
    enabled: _environmentEnabled,
    provider: AdProviderSelectionParsing.parse(_environmentProvider),
  );

  final bool enabled;
  final AdProviderSelection provider;
}

class AdFrequencyPolicy {
  const AdFrequencyPolicy({
    this.maximumDisplays = 3,
    this.window = const Duration(hours: 24),
    this.minimumInterval = const Duration(minutes: 15),
  }) : assert(maximumDisplays > 0);

  final int maximumDisplays;
  final Duration window;
  final Duration minimumInterval;

  bool allows(List<DateTime> successfulDisplays, DateTime now) {
    final cutoff = now.subtract(window);
    final recent =
        successfulDisplays
            .map((time) => time.toUtc())
            .where((time) => !time.isBefore(cutoff))
            .toList()
          ..sort();
    if (recent.any((time) => time.isAfter(now.toUtc()))) return false;
    if (recent.length >= maximumDisplays) return false;
    if (recent.isNotEmpty &&
        now.toUtc().difference(recent.last) < minimumInterval) {
      return false;
    }
    return true;
  }
}

class AdRequestContext {
  const AdRequestContext({
    required this.userId,
    required this.consent,
    required this.interaction,
    required this.lifecycle,
    this.placement = AdPlacement.interstitial,
  });

  final String? userId;
  final AdConsentState consent;
  final AdInteractionContext interaction;
  final AppLifecycleState lifecycle;
  final AdPlacement placement;
}

abstract interface class AdProviderAdapter {
  AdProviderSelection get provider;
  bool get isConfigured;

  Future<void> initialize();
  Future<AdDisplayResult> show(AdPlacement placement);
  Future<void> dispose();
}

abstract interface class AdFrequencyStore {
  Future<List<DateTime>> successfulDisplays(
    String userId,
    AdPlacement placement,
  );

  Future<void> recordSuccessfulDisplay(
    String userId,
    AdPlacement placement,
    DateTime displayedAt,
  );
}

abstract interface class AdAccessResolver {
  Future<AdAccessLevel> resolve(String expectedUserId);
}

/// Resolves entitlement from the authenticated profile; errors fail closed.
class SupabaseAdAccessResolver implements AdAccessResolver {
  SupabaseAdAccessResolver(this._client);

  final SupabaseClient _client;

  @override
  Future<AdAccessLevel> resolve(String expectedUserId) async {
    if (_client.auth.currentUser?.id != expectedUserId) {
      return AdAccessLevel.unknown;
    }
    try {
      final profile = await _client
          .from('user_profiles')
          .select('tier, subscription_status, subscription_expires_at')
          .eq('id', expectedUserId)
          .maybeSingle();
      if (_client.auth.currentUser?.id != expectedUserId || profile == null) {
        return AdAccessLevel.unknown;
      }
      return classifyAdAccess(
        tier: profile['tier'] as String?,
        status: profile['subscription_status'] as String?,
        expiresAt: profile['subscription_expires_at'] as String?,
      );
    } catch (_) {
      return AdAccessLevel.unknown;
    }
  }
}

/// Frequency history is isolated per account and placement.
class PreferencesAdFrequencyStore implements AdFrequencyStore {
  const PreferencesAdFrequencyStore();

  static const _keyPrefix = 'everywear_ads_success_v1';
  static const _maximumStoredTimestamps = 200;

  String _key(String userId, AdPlacement placement) =>
      '$_keyPrefix:${Uri.encodeComponent(userId)}:${placement.name}';

  @override
  Future<List<DateTime>> successfulDisplays(
    String userId,
    AdPlacement placement,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key(userId, placement)) ?? [])
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((value) => value.toUtc())
        .toList(growable: false);
  }

  @override
  Future<void> recordSuccessfulDisplay(
    String userId,
    AdPlacement placement,
    DateTime displayedAt,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _key(userId, placement);
    final timestamps =
        (preferences.getStringList(key) ?? [])
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map((value) => value.toUtc())
            .toList()
          ..add(displayedAt.toUtc())
          ..sort();
    final retained = timestamps.length <= _maximumStoredTimestamps
        ? timestamps
        : timestamps.sublist(timestamps.length - _maximumStoredTimestamps);
    await preferences.setStringList(
      key,
      retained.map((value) => value.toIso8601String()).toList(),
    );
  }
}

/// Provider-neutral coordinator with no registered adapters by default.
class AdCoordinator {
  AdCoordinator({
    required this.configuration,
    required this.adapters,
    required this.frequencyStore,
    required this.accessResolver,
    required this.currentAccountId,
    this.frequencyPolicy = const AdFrequencyPolicy(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AdsConfiguration configuration;
  final Map<AdProviderSelection, AdProviderAdapter> adapters;
  final AdFrequencyStore frequencyStore;
  final AdAccessResolver accessResolver;
  final String? Function() currentAccountId;
  final AdFrequencyPolicy frequencyPolicy;
  final DateTime Function() _clock;
  final Set<AdProviderAdapter> _initializedAdapters =
      Set<AdProviderAdapter>.identity();

  bool _busy = false;

  Future<AdRequestOutcome> request(AdRequestContext context) async {
    if (_busy) return AdRequestOutcome.suppressed;
    _busy = true;
    try {
      if (!configuration.enabled ||
          configuration.provider == AdProviderSelection.disabled) {
        return AdRequestOutcome.suppressed;
      }
      if (context.consent != AdConsentState.granted ||
          context.interaction != AdInteractionContext.safeContentBreak ||
          context.lifecycle != AppLifecycleState.resumed) {
        return AdRequestOutcome.suppressed;
      }
      final userId = context.userId;
      if (userId == null || userId.isEmpty || currentAccountId() != userId) {
        return AdRequestOutcome.suppressed;
      }
      final adapter = adapters[configuration.provider];
      if (adapter == null ||
          adapter.provider != configuration.provider ||
          !adapter.isConfigured) {
        return AdRequestOutcome.unavailable;
      }
      final access = await accessResolver.resolve(userId);
      if (currentAccountId() != userId) return AdRequestOutcome.suppressed;
      if (access == AdAccessLevel.premium ||
          access == AdAccessLevel.promotionalAccess) {
        return AdRequestOutcome.suppressed;
      }
      if (access != AdAccessLevel.free) return AdRequestOutcome.unavailable;
      final previous = await frequencyStore.successfulDisplays(
        userId,
        context.placement,
      );
      if (!frequencyPolicy.allows(previous, _clock())) {
        return AdRequestOutcome.suppressed;
      }
      if (currentAccountId() != userId) return AdRequestOutcome.suppressed;
      if (!_initializedAdapters.contains(adapter)) {
        await adapter.initialize();
        _initializedAdapters.add(adapter);
      }
      if (currentAccountId() != userId) return AdRequestOutcome.suppressed;
      final result = await adapter.show(context.placement);
      if (result == AdDisplayResult.displayed) {
        await frequencyStore.recordSuccessfulDisplay(
          userId,
          context.placement,
          _clock(),
        );
        return AdRequestOutcome.displayed;
      }
      return result == AdDisplayResult.failed
          ? AdRequestOutcome.failed
          : AdRequestOutcome.unavailable;
    } catch (_) {
      return AdRequestOutcome.failed;
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() async {
    for (final adapter in _initializedAdapters) {
      await adapter.dispose();
    }
    _initializedAdapters.clear();
  }
}
