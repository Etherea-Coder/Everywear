import { extractGeminiText, parseAiInsights } from "./ai_response.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  const normalize = (value: unknown): unknown => {
    if (Array.isArray(value)) return value.map(normalize);
    if (typeof value !== "object" || value === null) return value;
    return Object.fromEntries(
      Object.entries(value).sort(([left], [right]) => left.localeCompare(right))
        .map(([key, item]) => [key, normalize(item)]),
    );
  };
  const actualJson = JSON.stringify(normalize(actual));
  const expectedJson = JSON.stringify(normalize(expected));
  if (actualJson !== expectedJson) {
    throw new Error(
      `Expected ${expectedJson}, received ${actualJson}`,
    );
  }
}

Deno.test("parses valid bounded insight fields", () => {
  assertEquals(
    parseAiInsights(
      `prefix {"confidenceScore": 104, "styleProfile": "  Casual  ",
      "emergingStyles": ["Minimal", 3], "recommendations": [{
        "type": "gap", "title": "Add layers", "description": "Use a jacket.",
        "confidence": 82, "reasoning": "Works with existing pieces."
      }, {"type": "unknown", "title": "bad"}]} suffix`,
    ),
    {
      confidenceScore: 100,
      styleProfile: "Casual",
      emergingStyles: ["Minimal"],
      recommendations: [{
        type: "gap",
        title: "Add layers",
        description: "Use a jacket.",
        confidence: 82,
        reasoning: "Works with existing pieces.",
      }],
    },
  );
});

Deno.test("malformed, non-object and wrong-shaped model replies fail closed", () => {
  assertEquals(parseAiInsights("not json"), {});
  assertEquals(parseAiInsights("[]"), {});
  assertEquals(
    parseAiInsights('{"confidenceScore":"high","recommendations":"no"}'),
    {},
  );
});

Deno.test("caps text and collection sizes from untrusted model output", () => {
  const longText = "x".repeat(600);
  const parsed = parseAiInsights(JSON.stringify({
    styleProfile: longText,
    emergingStyles: Array.from({ length: 12 }, () => longText),
    recommendations: Array.from({ length: 12 }, () => ({
      type: "style",
      title: longText,
      description: longText,
      confidence: 70,
      reasoning: longText,
    })),
  }));

  assertEquals(parsed.styleProfile?.length, 80);
  assertEquals(parsed.emergingStyles?.length, 8);
  assertEquals(parsed.recommendations?.length, 10);
  assertEquals(parsed.recommendations?.[0].title.length, 120);
  assertEquals(parsed.recommendations?.[0].description.length, 500);
  assertEquals(parsed.recommendations?.[0].reasoning.length, 300);
});

Deno.test("extracts provider response text only from a valid candidate", () => {
  assertEquals(
    extractGeminiText({
      candidates: [{ content: { parts: [{ text: "{}" }] } }],
    }),
    "{}",
  );
  assertEquals(extractGeminiText({ candidates: [] }), null);
  assertEquals(extractGeminiText(null), null);
});
