import { createGeminiRequest } from "./gemini_request.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("sends Gemini credentials only in the API key header", async () => {
  const apiKey = "private-test-api-key";
  const payload = { contents: [{ parts: [{ text: "test prompt" }] }] };
  const request = createGeminiRequest("gemini-test", apiKey, payload);

  assertEquals(request.method, "POST");
  assertEquals(new URL(request.url).search, "");
  assertEquals(request.url.includes(apiKey), false);
  assertEquals(request.headers.get("x-goog-api-key"), apiKey);
  assertEquals(request.headers.get("content-type"), "application/json");
  assertEquals(await request.json(), payload);
});
