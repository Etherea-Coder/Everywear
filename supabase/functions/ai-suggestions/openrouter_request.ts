export const OPENROUTER_MODEL = "google/gemini-2.5-flash-lite";
export const OPENROUTER_API_URL =
  "https://openrouter.ai/api/v1/chat/completions";

function truncateUtf8(value: string, maxBytes: number): string {
  const encoder = new TextEncoder();
  let output = "";
  let bytes = 0;
  for (const character of value) {
    const size = encoder.encode(character).byteLength;
    if (bytes + size > maxBytes) break;
    output += character;
    bytes += size;
  }
  return output;
}

export function createOpenRouterRequest(input: {
  apiKey: string;
  supabaseUrl: string;
  imageBase64: string;
  systemPrompt: string;
  languageInstruction: string;
}): Request {
  return new Request(OPENROUTER_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${input.apiKey}`,
      "HTTP-Referer": input.supabaseUrl || "https://everywear.app",
      "X-OpenRouter-Title": "EveryWear AI Suggestions",
    },
    body: JSON.stringify({
      model: OPENROUTER_MODEL,
      provider: {
        allow_fallbacks: false,
        sort: "price",
        max_price: { prompt: 0.1, completion: 0.4 },
      },
      messages: [
        { role: "system", content: truncateUtf8(input.systemPrompt, 4_000) },
        {
          role: "user",
          content: [
            { type: "text", text: input.languageInstruction },
            {
              type: "image_url",
              image_url: { url: `data:image/jpeg;base64,${input.imageBase64}` },
            },
          ],
        },
      ],
      max_tokens: 500,
      temperature: 0.1,
      stream: false,
    }),
  });
}
