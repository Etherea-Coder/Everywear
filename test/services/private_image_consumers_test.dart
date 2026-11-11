import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:everywear/services/image_export_resolver.dart';
import 'package:everywear/services/storage_service.dart';
import 'package:everywear/widgets/custom_image_widget.dart';

void main() {
  group('avatar storage reference contract', () {
    test('uploaded avatar references are stable owner scoped paths', () {
      expect(
        StorageService.stableReferenceFor(
          bucket: 'avatars',
          ownerId: 'user-a',
          objectPath: 'user-a/avatar-1.png',
        ),
        'avatars/user-a/avatar-1.png',
      );
      expect(
        StorageService.stableReferenceFor(
          bucket: 'avatars',
          ownerId: 'user-a',
          objectPath: 'user-b/avatar.png',
        ),
        isNull,
      );
      expect(
        StorageService.stableStorageReference(
          'https://qxsdwwdrxoyxmnapuqqv.supabase.co/storage/v1/object/public/avatars/user-a/avatar.png?token=old',
          supabaseUrl: 'https://qxsdwwdrxoyxmnapuqqv.supabase.co',
        ),
        'avatars/user-a/avatar.png',
      );
    });

    test('Storage cache keys are stable and external URLs stay unchanged', () {
      expect(
        StorageService.imageCacheKey(
          'https://qxsdwwdrxoyxmnapuqqv.supabase.co/storage/v1/object/sign/wardrobe-images/user-a/item.png?token=temporary',
          supabaseUrl: 'https://qxsdwwdrxoyxmnapuqqv.supabase.co',
        ),
        'wardrobe-images/user-a/item.png',
      );
      expect(
        StorageService.imageCacheKey('https://images.example/item.png'),
        'https://images.example/item.png',
      );
    });

    testWidgets(
      'avatar display resolves a private reference before networking',
      (tester) async {
        String? requestedReference;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomImageWidget(
                imageUrl: 'avatars/user-a/avatar.png',
                storageUrlResolver: (reference) async {
                  requestedReference = reference;
                  return 'http://127.0.0.1:1/avatar?token=temporary';
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(requestedReference, 'avatars/user-a/avatar.png');
        final networkImage = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(networkImage.imageUrl, contains('127.0.0.1:1'));
        expect(networkImage.cacheKey, 'avatars/user-a/avatar.png');
      },
    );

    testWidgets('unavailable avatar uses the supplied fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomImageWidget(
              imageUrl: 'avatars/user-a/missing.png',
              storageUrlResolver: (_) async => null,
              errorWidget: const Text('avatar unavailable'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('avatar unavailable'), findsOneWidget);
    });
  });

  group('wardrobe image cleanup ownership', () {
    test('allows only the current owner wardrobe object reference', () {
      expect(
        StorageService.ownedWardrobeImageReference(
          'wardrobe-images/user-a/item.png',
          ownerId: 'user-a',
        ),
        'wardrobe-images/user-a/item.png',
      );
      expect(
        StorageService.ownedWardrobeImageReference(
          'wardrobe-images/user-b/item.png',
          ownerId: 'user-a',
        ),
        isNull,
      );
      expect(
        StorageService.ownedWardrobeImageReference(
          'https://images.example/item.png',
          ownerId: 'user-a',
        ),
        isNull,
      );
      expect(
        StorageService.ownedWardrobeImageReference(
          'avatars/user-a/avatar.png',
          ownerId: 'user-a',
        ),
        isNull,
      );
    });

    test(
      'recognizes an owned legacy project URL without retaining its token',
      () {
        expect(
          StorageService.ownedWardrobeImageReference(
            'https://qxsdwwdrxoyxmnapuqqv.supabase.co/storage/v1/object/public/wardrobe-images/user-a/item.png?token=expired',
            ownerId: 'user-a',
            supabaseUrl: 'https://qxsdwwdrxoyxmnapuqqv.supabase.co',
          ),
          'wardrobe-images/user-a/item.png',
        );
      },
    );
  });

  test(
    'exports resolve stable and legacy references in memory and skip misses',
    () async {
      final requested = <String>[];
      final bytes = Uint8List.fromList(
        image_codec.encodePng(image_codec.Image(width: 1, height: 1)),
      );
      final resolved = await ImageExportResolver.resolve(
        const [
          'wardrobe-images/user-a/item.jpg',
          'https://qxsdwwdrxoyxmnapuqqv.supabase.co/storage/v1/object/public/avatars/user-a/avatar.png?token=legacy',
          'avatars/user-a/deleted.png',
          null,
        ],
        load: (reference) async {
          requested.add(reference);
          return reference.endsWith('deleted.png') ? null : bytes;
        },
      );

      expect(requested, hasLength(3));
      expect(resolved.take(2), everyElement(isNotNull));
      expect(resolved[2], isNull);
      expect(resolved[3], isNull);
    },
  );
}
