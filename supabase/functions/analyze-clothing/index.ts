import { createClient } from "@supabase/supabase-js";
import { createGeminiRequest } from "../_shared/gemini_request.ts";
import {
  normalizeResponseLocale,
  responseLanguageName,
} from "../_shared/response_locale.ts";
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
  safeTokenCount,
  withProviderTimeout,
} from "../_shared/ai_action.ts";
import {
  buildClothingAnalysisPrompt,
  parseClothingAnalysis,
  validateImageRequest,
} from "./clothing_analysis.ts";

const GEMINI_MODEL = "gemini-2.5-flash-lite";
const CORS_HEADERS = { "Access-Control-Allow-Origin": "*" };

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
        headers: CORS_HEADERS,
      });
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    quotaClient = userClient;
    const { data: { user }, error: authError } = await userClient.auth
      .getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    let requestBody: unknown;
    try {
      requestBody = await readBoundedJson(req, 4_100_000);
    } catch (error) {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: error instanceof RangeError ? 413 : 400,
        headers: CORS_HEADERS,
      });
    }
    const validated = validateImageRequest(requestBody);
    if (!validated.ok) {
      return new Response(JSON.stringify({ error: validated.error }), {
        status: validated.status,
        headers: CORS_HEADERS,
      });
    }
    const { imageBase64, requestId } = validated;
    const requestBodyRecord = isRecord(requestBody) ? requestBody : {};
    const responseLocale = normalizeResponseLocale(
      requestBodyRecord.responseLocale,
    );
    const responseLanguage = responseLanguageName(responseLocale);

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
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    const reservation = await reserveAiAction(
      userClient,
      requestId,
      "analyze-clothing",
    );
    if (!reservation.allowed) {
      return quotaDeniedResponse(reservation, CORS_HEADERS);
    }
    pendingRequestId = requestId;

    const prompt = buildClothingAnalysisPrompt(responseLanguage);

    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
      contents: [{
        parts: [
          { text: prompt },
          { inline_data: { mime_type: "image/jpeg", data: imageBase64 } },
        ],
      }],
      generationConfig: { maxOutputTokens: 200, temperature: 0.1 },
    });
    const startedAt = performance.now();
    let geminiResponse: Response;
    try {
      geminiResponse = await withProviderTimeout(geminiRequest);
    } catch (error) {
      await finalizeAiAction(
        userClient,
        requestId,
        error instanceof DOMException && error.name === "AbortError"
          ? "timeout"
          : "provider_error",
        error instanceof DOMException && error.name === "AbortError"
          ? "timeout"
          : "provider_unavailable",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "analyze-clothing",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "provider_unavailable",
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
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    if (!geminiResponse.ok) {
      await cancelProviderResponse(geminiResponse);
      await finalizeAiAction(
        userClient,
        requestId,
        "provider_error",
        "provider_rejected",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "analyze-clothing",
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
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
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
    const result = parseClothingAnalysis(text);
    if (!result) {
      await finalizeAiAction(
        userClient,
        requestId,
        "invalid_response",
        "invalid_response",
      );
      pendingRequestId = null;
      console.info(
        JSON.stringify({
          action: "analyze-clothing",
          model: GEMINI_MODEL,
          latency_ms: Math.round(performance.now() - startedAt),
          error: "invalid_response",
        }),
      );
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI returned an unusable analysis.",
          code: "AI_INVALID_RESPONSE",
        }),
        {
          status: 502,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    await finalizeAiAction(userClient, requestId, "succeeded");
    pendingRequestId = null;
    const usage = geminiData.usageMetadata;
    console.info(
      JSON.stringify({
        action: "analyze-clothing",
        model: GEMINI_MODEL,
        served_model: safeProviderLabel(geminiData.modelVersion),
        latency_ms: Math.round(performance.now() - startedAt),
        input_tokens: safeTokenCount(usage?.promptTokenCount),
        output_tokens: safeTokenCount(usage?.candidatesTokenCount),
        thinking_tokens: safeTokenCount(usage?.thoughtsTokenCount),
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
      "analyze-clothing failed",
      error instanceof Error ? error.name : "unknown",
    );
    return new Response(
      JSON.stringify({
        success: false,
        error:
          "Clothing analysis is unavailable. Enter details manually and retry later.",
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
