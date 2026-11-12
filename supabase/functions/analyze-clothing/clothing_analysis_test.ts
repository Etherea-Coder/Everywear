import {
  parseClothingAnalysis,
  validateImageRequest,
} from "./clothing_analysis.ts";

const tinyJpeg = btoa(String.fromCharCode(
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
  0x03,
));
const requestId = "123e4567-e89b-42d3-a456-426614174000";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("accepts valid base64 image bodies and rejects malformed inputs", () => {
  assertEquals(validateImageRequest({ imageBase64: tinyJpeg, requestId }), {
    ok: true,
    imageBase64: tinyJpeg,
    requestId,
  });
  const nonObject = validateImageRequest(null);
  const empty = validateImageRequest({ imageBase64: "", requestId });
  const malformed = validateImageRequest({
    imageBase64: "not base64",
    requestId,
  });
  assertEquals(nonObject.ok ? 200 : nonObject.status, 400);
  assertEquals(empty.ok ? 200 : empty.status, 400);
  assertEquals(malformed.ok ? 200 : malformed.status, 400);
});

Deno.test("rejects encoded image bodies above the existing size limit", () => {
  const result = validateImageRequest({
    imageBase64: "A".repeat(4_000_001),
    requestId,
  });
  assertEquals(result.ok ? 200 : result.status, 413);
});

Deno.test("returns only allowed bounded analysis fields", () => {
  const result = parseClothingAnalysis(JSON.stringify({
    success: false,
    category: "Tops",
    color: ` ${"blue".repeat(20)} `,
    material: " Cotton ",
    confidence: 1.5,
    style_vibe: "Casual",
    error: "model supplied field",
  }));
  assertEquals(result?.success, true);
  assertEquals(result?.color.length, 40);
  assertEquals(result?.material, "Cotton");
  assertEquals(result?.confidence, 0.99);
  assertEquals("error" in (result ?? {}), false);
});

Deno.test("fails closed on malformed or unsupported model output", () => {
  assertEquals(parseClothingAnalysis("not JSON"), null);
  assertEquals(parseClothingAnalysis("[]"), null);
  assertEquals(
    parseClothingAnalysis(JSON.stringify({
      category: "Invented",
      color: "Blue",
      material: "Cotton",
      confidence: 0.8,
      style_vibe: "Casual",
    })),
    null,
  );
  assertEquals(parseClothingAnalysis("x".repeat(2_001)), null);
});
