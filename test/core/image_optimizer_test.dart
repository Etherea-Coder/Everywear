import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/core/utils/image_optimizer.dart';
import 'dart:io';

void main() {
  group('ImageOptimizer', () {
    test('getFileSizeInMB throws for non-existent file', () {
      final file = File('/nonexistent/path/image.jpg');
      expect(
        () => ImageOptimizer.getFileSizeInMB(file),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('getFileSizeInMB calculates correct size for a real file', () async {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/test_image_optimizer.txt');
      await file.writeAsBytes(List.generate(1024 * 1024, (i) => i % 256));
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final sizeInMB = ImageOptimizer.getFileSizeInMB(file);
      expect(sizeInMB, closeTo(1.0, 0.01));
    });
  });
}
