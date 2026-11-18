import {
  finalizeCoachAction,
  reconcileStaleCoachActions,
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
