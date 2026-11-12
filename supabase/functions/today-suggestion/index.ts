import { createClient } from "@supabase/supabase-js";
import { createGeminiRequest } from "../_shared/gemini_request.ts";
import {
  cancelProviderResponse,
  finalizeAiAction,
  isRecord,
  isRequestId,
  quotaDeniedResponse,
  readBoundedJson,
  readBoundedResponseJson,
  reserveAiAction,
  type RpcClient,
  safeProviderLabel,
  safeTokenCount,
  truncateUtf8,
  withProviderTimeout,
} from "../_shared/ai_action.ts";
import { parseTodaySuggestion } from "./suggestion_response.ts";

const GEMINI_MODEL = "gemini-2.5-flash-lite";

type WardrobePromptItem = {
  id?: string;
  name?: string;
  category?: string;
  semantic_label?: string | null;
  wear_count?: number | null;
  last_worn?: string | null;
  image_url?: string | null;
  avg_rating?: number | null;
  rated_count?: number | null;
};

function boundedString(value: unknown, maxLength: number): string | undefined {
  return typeof value === "string"
    ? value.trim().slice(0, maxLength)
    : undefined;
}

function boundedCounts(value: unknown): Record<string, number> {
  if (!isRecord(value)) return {};
  return Object.fromEntries(
    Object.entries(value)
      .filter(([key, count]) =>
        key.length <= 60 && typeof count === "number" &&
        Number.isFinite(count) && count >= 0
      )
      .slice(0, 20)
      .map(([key, count]) => [key, Math.min(count as number, 1000)]),
  );
}

Deno.serve(async (req) => {
  let quotaClient: RpcClient | null = null;
  let pendingRequestId: string | null = null;
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    quotaClient = supabase;
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    let requestBody: unknown;
    try {
      requestBody = await readBoundedJson(req, 16_384);
    } catch (error) {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: error instanceof RangeError ? 413 : 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    if (!isRecord(requestBody)) {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    const body = requestBody;
    if (!isRequestId(body.requestId)) {
      return new Response(
        JSON.stringify({ error: "Invalid request identifier" }),
        {
          status: 400,
          headers: { "Access-Control-Allow-Origin": "*" },
        },
      );
    }
    const requestId = body.requestId;
    const userName = boundedString(body.userName, 80);
    const localHour = typeof body.localHour === "number" &&
        Number.isInteger(body.localHour) && body.localHour >= 0 &&
        body.localHour <= 23
      ? body.localHour
      : undefined;
    const rawProfile = isRecord(body.userProfile) ? body.userProfile : {};
    const userProfile = {
      styleProfile: boundedString(rawProfile.styleProfile, 500),
      preferredColors: boundedString(rawProfile.preferredColors, 500),
      styleGoals: boundedString(rawProfile.styleGoals, 500),
      styleIntention: boundedString(rawProfile.styleIntention, 500),
    };
    const rawWeather = isRecord(body.weather) ? body.weather : null;
    const weather = rawWeather
      ? {
        temperature: typeof rawWeather.temperature === "number" &&
            Number.isFinite(rawWeather.temperature)
          ? Math.max(-100, Math.min(100, rawWeather.temperature))
          : undefined,
        unit: boundedString(rawWeather.unit, 12),
        condition: boundedString(rawWeather.condition, 80),
      }
      : null;
    const occasion = boundedString(body.occasion, 80);
    const mood = boundedString(body.mood, 80);
    const requestedWardrobeItems: WardrobePromptItem[] =
      Array.isArray(body.wardrobeItems)
        ? body.wardrobeItems.slice(0, 40).flatMap((value) => {
          if (!isRecord(value) || typeof value.id !== "string") return [];
          return [{
            id: value.id.slice(0, 80),
            avg_rating: typeof value.avg_rating === "number" &&
                Number.isFinite(value.avg_rating)
              ? Math.max(0, Math.min(5, value.avg_rating))
              : undefined,
            rated_count: typeof value.rated_count === "number" &&
                Number.isSafeInteger(value.rated_count)
              ? Math.max(0, Math.min(1000, value.rated_count))
              : undefined,
          }];
        })
        : [];
    const recentItems: string[] = Array.isArray(body.recentItems)
      ? body.recentItems.slice(0, 40).flatMap((value) => {
        const item = boundedString(value, 80);
        return item ? [item] : [];
      })
      : [];
    const rawEvent = isRecord(body.nextEvent) ? body.nextEvent : null;
    const nextEvent = rawEvent
      ? {
        title: boundedString(rawEvent.title, 80) ?? "Event",
        event_type: boundedString(rawEvent.event_type, 80) ?? "",
        dress_code: boundedString(rawEvent.dress_code, 80),
        daysLeft: typeof rawEvent.daysLeft === "number" &&
            Number.isFinite(rawEvent.daysLeft)
          ? Math.max(-365, Math.min(3650, Math.trunc(rawEvent.daysLeft)))
          : 0,
      }
      : null;
    const rawPatterns = isRecord(body.occasionPatterns)
      ? body.occasionPatterns
      : {};
    const occasionPatterns = {
      weekday: boundedCounts(rawPatterns.weekday),
      weekend: boundedCounts(rawPatterns.weekend),
    };

    const googleAiApiKey = Deno.env.get("GOOGLE_AI_API_KEY");
    if (!googleAiApiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI service is not configured.",
          code: "AI_UNAVAILABLE",
        }),
        {
          status: 503,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        },
      );
    }

    const { data: ownedWardrobe, error: wardrobeError } = await supabase
      .from("wardrobe_items")
      .select(
        "id, name, category, semantic_label, image_url, wear_count, last_worn",
      )
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(40);
    if (wardrobeError) throw new Error("Unable to load authenticated wardrobe");
    if (!ownedWardrobe || ownedWardrobe.length === 0) {
      return new Response(JSON.stringify({ error: "Wardrobe is empty" }), {
        status: 422,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // Client-supplied rating hints are accepted only for IDs returned by the
    // authenticated wardrobe query; names and image references come from DB.
    const ratingHints = new Map<
      string,
      { avg_rating?: number | null; rated_count?: number | null }
    >();
    for (
      const item of (Array.isArray(requestedWardrobeItems)
        ? requestedWardrobeItems
        : []) as WardrobePromptItem[]
    ) {
      if (typeof item?.id === "string") {
        ratingHints.set(item.id, {
          avg_rating: item.avg_rating,
          rated_count: item.rated_count,
        });
      }
    }
    const wardrobeItems = ownedWardrobe.map((item) => ({
      ...item,
      ...ratingHints.get(item.id),
    }));

    // Build wardrobe list for prompt
    const wardrobeList = (Array.isArray(wardrobeItems) ? wardrobeItems : [])
      .map((item: WardrobePromptItem) => {
        let line = `- id:${item.id} | ${item.name} | ${item.category} | ${
          item.semantic_label ?? "no visual details"
        } | worn ${item.wear_count ?? 0}x | last worn: ${
          item.last_worn ?? "never"
        }`;
        if (item.avg_rating) {
          line += ` | avg outfit rating: ${item.avg_rating}/5 (${
            item.rated_count ?? 0
          } outfits)`;
        }
        return line;
      }).join("\n");

    const recentList = (recentItems ?? []).join(", ") || "none";
    const weatherStr = weather
      ? `${weather.temperature}${weather.unit}, ${weather.condition}`
      : "unknown";
    const eventStr = nextEvent
      ? `${nextEvent.title} in ${nextEvent.daysLeft} days (${nextEvent.event_type}, dress code: ${
        nextEvent.dress_code ?? "none"
      })`
      : "none";

    const nameLine = userName ? ` for ${userName}` : "";
    const titleName = userName
      ? `${userName}'s Style Idea for Today`
      : "Today's Style Idea";

    let timeString = "unknown";
    if (typeof localHour === "number") {
      if (localHour >= 5 && localHour < 12) {
        timeString = "Morning";
      } else if (localHour >= 12 && localHour < 17) {
        timeString = "Afternoon";
      } else if (localHour >= 17 && localHour < 21) {
        timeString = "Evening";
      } else timeString = "Night";
    }

    const prompt = `You are a personal stylist${nameLine} inside a wardrobe app.
Your task is to create one realistic outfit suggestion for today using ONLY items from the user's actual wardrobe list below.

USER PROFILE:
${userName ? `- Name: ${userName}` : ""}
- Style profile: ${userProfile?.styleProfile ?? "not set"}
- Preferred colors: ${userProfile?.preferredColors ?? "not specified"}
- Style goals: ${userProfile?.styleGoals ?? "not specified"}
- Style intention: ${userProfile?.styleIntention ?? "not specified"}

TODAY CONTEXT:
- Time of Day: ${timeString} (local hour: ${localHour ?? "?"})
- Weather: ${weatherStr}
- Occasion: ${occasion ?? "none selected"}
- Mood: ${mood ?? "none selected"}
- Upcoming event: ${eventStr}
- Instruction: Tone of the description can hint at the time of day (e.g. morning prep, afternoon slump, evening out).

${
      (() => {
        if (!occasionPatterns || typeof occasionPatterns !== "object") {
          return "";
        }
        const weekday = occasionPatterns.weekday ?? {};
        const weekend = occasionPatterns.weekend ?? {};
        const fmtTop = (counts: Record<string, number>) => {
          const entries = Object.entries(counts).sort(([, a], [, b]) =>
            b - a
          );
          if (entries.length === 0) return "no data yet";
          return entries.slice(0, 3).map(([k, v]) => `${k} (${v}x)`).join(", ");
        };
        if (
          Object.keys(weekday).length === 0 && Object.keys(weekend).length === 0
        ) return "";
        return `HABIT PATTERNS (last 60 days):\n- Weekdays: ${
          fmtTop(weekday)
        }\n- Weekends: ${
          fmtTop(weekend)
        }\n- Instruction: If no occasion is selected, lean toward the user's most common occasion for today's day type.`;
      })()
    }

RECENTLY WORN ITEMS (avoid if possible):
${recentList}

WARDROBE (use ONLY these items):
${
      wardrobeList ||
      "No items available - return a generic suggestion with empty ids"
    }

OUTFIT RULES:
- Build around one anchor item (outerwear, jacket, or statement piece)
- Choose 2 to 4 supporting items
- Prefer variety - avoid recently worn items unless no strong alternative exists
- Match the occasion and mood if selected
- Match the weather conditions
- Keep the outfit coherent in color, formality and practicality
- If wardrobe is limited, return the best possible combination

VARIETY RULE:
Avoid items worn in the last 3 days unless they are the only strong match.
Prefer underused items when they fit the outfit well.

RATING PREFERENCE:
Items with a high average outfit rating (4+) are proven favourites — prefer them when they fit the occasion and weather.
Items with low average ratings (below 3) should be deprioritised unless no better option exists.

Return ONLY valid JSON in this exact format, no markdown, no explanation:
{
  "title": "${titleName}",
  "description": "one sentence describing the look",
  "styling_note": "one practical tip for wearing this outfit",
  "anchor": {
    "id": "item id or empty string",
    "name": "item name",
    "category": "category",
    "imageUrl": "",
    "slot": "anchor"
  },
  "items": [
    {
      "id": "item id or empty string",
      "name": "item name",
      "category": "category",
      "imageUrl": "",
      "slot": "top or bottom or shoes or accessory"
    }
  ]
}`;

    const reservation = await reserveAiAction(
      supabase,
      requestId,
      "today-suggestion",
    );
    if (!reservation.allowed) {
      return quotaDeniedResponse(reservation, {
        "Access-Control-Allow-Origin": "*",
      });
    }
    pendingRequestId = requestId;
    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
      contents: [{ parts: [{ text: truncateUtf8(prompt, 16_000) }] }],
      generationConfig: {
        maxOutputTokens: 600,
        temperature: 0.7,
      },
    });
    const startedAt = performance.now();
    let geminiResponse: Response;
    try {
      geminiResponse = await withProviderTimeout(geminiRequest);
    } catch (error) {
      const timedOut = error instanceof DOMException &&
        error.name === "AbortError";
      await finalizeAiAction(
        supabase,
        requestId,
        timedOut ? "timeout" : "provider_error",
        timedOut ? "timeout" : "provider_unavailable",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "today-suggestion",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: timedOut ? "timeout" : "provider_unavailable",
        }),
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI provider did not complete the request.",
          code: "AI_PROVIDER_UNAVAILABLE",
        }),
        {
          status: 502,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        },
      );
    }

    if (!geminiResponse.ok) {
      await cancelProviderResponse(geminiResponse);
      await finalizeAiAction(
        supabase,
        requestId,
        "provider_error",
        "provider_rejected",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "today-suggestion",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "provider_rejected",
        }),
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI provider rejected the request.",
          code: "AI_PROVIDER_REJECTED",
        }),
        {
          status: 502,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        },
      );
    }

    const geminiData = await readBoundedResponseJson(geminiResponse) as {
      modelVersion?: unknown;
      candidates?: Array<{ content?: { parts?: Array<{ text?: unknown }> } }>;
      usageMetadata?: {
        promptTokenCount?: unknown;
        candidatesTokenCount?: unknown;
        thoughtsTokenCount?: unknown;
      };
    };
    const modelText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    const text = typeof modelText === "string" ? modelText : "";
    const result = parseTodaySuggestion(text, wardrobeItems);
    if (result.success !== true) {
      await finalizeAiAction(
        supabase,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "today-suggestion",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "invalid_response",
        }),
      );
      return new Response(JSON.stringify(result), {
        status: 502,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    await finalizeAiAction(supabase, requestId, "succeeded");
    pendingRequestId = null;
    console.info(
      JSON.stringify({
        action: "today-suggestion",
        model: GEMINI_MODEL,
        served_model: safeProviderLabel(geminiData.modelVersion),
        latency_ms: Math.round(performance.now() - startedAt),
        input_tokens: safeTokenCount(
          geminiData.usageMetadata?.promptTokenCount,
        ),
        output_tokens: safeTokenCount(
          geminiData.usageMetadata?.candidatesTokenCount,
        ),
        thinking_tokens: safeTokenCount(
          geminiData.usageMetadata?.thoughtsTokenCount,
        ),
      }),
    );

    return new Response(JSON.stringify({ ...result, allowance: reservation }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    if (quotaClient && pendingRequestId) {
      const outcome =
        error instanceof DOMException && error.name === "AbortError"
          ? "timeout"
          : error instanceof SyntaxError || error instanceof RangeError
          ? "invalid_response"
          : "internal_error";
      try {
        await finalizeAiAction(
          quotaClient,
          pendingRequestId,
          outcome,
          outcome === "timeout"
            ? "timeout"
            : outcome === "invalid_response"
            ? "invalid_response"
            : "internal_error",
        );
      } catch { /* reservation still consumes allowance */ }
    }
    console.error(
      "today-suggestion error:",
      error instanceof Error ? error.name : "unknown",
    );
    return new Response(
      JSON.stringify({
        success: false,
        error: "AI outfit suggestions are unavailable. Try again later.",
        code: "AI_UNAVAILABLE",
      }),
      {
        status: 503,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
});
