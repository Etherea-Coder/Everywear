import {
  finalizeCoachAction,
  reconcileStaleCoachActions,
  respondWithValidatedCoachAdvice,
} from "./coach_quota.ts";

const uid = "11111111-1111-4111-8111-111111111111";
const requestId = "22222222-2222-4222-8222-222222222222";

Deno.test("coach finalization uses the server-only RPC and exact identity", async () => {
  const calls: Array<{ name: string; args?: Record<string, unknown> }> = [];
  const client = {
    rpc(name: string, args?: Record<string, unknown>) {
      calls.push({ name, args });
      return Promise.resolve({ data: true, error: null });
    },
  };
  await reconcileStaleCoachActions({
    rpc(name, args) {
      calls.push({ name, args });
      return Promise.resolve({ data: 0, error: null });
    },
  }, uid);
  await finalizeCoachAction(client, uid, requestId, "succeeded");
  if (
    calls[0].name !== "reconcile_stale_style_coach_actions" ||
    calls[0].args?.p_user_id !== uid ||
    calls[1].name !== "finalize_style_coach_action" ||
    calls[1].args?.p_user_id !== uid ||
    calls[1].args?.p_request_id !== requestId ||
    calls[1].args?.p_outcome !== "succeeded"
  ) throw new Error("Coach used the wrong protected RPC contract");
});

Deno.test("uncertain success finalization returns validated advice without refund", async () => {
  const calls: Array<Record<string, unknown> | undefined> = [];
  const advice = {
    success: true,
    mode: "active",
    answer: "Wear the blue shirt.",
    next_step: "Try it with your dark trousers.",
  };
  const originalError = console.error;
  const errors: unknown[][] = [];
  console.error = (...args: unknown[]) => {
    errors.push(args);
  };
  try {
    const response = await respondWithValidatedCoachAdvice(
      {
        rpc: (_name, args) => {
          calls.push(args);
          return Promise.resolve({
            data: null,
            error: new Error("transport failed"),
          });
        },
      },
      uid,
      requestId,
      advice,
      { allowed: true },
    );
    const body = await response.json();
    if (
      response.status !== 200 || body.answer !== advice.answer ||
      body.next_step !== advice.next_step || calls.length !== 1 ||
      calls[0]?.p_outcome !== "succeeded"
    ) {
      throw new Error("Valid advice was lost or a refund was attempted");
    }
    if (
      errors.length !== 1 ||
      errors[0][0] !==
        "style-coach accounting error: success_finalization_uncertain"
    ) {
      throw new Error("Accounting failure was not logged safely");
    }
  } finally {
    console.error = originalError;
  }
});

Deno.test("duplicate or failed finalization cannot be treated as success", async () => {
  for (
    const result of [
      { data: false, error: null },
      { data: null, error: new Error("unavailable") },
    ]
  ) {
    let failed = false;
    try {
      await finalizeCoachAction(
        { rpc: () => Promise.resolve(result) },
        uid,
        requestId,
        "provider_error",
        "provider_rejected",
      );
    } catch {
      failed = true;
    }
    if (!failed) throw new Error("Finalization failure was ignored");
  }
});
