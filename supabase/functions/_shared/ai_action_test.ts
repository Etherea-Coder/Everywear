import {
  isRequestId,
  quotaDeniedResponse,
  readBoundedJson,
  readBoundedResponseJson,
  reserveAiAction,
  safeProviderLabel,
  safeTokenCount,
  truncateUtf8,
  withProviderTimeout,
} from "./ai_action.ts";

const requestA = "123e4567-e89b-42d3-a456-426614174000";

Deno.test("request IDs are UUID v4 and invalid IDs cannot reach reservation", () => {
  if (
    !isRequestId(requestA) ||
    isRequestId("123e4567-e89b-12d3-a456-426614174000")
  ) {
    throw new Error("UUID validation did not enforce version and variant");
  }
});

Deno.test("body reader enforces streamed byte limits and parses bounded JSON", async () => {
  const parsed = await readBoundedJson(
    new Request("https://local.invalid", {
      method: "POST",
      body: JSON.stringify({ requestId: requestA }),
    }),
    100,
  );
  if (
    !parsed || typeof parsed !== "object" ||
    (parsed as { requestId?: string }).requestId !== requestA
  ) {
    throw new Error("Expected bounded JSON body");
  }
  let rejected = false;
  try {
    await readBoundedJson(
      new Request("https://local.invalid", {
        method: "POST",
        body: "x".repeat(101),
      }),
      100,
    );
  } catch (error) {
    rejected = error instanceof RangeError;
  }
  if (!rejected) throw new Error("Oversized streamed JSON was accepted");
});

Deno.test("prompt byte limiter never cuts through a UTF-8 character", () => {
  const value = truncateUtf8("a🙂b", 5);
  if (value !== "a🙂" || new TextEncoder().encode(value).byteLength !== 5) {
    throw new Error(
      "UTF-8 prompt truncation exceeded or split its byte budget",
    );
  }
});

Deno.test("provider token telemetry accepts only finite nonnegative integers", () => {
  if (
    safeTokenCount(7) !== 7 || safeTokenCount(1.5) !== null ||
    safeTokenCount(-1) !== null || safeTokenCount(Number.NaN) !== null
  ) {
    throw new Error("Provider token metadata was not validated");
  }
});

Deno.test("provider model labels are bounded and contain no free-form data", () => {
  if (
    safeProviderLabel("google/gemini-2.5-flash-lite") !==
      "google/gemini-2.5-flash-lite" ||
    safeProviderLabel("model\nwith prompt") !== null ||
    safeProviderLabel("x".repeat(101)) !== null
  ) {
    throw new Error("Provider model label was not safely bounded");
  }
});

Deno.test("reservation fails closed on RPC errors and translates limit responses", async () => {
  let calls = 0;
  let rejected = false;
  try {
    await reserveAiAction(
      {
        rpc(name, args) {
          calls++;
          if (name !== "reserve_ai_action" || args?.p_request_id !== requestA) {
            throw new Error("Wrong RPC call");
          }
          return Promise.resolve({
            data: null,
            error: new Error("database unavailable"),
          });
        },
      },
      requestA,
      "today-suggestion",
    );
  } catch {
    rejected = true;
  }
  if (!rejected || calls !== 1) {
    throw new Error("Quota RPC failure did not fail closed");
  }
  const response = quotaDeniedResponse({
    allowed: false,
    reason: "monthly",
    month_resets_at: "2030-02-01T00:00:00Z",
  });
  if (
    response.status !== 429 ||
    !(await response.text()).includes("AI_LIMIT_MONTHLY")
  ) {
    throw new Error("Monthly denial was not actionable");
  }
});

Deno.test("provider response reader rejects oversized JSON bodies", async () => {
  let rejected = false;
  try {
    await readBoundedResponseJson(new Response("x".repeat(20)), 10);
  } catch (error) {
    rejected = error instanceof RangeError;
  }
  if (!rejected) throw new Error("Oversized provider response was accepted");
});

Deno.test("provider request timeout aborts the one attempted fetch", async () => {
  let aborted = false;
  const pending = withProviderTimeout(
    new Request("https://provider.invalid", { method: "POST", body: "{}" }),
    5,
    (request: Request) =>
      new Promise<Response>((_resolve, reject) => {
        request.signal.addEventListener("abort", () => {
          aborted = true;
          reject(new DOMException("Aborted", "AbortError"));
        }, { once: true });
      }),
  );
  try {
    await pending;
  } catch (error) {
    if (!(error instanceof DOMException) || error.name !== "AbortError") {
      throw error;
    }
  }
  if (!aborted) throw new Error("Timed out provider call did not abort");
});
