import { createClient } from "@supabase/supabase-js";
import {
  cancelProviderResponse,
  finalizeAiAction,
  isRecord,
  quotaDeniedResponse,
  readBoundedJson,
  readBoundedResponseJson,
  reserveAiAction,
  type RpcClient,
  safeProviderLabel,
  withProviderTimeout,
} from "../_shared/ai_action.ts";
import { validateAiSuggestionRequest } from "./request_validation.ts";
import {
  createOpenRouterRequest,
  OPENROUTER_MODEL,
} from "./openrouter_request.ts";

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
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
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
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    let requestBody: unknown;
    try {
      requestBody = await readBoundedJson(req, 4_100_000);
    } catch (error) {
      return new Response(
        JSON.stringify({ error: "Invalid request body" }),
        {
          status: error instanceof RangeError ? 413 : 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const validated = validateAiSuggestionRequest(requestBody);
    if (!validated.ok) {
      return new Response(
        JSON.stringify({ error: validated.error }),
        {
          status: validated.status,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
    const { imageBase64, language, userName, userProfile, requestId } =
      validated.value;

    const openRouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
    if (!openRouterApiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI service is not configured.",
          code: "AI_UNAVAILABLE",
        }),
        { status: 503, headers: { "Content-Type": "application/json" } },
      );
    }

    // Fetch style quiz results if not provided by client
    let profile = userProfile;
    if (!profile) {
      const { data: quiz } = await supabaseClient
        .from("style_quiz_results")
        .select("style_profile, preferred_colors, style_goals, style_intention")
        .order("completed_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (quiz) {
        profile = {
          styleProfile: quiz.style_profile,
          preferredColors: Array.isArray(quiz.preferred_colors)
            ? quiz.preferred_colors.join(", ")
            : quiz.preferred_colors,
          styleGoals: Array.isArray(quiz.style_goals)
            ? quiz.style_goals.join(", ")
            : quiz.style_goals,
          styleIntention: quiz.style_intention,
        };
      }
    }

    const reservation = await reserveAiAction(
      supabaseClient,
      requestId,
      "ai-suggestions",
    );
    if (!reservation.allowed) return quotaDeniedResponse(reservation);
    pendingRequestId = requestId;

    // Build personalized name line
    const nameIntro = userName ? `You are styling for ${userName}. ` : "";

    // Build style profile context
    let profileContext = "";
    if (profile) {
      const parts = [];
      if (profile.styleProfile) parts.push(`Style: ${profile.styleProfile}`);
      if (profile.preferredColors) {
        parts.push(`Preferred colors: ${profile.preferredColors}`);
      }
      if (profile.styleGoals) parts.push(`Goals: ${profile.styleGoals}`);
      if (profile.styleIntention) {
        parts.push(`Intention: ${profile.styleIntention}`);
      }
      if (parts.length > 0) {
        profileContext = `\n\nUSER STYLE PROFILE:\n${
          parts.join("\n")
        }\nTailor your suggestions to match this style profile.`;
      }
    }

    const languageInstructions = {
      EN:
        "Analyze this clothing image and provide 2-3 short, friendly styling suggestions in English.",
      FR:
        "Analysez cette image de vêtements et fournissez 2-3 suggestions de style courtes et amicales en français.",
      ES:
        "Analiza esta imagen de ropa y proporciona 2-3 sugerencias de estilo cortas y amigables en español.",
    };

    const systemPrompt =
      `You are a friendly fashion assistant. ${nameIntro}Based on the outfit in the image:
1. First, provide an objective description with bullet points (item type, colors, patterns, style elements)
2. Then give 2-3 short, positive styling suggestions
Be encouraging and constructive. Keep each suggestion to 1-2 sentences.${profileContext}`;

    const providerRequest = createOpenRouterRequest({
      apiKey: openRouterApiKey,
      supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
      imageBase64,
      systemPrompt,
      languageInstruction: languageInstructions[language],
    });
    const startedAt = performance.now();
    let geminiResponse: Response;
    try {
      geminiResponse = await withProviderTimeout(providerRequest);
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
          action: "ai-suggestions",
          model: OPENROUTER_MODEL,
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
          headers: { "Content-Type": "application/json" },
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
          action: "ai-suggestions",
          model: OPENROUTER_MODEL,
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
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const geminiData = await readBoundedResponseJson(geminiResponse);
    const firstChoice =
      isRecord(geminiData) && Array.isArray(geminiData.choices)
        ? geminiData.choices[0]
        : null;
    const firstMessage = isRecord(firstChoice) && isRecord(firstChoice.message)
      ? firstChoice.message
      : null;
    const suggestionContent = firstMessage?.content;
    const suggestions = typeof suggestionContent === "string"
      ? suggestionContent.trim().slice(0, 4_000)
      : "";

    if (!suggestions) {
      await finalizeAiAction(
        supabaseClient,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "ai-suggestions",
          model: OPENROUTER_MODEL,
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
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    await finalizeAiAction(supabaseClient, requestId, "succeeded");
    pendingRequestId = null;
    const usage = isRecord(geminiData) && isRecord(geminiData.usage)
      ? geminiData.usage
      : null;
    console.info(
      JSON.stringify({
        action: "ai-suggestions",
        model: OPENROUTER_MODEL,
        served_model: isRecord(geminiData)
          ? safeProviderLabel(geminiData.model)
          : null,
        provider: isRecord(geminiData)
          ? safeProviderLabel(geminiData.provider)
          : null,
        latency_ms: Math.round(performance.now() - startedAt),
        input_tokens: usage && Number.isSafeInteger(usage.prompt_tokens)
          ? usage.prompt_tokens
          : null,
        output_tokens: usage && Number.isSafeInteger(usage.completion_tokens)
          ? usage.completion_tokens
          : null,
      }),
    );

    return new Response(
      JSON.stringify({
        success: true,
        suggestions: suggestions.trim(),
        language,
        allowance: reservation,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
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
      "AI Suggestions Error:",
      error instanceof Error ? error.name : "unknown",
    );
    return new Response(
      JSON.stringify({
        success: false,
        error: "AI suggestions are unavailable. Try again later.",
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
