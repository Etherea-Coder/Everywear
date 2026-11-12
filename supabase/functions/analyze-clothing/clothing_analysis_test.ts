import {
  parseClothingAnalysis,
  validateImageRequest,
} from "./clothing_analysis.ts";

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
  assertEquals(validateImageRequest({ imageBase64: "AQID" }), {
    ok: true,
    imageBase64: "AQID",
  });
  const nonObject = validateImageRequest(null);
  const empty = validateImageRequest({ imageBase64: "" });
  const malformed = validateImageRequest({ imageBase64: "not base64" });
  assertEquals(nonObject.ok ? 200 : nonObject.status, 400);
  assertEquals(empty.ok ? 200 : empty.status, 400);
  assertEquals(malformed.ok ? 200 : malformed.status, 400);
});

Deno.test("rejects encoded image bodies above the existing size limit", () => {
  const result = validateImageRequest({
    imageBase64: "A".repeat(10_000_001),
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
