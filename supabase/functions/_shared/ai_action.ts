export const AI_ACTIONS = [
  "analyze-clothing",
  "ai-suggestions",
  "today-suggestion",
  "style-coach",
  "generate-ai-insights",
] as const;

export type AiAction = typeof AI_ACTIONS[number];
export type RpcClient = {
  rpc: (
    name: string,
    args?: Record<string, unknown>,
  ) => PromiseLike<{ data: unknown; error: unknown }>;
};

export type Reservation = {
  allowed: boolean;
  reason?: "monthly" | "daily" | "burst" | "concurrency" | "duplicate";
  month_remaining?: number;
  day_remaining?: number;
  burst_remaining?: number;
  month_resets_at?: string;
  day_resets_at?: string;
  burst_resets_at?: string;
  allowance?: Record<string, unknown>;
};

const providerTimeouts = new WeakMap<Response, ReturnType<typeof setTimeout>>();

export function isRequestId(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value);
}

export async function readBoundedJson(
  request: Request,
  maxBytes: number,
): Promise<unknown> {
  const declared = Number(request.headers.get("content-length") ?? 0);
  if (Number.isFinite(declared) && declared > maxBytes) {
    throw new RangeError("request_too_large");
  }
  if (!request.body) throw new SyntaxError("invalid_json");
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) {
        await reader.cancel();
        throw new RangeError("request_too_large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const body = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder().decode(body)) as unknown;
  } catch {
    throw new SyntaxError("invalid_json");
  }
}

export async function readBoundedResponseJson(
  response: Response,
  maxBytes = 65_536,
): Promise<unknown> {
  const declared = Number(response.headers.get("content-length") ?? 0);
  if (Number.isFinite(declared) && declared > maxBytes) {
    await response.body?.cancel();
    clearProviderTimeout(response);
    throw new RangeError("provider_response_too_large");
  }
  if (!response.body) {
    clearProviderTimeout(response);
    throw new SyntaxError("invalid_provider_response");
  }
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) {
        await reader.cancel();
        throw new RangeError("provider_response_too_large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
    clearProviderTimeout(response);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder().decode(bytes)) as unknown;
  } catch {
    throw new SyntaxError("invalid_provider_response");
  }
}

export async function reserveAiAction(
  client: RpcClient,
  requestId: string,
  action: AiAction,
): Promise<Reservation> {
  const { data, error } = await client.rpc("reserve_ai_action", {
    p_request_id: requestId,
    p_action_name: action,
  });
  if (error || !isRecord(data) || typeof data.allowed !== "boolean") {
    throw new Error("quota_unavailable");
  }
  return data as Reservation;
}

export async function finalizeAiAction(
  client: RpcClient,
  requestId: string,
  outcome:
    | "succeeded"
    | "provider_error"
    | "timeout"
    | "invalid_response"
    | "internal_error",
  errorCode?:
    | "provider_unavailable"
    | "provider_rejected"
    | "invalid_response"
    | "timeout"
    | "internal_error",
): Promise<void> {
  // Shared handlers keep charged attempts. Style-coach uses a separate
  // server-only finalizer for its scoped refund rule.
  const { error } = await client.rpc("finalize_ai_action", {
    p_request_id: requestId,
    p_outcome: outcome,
    p_error_code: errorCode ?? null,
  });
  if (error) throw new Error("quota_finalization_failed");
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function safeTokenCount(value: unknown): number | null {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0
    ? value
    : null;
}

export function safeProviderLabel(value: unknown): string | null {
  return typeof value === "string" && value.length <= 100 &&
      /^[A-Za-z0-9._:/ -]+$/.test(value)
    ? value
    : null;
}

export function truncateUtf8(value: string, maxBytes: number): string {
  const encoder = new TextEncoder();
  let output = "";
  let bytes = 0;
  for (const character of value) {
    const size = encoder.encode(character).byteLength;
    if (bytes + size > maxBytes) break;
    output += character;
    bytes += size;
  }
  return output;
}

export function quotaDeniedResponse(
  reservation: Reservation,
  headers: Record<string, string> = {},
): Response {
  const status = reservation.reason === "duplicate" ? 409 : 429;
  return new Response(
    JSON.stringify({
      success: false,
      error: reservation.reason === "duplicate"
        ? "This AI request was already submitted. Start a new request to try again."
        : "AI allowance reached. Try again after the reset time.",
      code: reservation.reason === "duplicate"
        ? "AI_REQUEST_DUPLICATE"
        : `AI_LIMIT_${(reservation.reason ?? "unavailable").toUpperCase()}`,
      allowance: reservation.allowance ?? reservation,
    }),
    {
      status,
      headers: { "Content-Type": "application/json", ...headers },
    },
  );
}

export function withProviderTimeout(
  request: Request,
  timeoutMs = 20_000,
  fetcher: (request: Request) => Promise<Response> = (request) =>
    fetch(request),
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  return fetcher(new Request(request, { signal: controller.signal })).then(
    (response) => {
      providerTimeouts.set(response, timeout);
      return response;
    },
    (error: unknown) => {
      clearTimeout(timeout);
      throw error;
    },
  );
}

export async function cancelProviderResponse(
  response: Response,
): Promise<void> {
  try {
    await response.body?.cancel();
  } finally {
    clearProviderTimeout(response);
  }
}

function clearProviderTimeout(response: Response): void {
  const timeout = providerTimeouts.get(response);
  if (timeout !== undefined) clearTimeout(timeout);
  providerTimeouts.delete(response);
}
