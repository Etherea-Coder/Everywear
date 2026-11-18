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
