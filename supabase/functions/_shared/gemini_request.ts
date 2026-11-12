export function createGeminiRequest(
  model: string,
  apiKey: string,
  payload: unknown,
): Request {
  const url = new URL(
    `https://generativelanguage.googleapis.com/v1beta/models/${
      encodeURIComponent(model)
    }:generateContent`,
  );
  return new Request(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: JSON.stringify(payload),
  });
}
