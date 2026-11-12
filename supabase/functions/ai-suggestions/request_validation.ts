import { isRequestId } from "../_shared/ai_action.ts";
import { isBoundedJpegBase64 } from "../_shared/jpeg_bounds.ts";

export type AiSuggestionLanguage = "EN" | "FR" | "ES";

export interface AiSuggestionProfile {
  styleProfile?: string;
  preferredColors?: string;
  styleGoals?: string;
  styleIntention?: string;
}

export interface AiSuggestionRequest {
  imageBase64: string;
  requestId: string;
  language: AiSuggestionLanguage;
  userName?: string;
  userProfile?: AiSuggestionProfile;
}

export type AiSuggestionRequestResult =
  | { ok: true; value: AiSuggestionRequest }
  | { ok: false; status: 400 | 413; error: string };

const MAX_IMAGE_BASE64_CHARS = 4_000_000;
const BASE64_PATTERN =
  /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;
const ALLOWED_LANGUAGES = new Set<string>(["EN", "FR", "ES"]);
const PROFILE_FIELDS = [
  "styleProfile",
  "preferredColors",
  "styleGoals",
  "styleIntention",
] as const;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function boundedString(value: unknown, maxLength: number): string | undefined {
  if (typeof value !== "string") return undefined;
  return value.slice(0, maxLength);
}

export function validateAiSuggestionRequest(
  input: unknown,
): AiSuggestionRequestResult {
  if (!isRecord(input)) {
    return { ok: false, status: 400, error: "Invalid request body" };
  }

  const imageBase64 = input.imageBase64;
  const requestId = input.requestId;
  if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
    return { ok: false, status: 400, error: "Missing image data" };
  }
  if (imageBase64.length > MAX_IMAGE_BASE64_CHARS) {
    return { ok: false, status: 413, error: "Image is too large" };
  }
  if (!BASE64_PATTERN.test(imageBase64)) {
    return { ok: false, status: 400, error: "Invalid image data" };
  }
  if (!isBoundedJpegBase64(imageBase64)) {
    return {
      ok: false,
      status: 413,
      error: "Image must be JPEG up to 1280 pixels and 3 MB",
    };
  }
  if (!isRequestId(requestId)) {
    return { ok: false, status: 400, error: "Invalid request identifier" };
  }

  const language = input.language;
  if (typeof language !== "string" || !ALLOWED_LANGUAGES.has(language)) {
    return { ok: false, status: 400, error: "Unsupported language" };
  }

  const profileInput = isRecord(input.userProfile) ? input.userProfile : null;
  const profileEntries = PROFILE_FIELDS.flatMap((field) => {
    const value = boundedString(profileInput?.[field], 500);
    return value === undefined ? [] : [[field, value] as const];
  });
  const userProfile = profileEntries.length > 0
    ? Object.fromEntries(profileEntries) as AiSuggestionProfile
    : undefined;

  const userName = boundedString(input.userName, 80);
  return {
    ok: true,
    value: {
      imageBase64,
      requestId,
      language: language as AiSuggestionLanguage,
      ...(userName === undefined ? {} : { userName }),
      ...(userProfile === undefined ? {} : { userProfile }),
    },
  };
}
