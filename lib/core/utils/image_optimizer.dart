import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class ImageOptimizer {
  /// Compresses an image file to a target quality and size.
  /// Returns the compressed file.
  static Future<File> compressImage(File file, {int quality = 80}) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = p.join(dir.absolute.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    return File(result.path);
  }

  /// Helper to get file size in MB
  static double getFileSizeInMB(File file) {
    int sizeInBytes = file.lengthSync();
    return sizeInBytes / (1024 * 1024);
  }
}
