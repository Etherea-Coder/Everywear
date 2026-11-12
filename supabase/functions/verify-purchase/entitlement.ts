type JsonObject = Record<string, unknown>;

export type VerifiedEntitlement = {
  eventAt: string;
  expiresAt: string | null;
  purchaseDate: string;
  expiresDate: string | null;
  gracePeriodExpiresDate: string | null;
  status: "active" | "grace_period";
};

function isRecord(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function selectExactEntitlement(
  response: unknown,
  entitlementId: string,
): JsonObject | null {
  if (!isRecord(response) || !isRecord(response.subscriber)) return null;
  const entitlements = response.subscriber.entitlements;
  if (!isRecord(entitlements)) return null;
  const entitlement = entitlements[entitlementId];
  return isRecord(entitlement) ? entitlement : null;
}

function parseOptionalDate(value: unknown): number | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string" || value.trim().length === 0) return undefined;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

export function evaluateVerifiedEntitlement(
  entitlement: unknown,
  now: number,
): VerifiedEntitlement | null {
  if (!isRecord(entitlement)) return null;

  const purchaseDate = entitlement.purchase_date;
  if (typeof purchaseDate !== "string" || purchaseDate.trim().length === 0) {
    return null;
  }
  const purchaseMs = Date.parse(purchaseDate);
  if (!Number.isFinite(purchaseMs)) return null;

  const regularExpiryMs = parseOptionalDate(entitlement.expires_date);
  const graceExpiryMs = parseOptionalDate(
    entitlement.grace_period_expires_date,
  );
  if (regularExpiryMs === undefined || graceExpiryMs === undefined) return null;

  const finiteExpiries = [regularExpiryMs, graceExpiryMs].filter(
    (value): value is number => value !== null,
  );
  const expiryMs = finiteExpiries.length === 0
    ? null
    : Math.max(...finiteExpiries);
  if (expiryMs !== null && expiryMs <= now) return null;

  const isInGrace = graceExpiryMs !== null && graceExpiryMs > now &&
    (regularExpiryMs === null || regularExpiryMs <= now);
  return {
    eventAt: new Date(purchaseMs).toISOString(),
    expiresAt: expiryMs === null ? null : new Date(expiryMs).toISOString(),
    purchaseDate,
    expiresDate: typeof entitlement.expires_date === "string"
      ? entitlement.expires_date
      : null,
    gracePeriodExpiresDate:
      typeof entitlement.grace_period_expires_date === "string"
        ? entitlement.grace_period_expires_date
        : null,
    status: isInGrace ? "grace_period" : "active",
  };
}
