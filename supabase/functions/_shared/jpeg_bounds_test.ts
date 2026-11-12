import { isBoundedJpegBase64, jpegDimensions } from "./jpeg_bounds.ts";

const jpegHeader = Uint8Array.from([
  0xff,
  0xd8,
  0xff,
  0xc0,
  0x00,
  0x07,
  0x08,
  0x00,
  0x02,
  0x00,
  0x03,
  0x01,
]);

Deno.test("accepts a bounded single JPEG and rejects unsupported or oversized images", () => {
  const encoded = btoa(String.fromCharCode(...jpegHeader));
  const dimensions = jpegDimensions(jpegHeader);
  if (
    dimensions?.width !== 3 || dimensions.height !== 2 ||
    !isBoundedJpegBase64(encoded)
  ) {
    throw new Error("Expected parsed bounded JPEG dimensions");
  }
  if (isBoundedJpegBase64(btoa("not jpeg"))) {
    throw new Error("Accepted non-JPEG bytes");
  }
  const wide = Uint8Array.from([
    0xff,
    0xd8,
    0xff,
    0xc0,
    0x00,
    0x07,
    0x08,
    0x00,
    0x01,
    0x05,
    0x01,
    0x01,
  ]);
  if (isBoundedJpegBase64(btoa(String.fromCharCode(...wide)))) {
    throw new Error("Accepted image over the dimension limit");
  }
});
