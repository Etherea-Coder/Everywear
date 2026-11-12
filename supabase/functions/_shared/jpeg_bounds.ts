export type JpegDimensions = { width: number; height: number };

const SOF_MARKERS = new Set([
  0xc0,
  0xc1,
  0xc2,
  0xc3,
  0xc5,
  0xc6,
  0xc7,
  0xc9,
  0xca,
  0xcb,
  0xcd,
  0xce,
  0xcf,
]);

/** Reads dimensions from JPEG headers without decoding or retaining the image. */
export function jpegDimensions(bytes: Uint8Array): JpegDimensions | null {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return null;
  let offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] !== 0xff) return null;
    while (offset < bytes.length && bytes[offset] === 0xff) offset++;
    const marker = bytes[offset++];
    if (marker === 0xd9 || marker === 0xda) return null;
    if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 2 > bytes.length) return null;
    const length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) return null;
    if (SOF_MARKERS.has(marker)) {
      if (length < 7) return null;
      return {
        height: (bytes[offset + 3] << 8) | bytes[offset + 4],
        width: (bytes[offset + 5] << 8) | bytes[offset + 6],
      };
    }
    offset += length;
  }
  return null;
}

export function isBoundedJpegBase64(
  value: string,
  maxBytes = 3_000_000,
  maxDimension = 1280,
): boolean {
  let bytes: Uint8Array;
  try {
    bytes = Uint8Array.from(
      atob(value),
      (character) => character.charCodeAt(0),
    );
  } catch {
    return false;
  }
  if (bytes.byteLength > maxBytes) return false;
  const dimensions = jpegDimensions(bytes);
  return dimensions !== null && dimensions.width > 0 && dimensions.height > 0 &&
    dimensions.width <= maxDimension && dimensions.height <= maxDimension;
}
