import type { RpcClient } from "../_shared/ai_action.ts";

export type CoachOutcome =
  | "succeeded"
  | "provider_error"
  | "timeout"
  | "invalid_response"
  | "internal_error";

/** Server-role RPC only. A caller JWT must never have refund authority. */
export async function finalizeCoachAction(
  client: RpcClient,
  userId: string,
  requestId: string,
  outcome: CoachOutcome,
  errorCode?: string,
): Promise<void> {
  const { data, error } = await client.rpc("finalize_style_coach_action", {
    p_user_id: userId,
    p_request_id: requestId,
    p_outcome: outcome,
    p_error_code: errorCode ?? null,
  });
  if (error || data !== true) throw new Error("coach_finalization_failed");
}

/** Valid advice remains deliverable when the success RPC outcome is uncertain.
 * The reservation must never be finalized as a failure after this point.
 */
export async function respondWithValidatedCoachAdvice(
  client: RpcClient,
  userId: string,
  requestId: string,
  advice: Record<string, string | boolean>,
  allowance: unknown,
): Promise<Response> {
  try {
    await finalizeCoachAction(client, userId, requestId, "succeeded");
  } catch {
    // The RPC may have committed before the transport failed. Stale
    // reconciliation closes reservations that really remain open.
    console.error(
      "style-coach accounting error: success_finalization_uncertain",
    );
  }
  return new Response(JSON.stringify({ ...advice, allowance }), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

export async function reconcileStaleCoachActions(
  client: RpcClient,
  userId: string,
): Promise<void> {
  const { data, error } = await client.rpc(
    "reconcile_stale_style_coach_actions",
    { p_user_id: userId },
  );
  if (error || typeof data !== "number") {
    throw new Error("coach_reconciliation_failed");
  }
}
