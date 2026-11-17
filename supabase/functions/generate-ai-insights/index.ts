import { createClient } from "@supabase/supabase-js";
import { extractGeminiText, parseAiInsights } from "./ai_response.ts";
import { createGeminiRequest } from "../_shared/gemini_request.ts";
import {
  normalizeResponseLocale,
  responseLanguageName,
} from "../_shared/response_locale.ts";
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

type WardrobeItem = {
  id: string;
  name: string;
  category: string | null;
  semantic_label: string | null;
  wear_count: number | null;
  last_worn: string | null;
  cost_per_wear: number | string | null;
  purchase_price: number | string | null;
  purchase_date: string | null;
};

type OutfitItemLink = { item_id: string | null };

type OutfitLog = {
  id: string;
  worn_date: string;
  occasion: string | null;
  rating: number | null;
  outfit_items: OutfitItemLink[] | null;
};

const GEMINI_MODEL = "gemini-2.5-flash-lite";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Extracts a colour keyword from semantic_label (no `color` column exists in DB)
const COLOUR_KEYWORDS = [
  "black",
  "white",
  "gray",
  "grey",
  "brown",
  "beige",
  "cream",
  "navy",
  "blue",
  "red",
  "green",
  "yellow",
  "orange",
  "pink",
  "purple",
  "burgundy",
  "camel",
  "khaki",
  "olive",
  "coral",
  "teal",
  "gold",
  "silver",
  "tan",
];

function extractColour(semanticLabel: string): string | null {
  if (!semanticLabel) return null;
  const lower = semanticLabel.toLowerCase();
  return COLOUR_KEYWORDS.find((c) => lower.includes(c)) ?? null;
}

Deno.serve(async (req) => {
  let quotaClient: RpcClient | null = null;
  let pendingRequestId: string | null = null;
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });

  try {
    // ── Auth (identical pattern to style-coach) ───────────────────────────
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
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
      });
    }

    const body = await readBoundedJson(req, 4096);
    if (
      !body || typeof body !== "object" || Array.isArray(body) ||
      !isRequestId((body as Record<string, unknown>).requestId)
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Invalid request identifier or body.",
        }),
        { status: 400, headers: CORS },
      );
    }
    const requestId = (body as Record<string, unknown>).requestId as string;
    const responseLocale = normalizeResponseLocale(
      (body as Record<string, unknown>).responseLocale,
    );
    const responseLanguage = responseLanguageName(responseLocale);
    const timeRangeInput = (body as Record<string, unknown>).timeRange ??
      "month";
    const categoryInput = (body as Record<string, unknown>).category ?? null;
    if (
      !["week", "month", "season"].includes(String(timeRangeInput)) ||
      (categoryInput !== null &&
        (typeof categoryInput !== "string" || categoryInput.length > 64))
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Unsupported insight filter.",
        }),
        { status: 400, headers: CORS },
      );
    }
    const timeRange = timeRangeInput as "week" | "month" | "season";
    const category = categoryInput as string | null;

    // ── Date window ───────────────────────────────────────────────────────
    const now = new Date();
    const start = new Date();
    if (timeRange === "week") start.setDate(now.getDate() - 7);
    if (timeRange === "month") start.setMonth(now.getMonth() - 1);
    if (timeRange === "season") start.setMonth(now.getMonth() - 3);

    // ── Fetch wardrobe items ──────────────────────────────────────────────
    // wear_count / last_worn / cost_per_wear already maintained by DB — no need to compute
    let wardrobeQ = supabase
      .from("wardrobe_items")
      .select(
        "id, name, category, semantic_label, wear_count, last_worn, cost_per_wear, purchase_price, purchase_date",
      )
      .eq("user_id", user.id);

    if (category) wardrobeQ = wardrobeQ.eq("category", category);

    const { data: itemRows, error: itemsErr } = await wardrobeQ.limit(250);
    if (itemsErr) throw new Error(`wardrobe_items: ${itemsErr.message}`);
    const items: WardrobeItem[] = (itemRows ?? []) as WardrobeItem[];

    // ── Fetch outfit logs (used for silhouette evolution only) ────────────
    // outfit_items uses `item_id`, NOT `wardrobe_item_id`
    const { data: logRows, error: logsErr } = await supabase
      .from("outfit_logs")
      .select("id, worn_date, occasion, rating, outfit_items(item_id)")
      .eq("user_id", user.id)
      .gte("worn_date", start.toISOString())
      .limit(250);
    if (logsErr) throw new Error(`outfit_logs: ${logsErr.message}`);
    const logs: OutfitLog[] = (logRows ?? []) as OutfitLog[];

    // ── Compute per-item average ratings from outfit logs ─────────────────
    const itemRatingAccum: Record<string, number[]> = {};
    logs.forEach((log) => {
      const rating = log.rating;
      if (rating == null) return;
      log.outfit_items?.forEach((oi) => {
        if (!oi.item_id) return;
        if (!itemRatingAccum[oi.item_id]) itemRatingAccum[oi.item_id] = [];
        itemRatingAccum[oi.item_id].push(rating);
      });
    });
    const itemRatingAverages: Record<
      string,
      { avg: number; count: number; name?: string }
    > = {};
    for (const [id, ratings] of Object.entries(itemRatingAccum)) {
      const avg = ratings.reduce((a, b) => a + b, 0) / ratings.length;
      const item = items.find((i) => i.id === id);
      itemRatingAverages[id] = {
        avg: Math.round(avg * 10) / 10,
        count: ratings.length,
        name: item?.name ?? undefined,
      };
    }

    // Top-rated and lowest-rated items for AI prompt
    const ratedItems = Object.entries(itemRatingAverages)
      .filter(([, v]) => v.count >= 2)
      .sort(([, a], [, b]) => b.avg - a.avg);
    const topRated = ratedItems.slice(0, 5);
    const lowestRated = ratedItems.filter(([, v]) => v.avg < 3).slice(0, 3);

    // ── Fetch style quiz (all available columns for richer AI context) ────
    const { data: quiz } = await supabase
      .from("style_quiz_results")
      .select(
        "style_profile, preferred_colors, style_goals, style_intention, answers",
      )
      .order("completed_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    // ══════════════════════════════════════════════════════════════════════
    // PURE DATA — no AI needed
    // ══════════════════════════════════════════════════════════════════════

    // ── Dominant colours (from semantic_label — no color column in DB) ────
    const colourCount: Record<string, number> = {};
    items.forEach((i) => {
      const c = extractColour(i.semantic_label ?? "");
      if (c) colourCount[c] = (colourCount[c] ?? 0) + 1;
    });
    const sortedColours = Object.entries(colourCount).sort(([, a], [, b]) =>
      b - a
    ).slice(0, 4);
    const dominantColors = sortedColours.map(([c]) =>
      c.charAt(0).toUpperCase() + c.slice(1)
    );
    const colorPercentages = sortedColours.map(([, n]) =>
      Math.round((n / Math.max(items.length, 1)) * 100)
    );

    // ── Versatility scores (top 4 by wear_count from DB) ─────────────────
    const versatilityScores = [...items]
      .sort((a, b) => (b.wear_count ?? 0) - (a.wear_count ?? 0))
      .slice(0, 4)
      .map((item) => ({
        item: item.name,
        score: Math.min(100, Math.round(((item.wear_count ?? 0) / 20) * 100)),
        combinations: item.wear_count ?? 0,
      }));

    // ── Underutilized items (last_worn from DB — no log joins needed) ─────
    const underutilizedItems = items
      .map((item) => {
        const last = item.last_worn ? new Date(item.last_worn) : null;
        const days = last
          ? Math.floor((now.getTime() - last.getTime()) / 86_400_000)
          : 999;
        return {
          item: item.name,
          lastWorn: `${days} days ago`,
          suggestions: 2,
          _days: days,
        };
      })
      .filter((i) => i._days > 30)
      .sort((a, b) => b._days - a._days)
      .slice(0, 3)
      .map(({ _days, ...rest }) => rest);

    // ── Sustainability (cost_per_wear from DB) ────────────────────────────
    const cpwValues = items
      .map((i) => i.cost_per_wear)
      .filter((v): v is number | string => v !== null)
      .map(Number)
      .filter(Number.isFinite);

    const avgCostPerWear = cpwValues.length
      ? Math.round(
        (cpwValues.reduce((a, b) => a + b, 0) / cpwValues.length) * 100,
      ) / 100
      : 0;

    const recentPurchases = items.filter((i) => {
      const d = i.purchase_date ? new Date(i.purchase_date) : null;
      return d && d > start;
    }).length;

    const sustainabilityMetrics = {
      avgCostPerWear,
      costTrend: -12.5,
      purchaseFrequency: recentPurchases,
      carbonImpact: recentPurchases * 15,
      carbonGoal: 200,
      sustainabilityGoalProgress: Math.min(
        100,
        Math.max(0, Math.round((1 - recentPurchases / 10) * 100)),
      ),
    };

    // ── Silhouette evolution (semantic_label keywords, last 3 months) ─────
    const MONTH_LABELS = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    const FITTED_KEYWORDS = [
      "fitted",
      "slim",
      "skinny",
      "tailored",
      "formal",
      "structured",
      "blazer",
      "pencil",
    ];
    const RELAXED_KEYWORDS = [
      "oversized",
      "loose",
      "relaxed",
      "wide",
      "baggy",
      "flowy",
      "jogger",
      "sweat",
      "hoodie",
      "casual",
    ];

    const itemMap = new Map(
      items.map((item): [string, WardrobeItem] => [item.id, item]),
    );

    const silhouetteEvolution = [2, 1, 0].map((offset) => {
      const d = new Date(now.getFullYear(), now.getMonth() - offset, 1);
      let fitted = 0, relaxed = 0;

      logs
        .filter((log) => {
          const ld = new Date(log.worn_date);
          return ld.getMonth() === d.getMonth() &&
            ld.getFullYear() === d.getFullYear();
        })
        .forEach((log) => {
          log.outfit_items?.forEach((oi) => {
            const item = oi.item_id ? itemMap.get(oi.item_id) : undefined;
            const label = (item?.semantic_label ?? "").toLowerCase();
            if (FITTED_KEYWORDS.some((f) => label.includes(f))) fitted++;
            else if (RELAXED_KEYWORDS.some((r) => label.includes(r))) relaxed++;
          });
        });

      const total = fitted + relaxed || 1;
      return {
        month: MONTH_LABELS[d.getMonth()],
        fitted: Math.round((fitted / total) * 100),
        relaxed: Math.round((relaxed / total) * 100),
      };
    });

    // ══════════════════════════════════════════════════════════════════════
    // GEMINI — style profile + recommendations (same API as style-coach)
    // ══════════════════════════════════════════════════════════════════════
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
          headers: { ...CORS, "Content-Type": "application/json" },
        },
      );
    }

    const categoryBreakdown = items.reduce<Record<string, number>>((acc, i) => {
      acc[i.category ?? "other"] = (acc[i.category ?? "other"] ?? 0) + 1;
      return acc;
    }, {});

    const quizContext = quiz
      ? {
        styleProfile: quiz.style_profile,
        preferredColors: quiz.preferred_colors,
        styleGoals: quiz.style_goals,
        styleIntention: quiz.style_intention,
        answers: quiz.answers,
      }
      : {};

    const prompt =
      `You are a fashion AI analyst. Analyze this wardrobe and return ONLY a raw JSON object — no markdown, no explanation, no code block.
Write user-facing prose fields (styleProfile, emergingStyles, titles, descriptions, reasoning) in ${responseLanguage}. Preserve fixed response keys and type values exactly as specified.

WARDROBE SUMMARY:
- Total items: ${items.length}
- Category breakdown: ${JSON.stringify(categoryBreakdown)}
- Dominant colors: ${dominantColors.join(", ")}
- Outfit logs in period: ${logs.length}
- Occasions logged: ${
        [...new Set(logs.map((log) => log.occasion).filter(Boolean))].join(
          ", ",
        ) || "none"
      }

USER STYLE PROFILE (from quiz):
${JSON.stringify(quizContext)}

${
        topRated.length > 0
          ? `TOP-RATED ITEMS (by outfit rating):
${
            topRated.map(([, v]) =>
              `- ${v.name ?? "Unknown"}: avg ${v.avg}/5 (${v.count} outfits)`
            ).join("\n")
          }
These are proven favourites — prefer recommending outfits around them.`
          : ""
      }

${
        lowestRated.length > 0
          ? `LOWEST-RATED ITEMS:
${
            lowestRated.map(([, v]) =>
              `- ${v.name ?? "Unknown"}: avg ${v.avg}/5 (${v.count} outfits)`
            ).join("\n")
          }
Consider suggesting alternative styling or replacement for these.`
          : ""
      }

Return exactly this structure:
{
  "confidenceScore": <integer 60-95>,
  "styleProfile": "<2-3 word label like Casual Minimalist>",
  "emergingStyles": ["<style1>", "<style2>"],
  "recommendations": [
    {
      "type": "gap",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    },
    {
      "type": "seasonal",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    },
    {
      "type": "style",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    }
  ]
}`;

    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
      contents: [{ parts: [{ text: truncateUtf8(prompt, 16_000) }] }],
      generationConfig: {
        maxOutputTokens: 800,
        temperature: 0.4,
      },
    });
    const reservation = await reserveAiAction(
      supabase,
      requestId,
      "generate-ai-insights",
    );
    if (!reservation.allowed) return quotaDeniedResponse(reservation, CORS);
    pendingRequestId = requestId;
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
          action: "generate-ai-insights",
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
          headers: { ...CORS, "Content-Type": "application/json" },
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
          action: "generate-ai-insights",
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
          headers: { ...CORS, "Content-Type": "application/json" },
        },
      );
    }

    const geminiData: unknown = await readBoundedResponseJson(geminiResponse);
    const rawText = extractGeminiText(geminiData);
    if (rawText === null || rawText.length > 10_000) {
      await finalizeAiAction(
        supabase,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "generate-ai-insights",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "invalid_response",
        }),
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI returned an unusable response.",
          code: "AI_INVALID_RESPONSE",
        }),
        {
          status: 502,
          headers: { ...CORS, "Content-Type": "application/json" },
        },
      );
    }
    const aiInsights = parseAiInsights(rawText);
    if (
      aiInsights.confidenceScore === undefined || !aiInsights.styleProfile ||
      !aiInsights.recommendations?.length
    ) {
      await finalizeAiAction(
        supabase,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "generate-ai-insights",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "invalid_response",
        }),
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI returned an incomplete response.",
          code: "AI_INVALID_RESPONSE",
        }),
        {
          status: 502,
          headers: { ...CORS, "Content-Type": "application/json" },
        },
      );
    }

    // ── Final response — matches _aiData shape in ai_intelligence.dart exactly
    const result = {
      confidenceScore: aiInsights.confidenceScore ?? 70,
      styleProfile: aiInsights.styleProfile ?? quiz?.style_profile ??
        "Modern Casual",
      dominantColors,
      colorPercentages,
      silhouetteEvolution,
      emergingStyles: aiInsights.emergingStyles ?? [],
      versatilityScores,
      underutilizedItems,
      sustainabilityMetrics,
      recommendations: aiInsights.recommendations ?? [],
      topRatedItems: topRated.map(([id, v]) => ({
        id,
        name: v.name,
        avgRating: v.avg,
        outfitCount: v.count,
      })),
    };

    await finalizeAiAction(supabase, requestId, "succeeded");
    pendingRequestId = null;
    console.info(
      JSON.stringify({
        action: "generate-ai-insights",
        model: GEMINI_MODEL,
        served_model: isRecord(geminiData)
          ? safeProviderLabel(geminiData.modelVersion)
          : null,
        latency_ms: Math.round(performance.now() - startedAt),
        input_tokens: isRecord(geminiData) && isRecord(geminiData.usageMetadata)
          ? safeTokenCount(geminiData.usageMetadata.promptTokenCount)
          : null,
        output_tokens:
          isRecord(geminiData) && isRecord(geminiData.usageMetadata)
            ? safeTokenCount(geminiData.usageMetadata.candidatesTokenCount)
            : null,
        thinking_tokens:
          isRecord(geminiData) && isRecord(geminiData.usageMetadata)
            ? safeTokenCount(geminiData.usageMetadata.thoughtsTokenCount)
            : null,
      }),
    );

    return new Response(JSON.stringify({ ...result, allowance: reservation }), {
      headers: { ...CORS, "Content-Type": "application/json" },
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
      "generate-ai-insights error:",
      error instanceof Error ? error.name : "unknown",
    );
    return new Response(
      JSON.stringify({
        success: false,
        error: "AI insights are unavailable. Try again later.",
        code: "AI_UNAVAILABLE",
      }),
      { status: 503, headers: { ...CORS, "Content-Type": "application/json" } },
    );
  }
});
