import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/ai_image_payload.dart';

void main() {
  group('encodeAiImageBase64', () {
    test('encodes bytes for a direct authenticated request', () {
      expect(encodeAiImageBase64([1, 2, 3]), 'AQID');
    });

    test('rejects empty image data', () {
      expect(encodeAiImageBase64(const []), isNull);
    });

    test('enforces the compressed image byte limit', () {
      expect(encodeAiImageBase64([1, 2, 3], maxBytes: 3), 'AQID');
      expect(encodeAiImageBase64([1, 2, 3, 4], maxBytes: 3), isNull);
    });
  });
}
