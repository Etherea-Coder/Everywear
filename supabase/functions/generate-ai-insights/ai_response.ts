export type InsightRecommendation = {
  type: "gap" | "seasonal" | "style";
  title: string;
  description: string;
  confidence: number;
  reasoning: string;
};

export type AiInsights = {
  confidenceScore?: number;
  styleProfile?: string;
  emergingStyles?: string[];
  recommendations?: InsightRecommendation[];
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function boundedText(value: unknown, maxLength: number): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed.slice(0, maxLength) : undefined;
}

function boundedScore(value: unknown): number | undefined {
  if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
  return Math.max(0, Math.min(100, Math.round(value)));
}

function parseRecommendation(value: unknown): InsightRecommendation | null {
  if (!isRecord(value)) return null;
  const type = value.type;
  if (type !== "gap" && type !== "seasonal" && type !== "style") return null;

  const title = boundedText(value.title, 120);
  const description = boundedText(value.description, 500);
  const reasoning = boundedText(value.reasoning, 300);
  const confidence = boundedScore(value.confidence);
  if (!title || !description || !reasoning || confidence === undefined) {
    return null;
  }
  return { type, title, description, reasoning, confidence };
}

// Parse and bound an untrusted model response before returning it to clients.
export function parseAiInsights(rawText: string): AiInsights {
  const jsonMatch = rawText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return {};

  let value: unknown;
  try {
    value = JSON.parse(jsonMatch[0]);
  } catch {
    return {};
  }
  if (!isRecord(value)) return {};

  const confidenceScore = boundedScore(value.confidenceScore);
  const styleProfile = boundedText(value.styleProfile, 80);
  const emergingStyles = Array.isArray(value.emergingStyles)
    ? value.emergingStyles
      .map((style) => boundedText(style, 80))
      .filter((style): style is string => style !== undefined)
      .slice(0, 8)
    : undefined;
  const recommendations = Array.isArray(value.recommendations)
    ? value.recommendations
      .map(parseRecommendation)
      .filter((item): item is InsightRecommendation => item !== null)
      .slice(0, 10)
    : undefined;

  return {
    ...(confidenceScore === undefined ? {} : { confidenceScore }),
    ...(styleProfile === undefined ? {} : { styleProfile }),
    ...(emergingStyles === undefined ? {} : { emergingStyles }),
    ...(recommendations === undefined ? {} : { recommendations }),
  };
}

export function extractGeminiText(response: unknown): string | null {
  if (!isRecord(response) || !Array.isArray(response.candidates)) return null;
  const candidate = response.candidates[0];
  if (!isRecord(candidate) || !isRecord(candidate.content)) return null;
  const parts = candidate.content.parts;
  if (!Array.isArray(parts) || !isRecord(parts[0])) return null;
  const text = parts[0].text;
  return typeof text === "string" ? text : null;
}
