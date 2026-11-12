import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:everywear/services/ads/ad_service.dart';

void main() {
  group('classifyAdAccess', () {
    final now = DateTime.utc(2026, 11, 12);

    test('requires a valid server expiry for active premium', () {
      expect(
        classifyAdAccess(
          tier: 'premium',
          status: 'active',
          expiresAt: null,
          now: now,
        ),
        AdAccessLevel.unknown,
      );
      expect(
        classifyAdAccess(
          tier: 'premium',
          status: 'active',
          expiresAt: '2026-11-13T00:00:00Z',
          now: now,
        ),
        AdAccessLevel.premium,
      );
      expect(
        classifyAdAccess(
          tier: 'premium',
          status: 'active',
          expiresAt: '2026-11-11T00:00:00Z',
          now: now,
        ),
        AdAccessLevel.free,
      );
    });
  });

  group('AdsConfiguration', () {
    test('defaults disabled and parses explicit providers only', () {
      expect(const AdsConfiguration().enabled, isFalse);
      expect(
        AdProviderSelectionParsing.parse('monetag'),
        AdProviderSelection.monetag,
      );
      expect(
        AdProviderSelectionParsing.parse('admob'),
        AdProviderSelection.admob,
      );
      expect(
        AdProviderSelectionParsing.parse('unknown'),
        AdProviderSelection.disabled,
      );
    });

    test('frequency history is persistent and scoped by account', () async {
      SharedPreferences.setMockInitialValues({});
      const store = PreferencesAdFrequencyStore();
      final timestamp = DateTime.utc(2026, 11, 12, 12);
      await store.recordSuccessfulDisplay(
        'a',
        AdPlacement.interstitial,
        timestamp,
      );
      expect(await store.successfulDisplays('a', AdPlacement.interstitial), [
        timestamp,
      ]);
      expect(
        await store.successfulDisplays('b', AdPlacement.interstitial),
        isEmpty,
      );
    });
  });

  group('AdCoordinator', () {
    late FakeAdAdapter monetag;
    late FakeStore store;
    late FakeResolver resolver;
    late String? activeAccount;
    final now = DateTime.utc(2026, 11, 12, 12);

    setUp(() {
      monetag = FakeAdAdapter(AdProviderSelection.monetag);
      store = FakeStore();
      resolver = FakeResolver(AdAccessLevel.free);
      activeAccount = 'account-a';
    });

    AdCoordinator coordinator({
      bool enabled = true,
      AdProviderSelection provider = AdProviderSelection.monetag,
      Map<AdProviderSelection, AdProviderAdapter>? adapters,
      AdFrequencyPolicy policy = const AdFrequencyPolicy(),
    }) => AdCoordinator(
      configuration: AdsConfiguration(enabled: enabled, provider: provider),
      adapters: adapters ?? {AdProviderSelection.monetag: monetag},
      frequencyStore: store,
      accessResolver: resolver,
      currentAccountId: () => activeAccount,
      frequencyPolicy: policy,
      clock: () => now,
    );

    AdRequestContext request({
      String? userId = 'account-a',
      AdConsentState consent = AdConsentState.granted,
      AdInteractionContext interaction = AdInteractionContext.safeContentBreak,
      AppLifecycleState lifecycle = AppLifecycleState.resumed,
    }) => AdRequestContext(
      userId: userId,
      consent: consent,
      interaction: interaction,
      lifecycle: lifecycle,
    );

    test(
      'disabled config and missing providers never show fake success',
      () async {
        expect(
          await coordinator(enabled: false).request(request()),
          AdRequestOutcome.suppressed,
        );
        expect(
          await coordinator(adapters: const {}).request(request()),
          AdRequestOutcome.unavailable,
        );
        expect(
          await coordinator(
            provider: AdProviderSelection.admob,
          ).request(request()),
          AdRequestOutcome.unavailable,
        );
        expect(monetag.initializeCalls, 0);
      },
    );

    test('unconfigured placement stays unavailable', () async {
      monetag.isConfigured = false;
      expect(
        await coordinator().request(request()),
        AdRequestOutcome.unavailable,
      );
      expect(resolver.calls, 0);
      expect(monetag.initializeCalls, 0);
    });

    test('premium, future promotion and unknown access fail closed', () async {
      for (final level in [
        AdAccessLevel.premium,
        AdAccessLevel.promotionalAccess,
      ]) {
        resolver.level = level;
        expect(
          await coordinator().request(request()),
          AdRequestOutcome.suppressed,
        );
      }
      resolver.level = AdAccessLevel.unknown;
      expect(
        await coordinator().request(request()),
        AdRequestOutcome.unavailable,
      );
      expect(monetag.initializeCalls, 0);
    });

    test(
      'consent and safe lifecycle/context gate SDK initialization',
      () async {
        for (final consent in [
          AdConsentState.unknown,
          AdConsentState.required,
          AdConsentState.denied,
        ]) {
          expect(
            await coordinator().request(request(consent: consent)),
            AdRequestOutcome.suppressed,
          );
        }
        for (final interaction in [
          AdInteractionContext.photoCapture,
          AdInteractionContext.textEntry,
          AdInteractionContext.authentication,
          AdInteractionContext.checkout,
          AdInteractionContext.otherAd,
        ]) {
          expect(
            await coordinator().request(request(interaction: interaction)),
            AdRequestOutcome.suppressed,
          );
        }
        expect(
          await coordinator().request(
            request(lifecycle: AppLifecycleState.paused),
          ),
          AdRequestOutcome.suppressed,
        );
        expect(resolver.calls, 0);
        expect(monetag.initializeCalls, 0);
      },
    );

    test(
      'account switch during entitlement lookup cannot show to new user',
      () async {
        resolver.onResolve = () => activeAccount = 'account-b';
        expect(
          await coordinator().request(request()),
          AdRequestOutcome.suppressed,
        );
        expect(monetag.showCalls, 0);
        expect(monetag.initializeCalls, 0);
      },
    );

    test('failed and unavailable loads do not consume frequency', () async {
      monetag.nextResult = AdDisplayResult.failed;
      final ads = coordinator(
        policy: const AdFrequencyPolicy(maximumDisplays: 1),
      );
      expect(await ads.request(request()), AdRequestOutcome.failed);
      expect(store.displays, isEmpty);
      monetag.nextResult = AdDisplayResult.unavailable;
      expect(await ads.request(request()), AdRequestOutcome.unavailable);
      expect(store.displays, isEmpty);
      monetag.nextResult = AdDisplayResult.displayed;
      expect(await ads.request(request()), AdRequestOutcome.displayed);
      expect(store.displays, hasLength(1));
    });

    test('successful displays enforce count and cooldown', () async {
      final ads = coordinator(
        policy: const AdFrequencyPolicy(maximumDisplays: 2),
      );
      expect(await ads.request(request()), AdRequestOutcome.displayed);
      expect(await ads.request(request()), AdRequestOutcome.suppressed);
      expect(monetag.showCalls, 1);
    });

    test(
      'overlapping requests are suppressed and dispose releases adapter',
      () async {
        final pending = Completer<AdDisplayResult>();
        monetag.pending = pending;
        final ads = coordinator();
        final first = ads.request(request());
        await monetag.started.future;
        expect(await ads.request(request()), AdRequestOutcome.suppressed);
        pending.complete(AdDisplayResult.displayed);
        expect(await first, AdRequestOutcome.displayed);
        await ads.dispose();
        expect(monetag.showCalls, 1);
        expect(monetag.disposeCalls, 1);
      },
    );
  });
}

class FakeAdAdapter implements AdProviderAdapter {
  FakeAdAdapter(this.provider);
  @override
  final AdProviderSelection provider;
  @override
  bool isConfigured = true;
  int initializeCalls = 0;
  int showCalls = 0;
  int disposeCalls = 0;
  AdDisplayResult nextResult = AdDisplayResult.displayed;
  Completer<AdDisplayResult>? pending;
  final started = Completer<void>();

  @override
  Future<void> initialize() async => initializeCalls++;
  @override
  Future<AdDisplayResult> show(AdPlacement placement) {
    showCalls++;
    if (!started.isCompleted) started.complete();
    return pending?.future ?? Future.value(nextResult);
  }

  @override
  Future<void> dispose() async => disposeCalls++;
}

class FakeStore implements AdFrequencyStore {
  final displays = <DateTime>[];
  @override
  Future<List<DateTime>> successfulDisplays(
    String userId,
    AdPlacement placement,
  ) async => List.of(displays);
  @override
  Future<void> recordSuccessfulDisplay(
    String userId,
    AdPlacement placement,
    DateTime displayedAt,
  ) async => displays.add(displayedAt);
}

class FakeResolver implements AdAccessResolver {
  FakeResolver(this.level);
  AdAccessLevel level;
  int calls = 0;
  void Function()? onResolve;
  @override
  Future<AdAccessLevel> resolve(String expectedUserId) async {
    calls++;
    onResolve?.call();
    return level;
  }
}
