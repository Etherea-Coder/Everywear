import { validateAiSuggestionRequest } from "./request_validation.ts";

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
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("rejects non-object request bodies", () => {
  assertEquals(validateAiSuggestionRequest(null), {
    ok: false,
    status: 400,
    error: "Invalid request body",
  });
});

Deno.test("rejects missing or malformed image payloads", () => {
  assertEquals(
    validateAiSuggestionRequest({ imageBase64: "", language: "EN", requestId }),
    {
      ok: false,
      status: 400,
      error: "Missing image data",
    },
  );
  assertEquals(
    validateAiSuggestionRequest({
      imageBase64: "not-base64!",
      language: "EN",
      requestId,
    }),
    {
      ok: false,
      status: 400,
      error: "Invalid image data",
    },
  );
});

Deno.test("rejects oversized image payload before provider or quota work", () => {
  const result = validateAiSuggestionRequest({
    imageBase64: "A".repeat(4_000_001),
    requestId,
    language: "EN",
  });
  assertEquals(result, {
    ok: false,
    status: 413,
    error: "Image is too large",
  });
});

Deno.test("accepts only supported languages and trims prompt fields", () => {
  const result = validateAiSuggestionRequest({
    imageBase64: tinyJpeg,
    requestId,
    language: "EN",
    userName: "A".repeat(100),
    userProfile: {
      styleProfile: "B".repeat(600),
      preferredColors: "Blue",
      ignored: "not part of the prompt contract",
    },
  });

  if (!result.ok) throw new Error("Expected valid request");
  assertEquals(result.value.imageBase64, tinyJpeg);
  assertEquals(result.value.language, "EN");
  assertEquals(result.value.userName?.length, 80);
  assertEquals(result.value.userProfile, {
    styleProfile: "B".repeat(500),
    preferredColors: "Blue",
  });
});

Deno.test("rejects unsupported languages", () => {
  assertEquals(
    validateAiSuggestionRequest({
      imageBase64: tinyJpeg,
      language: "DE",
      requestId,
    }),
    {
      ok: false,
      status: 400,
      error: "Unsupported language",
    },
  );
});
