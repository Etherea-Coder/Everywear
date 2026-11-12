const MAX_IMAGE_BASE64_CHARS = 10_000_000;
const MAX_RESPONSE_CHARS = 2_000;
const BASE64_PATTERN =
  /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;
const CATEGORIES = new Set([
  "Tops",
  "Bottoms",
  "Shoes",
  "Outerwear",
  "Accessories",
  "Dresses",
  "Activewear",
]);
const VIBES = new Set(["Casual", "Formal", "Sport", "Elegant", "Street"]);

export type ImageRequestValidation =
  | { ok: true; imageBase64: string }
  | { ok: false; status: 400 | 413; error: string };

export type ClothingAnalysis = {
  success: true;
  category: string;
  color: string;
  material: string;
  confidence: number;
  style_vibe: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function boundedText(value: unknown, maxLength: number): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.trim();
  return text.length > 0 ? text.slice(0, maxLength) : undefined;
}

export function validateImageRequest(input: unknown): ImageRequestValidation {
  if (!isRecord(input)) {
    return { ok: false, status: 400, error: "Invalid request body" };
  }
  const imageBase64 = input.imageBase64;
  if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
    return { ok: false, status: 400, error: "Missing imageBase64" };
  }
  if (imageBase64.length > MAX_IMAGE_BASE64_CHARS) {
    return { ok: false, status: 413, error: "Image is too large" };
  }
  if (!BASE64_PATTERN.test(imageBase64)) {
    return { ok: false, status: 400, error: "Invalid image data" };
  }
  return { ok: true, imageBase64 };
}

// Model output is untrusted. Only return bounded fields from the expected shape.
export function parseClothingAnalysis(
  rawText: unknown,
): ClothingAnalysis | null {
  if (typeof rawText !== "string" || rawText.length > MAX_RESPONSE_CHARS) {
    return null;
  }
  const match = rawText.match(/\{[\s\S]*\}/);
  if (!match) return null;

  let parsed: unknown;
  try {
    parsed = JSON.parse(match[0]);
  } catch {
    return null;
  }
  if (!isRecord(parsed)) return null;

  const category = parsed.category;
  const color = boundedText(parsed.color, 40);
  const material = boundedText(parsed.material, 40);
  const styleVibe = parsed.style_vibe;
  const confidence = parsed.confidence;
  if (
    typeof category !== "string" || !CATEGORIES.has(category) || !color ||
    !material || typeof styleVibe !== "string" || !VIBES.has(styleVibe) ||
    typeof confidence !== "number" || !Number.isFinite(confidence)
  ) {
    return null;
  }

  return {
    success: true,
    category,
    color,
    material,
    confidence: Math.max(0.5, Math.min(0.99, confidence)),
    style_vibe: styleVibe,
  };
}
