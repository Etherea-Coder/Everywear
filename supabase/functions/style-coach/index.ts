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
import { isCoachMode, parseCoachResponse } from "./coach_response.ts";
import { selectTopRatedItems } from "./item_ratings.ts";

const GEMINI_MODEL = "gemini-2.5-flash-lite";

type RecentOutfit = {
  date?: string;
  items?: string[];
  rating?: number;
  name?: string;
  occasion?: string;
};

type SilhouetteMonth = { month: string; fitted: number; relaxed: number };

function boundedString(value: unknown, maxLength: number): string | undefined {
  return typeof value === "string"
    ? value.trim().slice(0, maxLength)
    : undefined;
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

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    quotaClient = supabaseClient;

    const { data: { user }, error: authError } = await supabaseClient.auth
      .getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    let requestBody: unknown;
    try {
      requestBody = await readBoundedJson(req, 32_768);
    } catch (error) {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: error instanceof RangeError ? 413 : 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    if (!isRecord(requestBody)) {
      return new Response(JSON.stringify({ error: "Invalid coach request" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
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
    if (!isCoachMode(body.mode)) {
      return new Response(JSON.stringify({ error: "Invalid coach mode" }), {
        status: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    const mode = body.mode;
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
    const rawInsights = isRecord(body.insights) ? body.insights : {};
    const insights = {
      totalItems: typeof rawInsights.totalItems === "number" &&
          Number.isFinite(rawInsights.totalItems)
        ? Math.max(0, Math.min(100_000, rawInsights.totalItems))
        : 0,
      topCategory: boundedString(rawInsights.topCategory, 80),
      topOccasion: boundedString(rawInsights.topOccasion, 80),
    };
    const wardrobeSummary = boundedString(body.wardrobeSummary, 1000);
    const recentOutfits: RecentOutfit[] = Array.isArray(body.recentOutfits)
      ? body.recentOutfits.slice(0, 20).flatMap((raw: unknown) => {
        if (!isRecord(raw)) return [];
        const items = Array.isArray(raw.items)
          ? raw.items.slice(0, 12).flatMap((value: unknown) => {
            const item = boundedString(value, 80);
            return item ? [item] : [];
          })
          : [];
        return [{
          date: boundedString(raw.date, 40),
          name: boundedString(raw.name, 80),
          occasion: boundedString(raw.occasion, 80),
          rating: typeof raw.rating === "number" && Number.isFinite(raw.rating)
            ? Math.max(0, Math.min(5, raw.rating))
            : undefined,
          items,
        }];
      })
      : [];
    const rawPatterns = isRecord(body.occasionPatterns)
      ? body.occasionPatterns
      : {};
    const boundedCounts = (value: unknown): Record<string, number> =>
      isRecord(value)
        ? Object.fromEntries(
          Object.entries(value)
            .filter(([key, count]) =>
              key.length <= 60 && typeof count === "number" &&
              Number.isFinite(count) && count >= 0
            )
            .slice(0, 20)
            .map(([key, count]) => [key, Math.min(count as number, 1000)]),
        )
        : {};
    const occasionPatterns = {
      weekday: boundedCounts(rawPatterns.weekday),
      weekend: boundedCounts(rawPatterns.weekend),
    };
    const itemRatings = isRecord(body.itemRatings)
      ? Object.fromEntries(Object.entries(body.itemRatings).slice(0, 40))
      : {};
    const rawEvolution = isRecord(body.silhouetteEvolution)
      ? body.silhouetteEvolution
      : {};
    const silhouetteEvolution = {
      months: Array.isArray(rawEvolution.months)
        ? rawEvolution.months.slice(0, 3).flatMap((raw: unknown) => {
          if (
            !isRecord(raw) || typeof raw.fitted !== "number" ||
            !Number.isFinite(raw.fitted) ||
            typeof raw.relaxed !== "number" || !Number.isFinite(raw.relaxed)
          ) return [];
          const month = boundedString(raw.month, 20);
          return month
            ? [{
              month,
              fitted: Math.max(0, Math.min(100, raw.fitted)),
              relaxed: Math.max(0, Math.min(100, raw.relaxed)),
            }]
            : [];
        })
        : [],
      trend: boundedString(rawEvolution.trend, 40),
    };
    const question = boundedString(body.question, 2000);
    const rawEvent = isRecord(body.event) ? body.event : {};
    const event = {
      daysLeft: typeof rawEvent.daysLeft === "number" &&
          Number.isFinite(rawEvent.daysLeft)
        ? Math.max(-365, Math.min(3650, Math.trunc(rawEvent.daysLeft)))
        : undefined,
      title: boundedString(rawEvent.title, 80),
      type: boundedString(rawEvent.type, 80),
      date: boundedString(rawEvent.date, 40),
      dressCode: boundedString(rawEvent.dressCode, 80),
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

    const guardrails = `
IMPORTANT:
- Do not shame the user
- Do not mention body weight or sensitive appearance assumptions
- Do not recommend expensive purchases unless truly necessary
- Do not invent wardrobe items that are not provided
- If data is missing, be transparent and still helpful
- Sound like a supportive, tasteful stylist friend — not a chatbot or fashion influencer`;

    const profileBlock = `
USER PROFILE:
${userName ? `- Name: ${userName}` : ""}
- Style profile: ${userProfile?.styleProfile ?? "Not set yet"}
- Preferred colors: ${userProfile?.preferredColors ?? "Not specified"}
- Style goals: ${userProfile?.styleGoals ?? "Not specified"}
- Style intention (in their own words): ${
      userProfile?.styleIntention ?? "Not provided"
    }`;

    const insightsBlock = `
WARDROBE DATA:
- Total items: ${insights?.totalItems ?? 0}
- Top category: ${insights?.topCategory ?? "Unknown"}
- Top occasion: ${insights?.topOccasion ?? "Casual"}
- Wardrobe summary: ${wardrobeSummary ?? "Limited data available"}`;

    // Build recent outfit history block
    let recentOutfitsBlock = "";
    if (Array.isArray(recentOutfits) && recentOutfits.length > 0) {
      const lines = recentOutfits.map((o: RecentOutfit) => {
        const date = o.date
          ? new Date(o.date).toLocaleDateString("en-GB", {
            day: "numeric",
            month: "short",
          })
          : "?";
        const items = Array.isArray(o.items) && o.items.length > 0
          ? o.items.join(", ")
          : "no item details";
        const rating = o.rating ? ` — rated ${o.rating}/5` : "";
        return `- ${date}: "${o.name ?? "Unnamed"}" — ${items} (${
          o.occasion ?? "Unknown"
        }${rating})`;
      }).join("\n");
      recentOutfitsBlock = `\n\nRECENT OUTFIT HISTORY (last 7 days):\n${lines}`;
    }

    // Build habit patterns block
    let habitBlock = "";
    if (occasionPatterns && typeof occasionPatterns === "object") {
      const weekday = occasionPatterns.weekday ?? {};
      const weekend = occasionPatterns.weekend ?? {};
      const fmtTop = (counts: Record<string, number>) => {
        const entries = Object.entries(counts).sort(([, a], [, b]) => b - a);
        if (entries.length === 0) return "no data yet";
        return entries.slice(0, 3).map(([k, v]) => `${k} (${v}x)`).join(", ");
      };
      if (Object.keys(weekday).length > 0 || Object.keys(weekend).length > 0) {
        habitBlock = `\n\nHABIT PATTERNS (last 60 days):\n- Weekdays: ${
          fmtTop(weekday)
        }\n- Weekends: ${fmtTop(weekend)}`;
      }
    }

    // Build top-rated items block from item rating averages
    let ratingsBlock = "";
    if (itemRatings && typeof itemRatings === "object") {
      // itemRatings is { itemId: { avg_rating, rated_count } } — we don't have names here,
      // but recent outfits already carry item names. Build a summary of top-rated items.
      const entries = selectTopRatedItems(itemRatings);
      if (entries.length > 0) {
        const lines = entries.map(({ id, avg_rating, rated_count }) =>
          `- Item ${
            id.slice(0, 8)
          }… avg ${avg_rating}/5 across ${rated_count} outfits`
        ).join("\n");
        ratingsBlock =
          `\n\nITEM RATING FEEDBACK:\nThe user rates their outfits. These items consistently appear in high-rated outfits — prefer them when building suggestions:\n${lines}`;
      }
    }

    // Build style evolution narrative block
    let evolutionBlock = "";
    if (silhouetteEvolution && typeof silhouetteEvolution === "object") {
      const months = silhouetteEvolution.months;
      const trend = silhouetteEvolution.trend;
      if (Array.isArray(months) && months.length > 0 && trend) {
        const monthLines = months.map((m: SilhouetteMonth) =>
          `- ${m.month}: ${m.fitted}% fitted, ${m.relaxed}% relaxed`
        ).join("\n");
        const trendNote = trend !== "stable"
          ? `The user is ${trend}. Acknowledge this positively and build on it in your advice.`
          : "The user's style silhouette has been consistent \u2014 acknowledge their confidence in their look.";
        evolutionBlock =
          `\n\nSTYLE EVOLUTION (last 3 months):\n${monthLines}\n${trendNote}`;
      }
    }

    let prompt = "";
    const nameIntro = userName ? ` for ${userName}` : "";

    if (mode === "passive") {
      let timeString = "unknown";
      if (typeof localHour === "number") {
        if (localHour >= 5 && localHour < 12) timeString = "Morning";
        else if (localHour >= 12 && localHour < 17) timeString = "Afternoon";
        else if (localHour >= 17 && localHour < 21) timeString = "Evening";
        else timeString = "Night";
      }
      const timeContext = typeof localHour === "number"
        ? `\nCURRENT CONTEXT:\n- Time of Day: ${timeString} (local hour: ${localHour})\n- Instruction: Subtly nod to the time of day if it makes the tip feel more relevant (e.g. morning prep, afternoon slump, evening planning).`
        : "";

      prompt =
        `You are a personal style coach${nameIntro} inside a wardrobe app.
Your job is to give one short weekly coaching tip. Be warm, encouraging, concise, and practical.
Do not sound like a chatbot or fashion magazine. Base advice only on the user data below.
${profileBlock}
${insightsBlock}${recentOutfitsBlock}${habitBlock}${ratingsBlock}${evolutionBlock}${timeContext}
${guardrails}

TASK:
Give exactly one coaching tip for this week.
- Be specific and personal
- Reference the user's recent outfit choices if available — notice patterns, suggest variety, or compliment repeated favourites
- Use habit patterns to anticipate today's likely occasion if relevant
- Suggest one realistic action
- 2 to 4 sentences maximum
- Start with a short observation, then one practical suggestion
- Output only the tip text, nothing else`;
    } else if (mode === "active") {
      prompt =
        `You are a personal style coach${nameIntro} inside a wardrobe app.
Help users style themselves using their own wardrobe, style profile, and goals.
Be helpful, personal, concise, and confident.
${profileBlock}
${insightsBlock}${recentOutfitsBlock}${habitBlock}${ratingsBlock}${evolutionBlock}
${guardrails}

USER QUESTION:
${question}

TASK:
Answer as their personal style coach. Prioritize items they already own.
If relevant, reference their recent outfit history to give context-aware advice.
Keep the answer under 180 words. The "next_step" must be a concrete action, never a question. Example: "Try pairing your blazer with white trousers this week".
Output a JSON object with keys: "answer" and "next_step"`;
    } else if (mode === "event") {
      const daysLeft = event?.daysLeft ?? "?";
      prompt =
        `You are a personal style coach${nameIntro} inside a wardrobe app.
Help users prepare outfits for real upcoming events. Be personal, practical, and appropriate.
Use the user existing wardrobe first. Do not invent wardrobe items not provided.
${profileBlock}
${insightsBlock}${recentOutfitsBlock}${habitBlock}${ratingsBlock}${evolutionBlock}

EVENT:
- Title: ${event?.title ?? "Unknown"}
- Type: ${event?.type ?? "Other"}
- Date: ${event?.date ?? "Unknown"}
- Days left: ${daysLeft}
- Dress code: ${event?.dressCode ?? "Not specified"}
${guardrails}

TASK:
Suggest up to 3 outfit directions for this event. Keep full answer under 220 words.
If relevant, reference recent outfits to avoid repeats or build on successful looks.
Output a JSON object with keys: "intro", "outfit_1", "outfit_2", "outfit_3", "prep_tip"`;
    }

    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
      contents: [{ parts: [{ text: truncateUtf8(prompt, 16_000) }] }],
      generationConfig: {
        maxOutputTokens: 400,
        temperature: 0.7,
      },
    });
    const reservation = await reserveAiAction(
      supabaseClient,
      requestId,
      "style-coach",
    );
    if (!reservation.allowed) {
      return quotaDeniedResponse(reservation, {
        "Access-Control-Allow-Origin": "*",
      });
    }
    pendingRequestId = requestId;
    const startedAt = performance.now();
    let geminiResponse: Response;
    try {
      geminiResponse = await withProviderTimeout(geminiRequest);
    } catch (error) {
      const timedOut = error instanceof DOMException &&
        error.name === "AbortError";
      await finalizeAiAction(
        supabaseClient,
        requestId,
        timedOut ? "timeout" : "provider_error",
        timedOut ? "timeout" : "provider_unavailable",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "style-coach",
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
        supabaseClient,
        requestId,
        "provider_error",
        "provider_rejected",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "style-coach",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "provider_rejected",
          provider_status: geminiResponse.status,
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
    const result = parseCoachResponse(mode, text);
    if (result.success !== true) {
      await finalizeAiAction(
        supabaseClient,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "style-coach",
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

    await finalizeAiAction(supabaseClient, requestId, "succeeded");
    pendingRequestId = null;
    console.info(
      JSON.stringify({
        action: "style-coach",
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
      "style-coach error:",
      error instanceof Error ? error.name : "unknown",
    );
    return new Response(
      JSON.stringify({
        success: false,
        error: "Style coaching is unavailable. Try again later.",
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
