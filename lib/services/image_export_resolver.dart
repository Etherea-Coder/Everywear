import 'dart:typed_data';
import 'package:image/image.dart' as image_codec;

typedef ExportImageLoader = Future<Uint8List?> Function(String reference);

/// Resolves export image references in memory; missing/unavailable images are
/// represented by null so exports can continue without writing URL credentials.
class ImageExportResolver {
  const ImageExportResolver._();

  static Future<List<Uint8List?>> resolve(
    Iterable<String?> references, {
    required ExportImageLoader load,
  }) async {
    return Future.wait(
      references.map((reference) async {
        if (reference == null || reference.trim().isEmpty) return null;
        try {
          final bytes = await load(reference);
          if (bytes == null) return null;
          final decoded = image_codec.decodeImage(bytes);
          if (decoded == null) return null;
          return Uint8List.fromList(image_codec.encodePng(decoded));
        } catch (_) {
          return null;
        }
      }),
    );
  }
}
