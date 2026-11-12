import {
  createOpenRouterRequest,
  OPENROUTER_MODEL,
} from "./openrouter_request.ts";

Deno.test("OpenRouter request is canonical, bounded, and has no provider failover", async () => {
  const request = createOpenRouterRequest({
    apiKey: "test-only",
    supabaseUrl: "https://project.example",
    imageBase64: "dGVzdA==",
    systemPrompt: "p".repeat(5_000),
    languageInstruction: "Describe this outfit.",
  });
  const body = await request.json() as Record<string, unknown>;
  const provider = body.provider as Record<string, unknown>;
  const messages = body.messages as Array<Record<string, unknown>>;
  if (
    body.model !== "google/gemini-2.5-flash-lite" ||
    body.model !== OPENROUTER_MODEL ||
    provider.allow_fallbacks !== false ||
    body.max_tokens !== 500 ||
    provider.sort !== "price" ||
    (messages[0].content as string).length > 4_000
  ) {
    throw new Error("OpenRouter request configuration exceeded its bound");
  }
  if (request.headers.get("authorization") !== "Bearer test-only") {
    throw new Error("Server API key must use the Authorization header");
  }
});
