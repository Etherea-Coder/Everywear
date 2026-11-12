type CoachMode = "passive" | "active" | "event";
type CoachResponse = Record<string, string | boolean>;

const MAX_RESPONSE_CHARS = 4_000;
const MAX_FIELD_CHARS = 1_200;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function boundedText(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.trim();
  return text.length > 0 ? text.slice(0, MAX_FIELD_CHARS) : undefined;
}

function parseJsonObject(text: string): Record<string, unknown> | null {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return null;
  try {
    const parsed: unknown = JSON.parse(match[0]);
    return isRecord(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function failure(): CoachResponse {
  return { success: false, error: "No usable coach response." };
}

export function isCoachMode(value: unknown): value is CoachMode {
  return value === "passive" || value === "active" || value === "event";
}

// Model output is untrusted: expose only bounded fields expected by each mode.
export function parseCoachResponse(
  mode: unknown,
  rawText: unknown,
): CoachResponse {
  if (!isCoachMode(mode)) return failure();
  if (typeof rawText !== "string" || rawText.length > MAX_RESPONSE_CHARS) {
    return failure();
  }

  const text = rawText.trim();
  if (!text) return failure();

  if (mode === "passive") {
    return { success: true, mode, tip: text.slice(0, MAX_FIELD_CHARS) };
  }

  const parsed = parseJsonObject(text);
  if (!parsed) return failure();

  if (mode === "active") {
    const answer = boundedText(parsed.answer);
    if (!answer) return failure();
    const nextStep = boundedText(parsed.next_step);
    return {
      success: true,
      mode,
      answer,
      next_step: nextStep ?? "",
    };
  }

  const intro = boundedText(parsed.intro);
  const outfit1 = boundedText(parsed.outfit_1);
  const outfit2 = boundedText(parsed.outfit_2);
  const outfit3 = boundedText(parsed.outfit_3);
  const prepTip = boundedText(parsed.prep_tip);
  if (!intro || (!outfit1 && !outfit2 && !outfit3)) return failure();

  return {
    success: true,
    mode,
    intro,
    ...(outfit1 ? { outfit_1: outfit1 } : {}),
    ...(outfit2 ? { outfit_2: outfit2 } : {}),
    ...(outfit3 ? { outfit_3: outfit3 } : {}),
    ...(prepTip ? { prep_tip: prepTip } : {}),
  };
}
