import { isRequestId } from "../_shared/ai_action.ts";
import {
  CANONICAL_COLOR_VALUES,
  normalizeCanonicalColor,
} from "../_shared/color_vocabulary.ts";
import { isBoundedJpegBase64 } from "../_shared/jpeg_bounds.ts";

const MAX_IMAGE_BASE64_CHARS = 4_000_000;
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
  | { ok: true; imageBase64: string; requestId: string }
  | { ok: false; status: 400 | 413; error: string };

export type ClothingAnalysis = {
  success: true;
  category: string;
  color: string;
  colorLabel: string;
  material: string;
  materialLabel: string;
  confidence: number;
  style_vibe: string;
};

export function buildClothingAnalysisPrompt(responseLanguage: string): string {
  return `Analyze this clothing item image and respond ONLY with a JSON object in this exact format.
Keep machine-readable values independent of the requested language: color must be one exact canonical English value from [${
    CANONICAL_COLOR_VALUES.join(", ")
  }]; material must be a concise canonical English material name. Put localized display text in colorLabel and materialLabel in ${responseLanguage}. Keep category and style_vibe values in the fixed English enums below:
{
  "category": one of ["Tops", "Bottoms", "Shoes", "Outerwear", "Accessories", "Dresses", "Activewear"],
  "color": canonical color value from the supplied list,
  "colorLabel": localized color display text,
  "material": likely material as a concise English canonical term,
  "materialLabel": localized material display text,
  "confidence": a number between 0.5 and 0.99,
  "style_vibe": one of ["Casual", "Formal", "Sport", "Elegant", "Street"]
}
Respond with ONLY the JSON, no other text.`;
}

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
  const requestId = input.requestId;
  if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
    return { ok: false, status: 400, error: "Missing imageBase64" };
  }
  if (imageBase64.length > MAX_IMAGE_BASE64_CHARS) {
    return { ok: false, status: 413, error: "Image is too large" };
  }
  if (!BASE64_PATTERN.test(imageBase64)) {
    return { ok: false, status: 400, error: "Invalid image data" };
  }
  if (!isRequestId(requestId)) {
    return { ok: false, status: 400, error: "Invalid request identifier" };
  }
  if (!isBoundedJpegBase64(imageBase64)) {
    return {
      ok: false,
      status: 413,
      error: "Image must be JPEG up to 1280 pixels and 3 MB",
    };
  }
  return { ok: true, imageBase64, requestId };
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
  const suppliedColor = boundedText(parsed.color, 40);
  const color = suppliedColor ? normalizeCanonicalColor(suppliedColor) : null;
  const colorLabel = boundedText(parsed.colorLabel, 40) ?? suppliedColor;
  const material = boundedText(parsed.material, 40);
  const materialLabel = boundedText(parsed.materialLabel, 40) ?? material;
  const styleVibe = parsed.style_vibe;
  const confidence = parsed.confidence;
  if (
    typeof category !== "string" || !CATEGORIES.has(category) || !color ||
    !colorLabel || !material || !materialLabel ||
    typeof styleVibe !== "string" || !VIBES.has(styleVibe) ||
    typeof confidence !== "number" || !Number.isFinite(confidence)
  ) {
    return null;
  }

  return {
    success: true,
    category,
    color,
    colorLabel,
    material,
    materialLabel,
    confidence: Math.max(0.5, Math.min(0.99, confidence)),
    style_vibe: styleVibe,
  };
}
