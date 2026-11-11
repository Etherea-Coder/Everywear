import 'dart:convert';

const maxAiImageBytes = 3_000_000;
const maxAiSourceImageBytes = 20 * 1024 * 1024;

/// Encodes an already-compressed JPEG for the authenticated AI request.
/// Returning null keeps oversized images from creating unbounded request JSON.
String? encodeAiImageBase64(List<int> bytes, {int maxBytes = maxAiImageBytes}) {
  if (bytes.isEmpty || bytes.length > maxBytes) return null;
  return base64Encode(bytes);
}
