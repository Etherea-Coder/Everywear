import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/storage_service.dart';
import 'package:everywear/widgets/custom_image_widget.dart';

void main() {
  const projectUrl = 'https://qxsdwwdrxoyxmnapuqqv.supabase.co';

  group('image reference routing', () {
    test('stable wardrobe and avatar object references use Storage', () {
      expect(
        StorageService.classifyImageReference(
          'wardrobe-images/user-1/item.jpg',
          supabaseUrl: projectUrl,
        ),
        ImageReferenceRoute.storage,
      );
      expect(
        StorageService.classifyImageReference(
          'avatars/user-1/avatar.png',
          supabaseUrl: projectUrl,
        ),
        ImageReferenceRoute.storage,
      );
    });

    test('Storage URLs route only for the exact configured origin and path', () {
      for (final url in [
        '$projectUrl/storage/v1/object/public/wardrobe-images/user-1/item.jpg',
        '$projectUrl/storage/v1/object/sign/avatars/user-1/avatar.png?token=old',
        '$projectUrl/storage/v1/object/wardrobe-images/user-1/item.jpg',
      ]) {
        expect(
          StorageService.classifyImageReference(url, supabaseUrl: projectUrl),
          ImageReferenceRoute.storage,
          reason: url,
        );
      }
    });

    test('external and lookalike URLs retain ordinary network routing', () {
      for (final url in [
        'https://images.example.org/item.jpg',
        'https://qxsdwwdrxoyxmnapuqqv.supabase.co.evil.example/storage/v1/object/public/wardrobe-images/user-1/item.jpg',
        'https://other.supabase.co/storage/v1/object/public/wardrobe-images/user-1/item.jpg',
        '$projectUrl/not-storage/v1/object/public/wardrobe-images/user-1/item.jpg',
      ]) {
        expect(
          StorageService.classifyImageReference(url, supabaseUrl: projectUrl),
          ImageReferenceRoute.network,
          reason: url,
        );
      }
      expect(
        'https://images.example.org/item.jpg'.imageType,
        ImageType.network,
      );
    });

    test('assets and local files bypass Storage resolution', () {
      expect(
        StorageService.classifyImageReference(
          'assets/images/item.png',
          supabaseUrl: projectUrl,
        ),
        ImageReferenceRoute.asset,
      );
      expect(
        StorageService.classifyImageReference(
          'file:///tmp/item.jpg',
          supabaseUrl: projectUrl,
        ),
        ImageReferenceRoute.localFile,
      );
      expect('assets/images/item.svg'.imageType, ImageType.svg);
      expect('file:///tmp/item.jpg'.imageType, ImageType.file);
    });
  });
}
