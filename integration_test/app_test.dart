import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:everywear/main.dart' as app;
import 'package:everywear/services/supabase_service.dart';
import 'package:everywear/core/utils/profile_display_name.dart';
import 'package:everywear/core/ui_smoke_test_mode.dart';
import 'package:everywear/widgets/staging_build_banner.dart';

const _foreground = MethodChannel('com.everywear/ui_smoke_test');
const _isStaging = bool.fromEnvironment('EVERYWEAR_STAGING');
const _adsEnabled = bool.fromEnvironment('EVERYWEAR_ADS_ENABLED');
const _distribution = String.fromEnvironment('APP_DISTRIBUTION');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'authenticated staging smoke: synthetic wardrobe, outfit, Today, profile, logout last',
    (tester) async {
      if (!_isStaging || _adsEnabled || _distribution != 'uptodown') {
        throw StateError(
          'Refusing to run without the approved staging-only UI smoke defines.',
        );
      }
      if (const String.fromEnvironment('REVENUECAT_BILLING_ENVIRONMENT') !=
          'unavailable') {
        throw StateError('Purchases must remain unavailable in the free beta.');
      }
      if (Uri.parse(SupabaseService.cleanSupabaseUrl).host !=
          'aftdbphdobfrshienple.supabase.co') {
        throw StateError('Refusing to run against a non-staging project.');
      }

      final originalPicker = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _SyntheticImagePicker();
      addTearDown(() => ImagePickerPlatform.instance = originalPicker);
      UiSmokeTestMode.setEnabledForDebugTest(true);
      addTearDown(() => UiSmokeTestMode.setEnabledForDebugTest(false));

      app.main();
      await _waitForForeground(tester);
      await _waitForPredicate(
        tester,
        () => SupabaseService.isInitialized,
        timeout: const Duration(seconds: 30),
      );
      final client = SupabaseService.instance.client;
      if (client.auth.currentUser == null) {
        // The isolated test application has its own secure storage and does
        // not inherit the normal app's Supabase session. Let the owner
        // authenticate privately in this test-only app before any writes.
        // ignore: avoid_print
        print(
          'SIGN_IN_REQUIRED: sign in to the staging-test app on this phone; '
          'the test is waiting and will not write test records yet.',
        );
        await _waitForPredicate(
          tester,
          () => client.auth.currentUser != null,
          timeout: const Duration(minutes: 5),
        );
      }
      await _waitFor(tester, find.byTooltip('Manage wardrobe items'));
      await _assertForeground(tester);
      expect(
        find.descendant(
          of: find.byType(StagingBuildBanner),
          matching: find.byType(Banner),
        ),
        findsOneWidget,
        reason: 'The staging define must enable the visible Flutter banner.',
      );

      final initialUser = client.auth.currentUser;
      expect(
        initialUser,
        isNotNull,
        reason: 'Use an already-confirmed staging account.',
      );
      final apiHost = Uri.parse(SupabaseService.cleanSupabaseUrl).host;
      expect(
        apiHost,
        'aftdbphdobfrshienple.supabase.co',
        reason: 'This smoke test may write only to approved staging.',
      );
      // ignore: avoid_print
      print('PASS: existing confirmed staging session and project guard');

      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final itemName = 'SYNTHETIC UI SMOKE TOP $suffix';
      final outfitName = 'SYNTHETIC UI SMOKE OUTFIT $suffix';

      // Wardrobe tab and add form.
      await _tap(tester, find.byTooltip('Manage wardrobe items'));
      await _tap(tester, find.byKey(const ValueKey('wardrobe_add_item')));
      await _waitFor(tester, find.byKey(const ValueKey('wardrobe_add_photo')));
      await _tap(tester, find.byKey(const ValueKey('wardrobe_add_photo')));
      await _tap(tester, find.byKey(const ValueKey('wardrobe_gallery_option')));
      await _waitFor(tester, find.byKey(const ValueKey('wardrobe_item_name')));
      await _enterText(
        tester,
        find.byKey(const ValueKey('wardrobe_item_name')),
        itemName,
      );
      await _tap(tester, find.byKey(const ValueKey('wardrobe_category_Tops')));
      await _tap(tester, find.byKey(const ValueKey('wardrobe_save_item')));
      await _waitFor(
        tester,
        find.text(itemName),
        timeout: const Duration(seconds: 75),
      );
      // ignore: avoid_print
      print('PASS: synthetic wardrobe image upload and row display');

      // Resolve the uploaded row using the authenticated session, then verify the
      // image widget completes its authorized Storage resolution and display.
      final storedItem = await _waitForStagingRow(
        tester,
        () async => await client
            .from('wardrobe_items')
            .select('id,image_url')
            .eq('user_id', initialUser!.id)
            .eq('name', itemName)
            .maybeSingle(),
        timeout: const Duration(seconds: 60),
      );
      final itemId = storedItem['id'].toString();
      final imageFinder = find.byKey(ValueKey('wardrobe_image_$itemId'));
      await _waitFor(tester, imageFinder);
      await _waitFor(
        tester,
        find.descendant(of: imageFinder, matching: find.byType(Image)),
        timeout: const Duration(seconds: 60),
      );
      expect(storedItem['image_url'].toString(), isNotEmpty);
      // ignore: avoid_print
      print('PASS: wardrobe Storage image resolves and renders');

      // The Today capture path must allow selecting the uploaded wardrobe item.
      await _tap(tester, find.byTooltip('Daily outfit log'));
      await _tap(tester, find.byKey(const ValueKey('today_quick_log')));
      await _tap(
        tester,
        find.byKey(const ValueKey('today_quicklog_take_photo')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('outfit_build_from_wardrobe')),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('outfit_build_from_wardrobe')),
      );
      final selectableItem = find.byKey(
        ValueKey('outfit_wardrobe_item_$itemId'),
      );
      await _waitFor(
        tester,
        selectableItem,
        timeout: const Duration(seconds: 60),
      );
      await _tap(tester, selectableItem);
      await _tap(tester, find.byKey(const ValueKey('outfit_continue')));
      await _waitFor(tester, find.byKey(const ValueKey('outfit_name')));
      expect(find.text(itemName), findsWidgets);
      final confirmationImage = find.byKey(
        ValueKey('outfit_confirmation_image_$itemId'),
      );
      await _waitFor(tester, confirmationImage);
      await _waitFor(
        tester,
        find.descendant(of: confirmationImage, matching: find.byType(Image)),
        timeout: const Duration(seconds: 60),
      );
      await _enterText(
        tester,
        find.byKey(const ValueKey('outfit_name')),
        outfitName,
      );
      await _tap(tester, find.byKey(const ValueKey('outfit_rating_3')));
      await _tap(tester, find.byKey(const ValueKey('outfit_save')));
      await _waitFor(
        tester,
        find.text(outfitName),
        timeout: const Duration(seconds: 75),
      );

      // Verify the route-return refresh shows the newly saved synthetic outfit.
      final refreshedOutfit = await _waitForStagingRow(
        tester,
        () async => await client
            .from('outfit_logs')
            .select('id')
            .eq('user_id', initialUser!.id)
            .eq('outfit_name', outfitName)
            .maybeSingle(),
        timeout: const Duration(seconds: 60),
      );
      expect(refreshedOutfit['id'], isNotEmpty);
      expect(find.text(outfitName), findsWidgets);
      // ignore: avoid_print
      print('PASS: outfit creation and automatic Today refresh');

      // A pre-existing account may not carry full_name if it signed up before
      // the metadata fix. Verify the displayed source when available, without
      // overwriting its profile. Fresh signup is separately required to prove
      // the signup metadata flow end to end.
      await _tap(tester, find.byTooltip('Profile and settings'));
      final nameFinder = find.byKey(const ValueKey('profile_display_name'));
      final profileRow = await client
          .from('user_profiles')
          .select('full_name')
          .eq('id', initialUser!.id)
          .maybeSingle();
      final profileName = client.auth.currentUser?.userMetadata?['full_name'];
      final expectedDisplayName = resolveProfileDisplayName(
        authMetadataName: profileName as String?,
        profileName: profileRow?['full_name'] as String?,
        email: initialUser.email,
      );
      await _waitFor(tester, nameFinder);
      await _waitForPredicate(
        tester,
        () => tester.widget<Text>(nameFinder).data == expectedDisplayName,
      );
      expect(tester.widget<Text>(nameFinder).data, expectedDisplayName);
      if (profileName is String && profileName.trim().isNotEmpty) {
        expect(tester.widget<Text>(nameFinder).data, profileName.trim());
        // ignore: avoid_print
        print('PASS: authenticated profile full-name display');
      } else {
        // ignore: avoid_print
        print(
          'SKIPPED fresh-signup name assertion: existing account has no full_name metadata.',
        );
      }

      // Logout is deliberately the final authenticated action. Never delete
      // the account or any smoke-test records.
      await _tap(tester, find.byKey(const ValueKey('profile_settings_tile')));
      await _tap(tester, find.byKey(const ValueKey('settings_logout')));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('confirmation_dialog_confirm')),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('confirmation_dialog_confirm')),
      );
      await _waitForPredicate(tester, () => client.auth.currentUser == null);
      await _assertForeground(tester);
      expect(client.auth.currentUser, isNull);
      // ignore: avoid_print
      print('PASS: sign-out completed as the final account action');
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _assertForeground(tester);
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await _assertForeground(tester);
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await _assertForeground(tester);
}

Future<void> _enterText(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await _assertForeground(tester);
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await _assertForeground(tester);
  await tester.tap(finder.first);
  await _assertForeground(tester);
  await tester.enterText(finder.first, value);
  await tester.pump(const Duration(milliseconds: 200));
  await _assertForeground(tester);
}

Future<void> _assertForeground(WidgetTester tester) async {
  final lifecycle = tester.binding.lifecycleState;
  if (lifecycle != AppLifecycleState.resumed) {
    throw StateError('Smoke test stopped: Flutter lifecycle is $lifecycle.');
  }
  final isForeground = await _foreground.invokeMethod<bool>('isForeground');
  if (isForeground != true) {
    throw StateError('Smoke test stopped: Everywear is not foregrounded.');
  }
}

Future<void> _waitForForeground(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (tester.binding.lifecycleState == AppLifecycleState.resumed) {
      try {
        if (await _foreground.invokeMethod<bool>('isForeground') == true) {
          return;
        }
      } on MissingPluginException {
        throw StateError(
          'Smoke test stopped before UI waits: native foreground probe is '
          'unavailable in the isolated Android test app.',
        );
      }
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  throw TestFailure(
    'Smoke test stopped before UI waits: isolated Everywear activity did '
    'not become resumed and foregrounded.',
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  throw TestFailure('Timed out waiting for visible app state: $finder');
}

Future<Map<String, dynamic>> _waitForStagingRow(
  WidgetTester tester,
  Future<Map<String, dynamic>?> Function() read, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final latest = await read();
    if (latest != null) return latest;
    await tester.pump(const Duration(milliseconds: 500));
  }
  throw TestFailure('Timed out waiting for staging record to become visible.');
}

Future<void> _waitForPredicate(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  throw TestFailure('Timed out waiting for the requested app state.');
}

class _SyntheticImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => _createSyntheticImage();

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => _createSyntheticImage();

  Future<XFile> _createSyntheticImage() async {
    final pixels = image_lib.Image(width: 96, height: 96);
    image_lib.fill(pixels, color: image_lib.ColorRgb8(232, 112, 64));
    // A simple contrasting rectangle makes the fixture visibly synthetic.
    image_lib.fillRect(
      pixels,
      x1: 25,
      y1: 15,
      x2: 70,
      y2: 80,
      color: image_lib.ColorRgb8(245, 226, 195),
    );
    final file = File(
      '${Directory.systemTemp.path}/everywear-synthetic-shirt.png',
    );
    await file.writeAsBytes(image_lib.encodePng(pixels), flush: true);
    return XFile(file.path, mimeType: 'image/png');
  }
}
