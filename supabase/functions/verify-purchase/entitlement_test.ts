import {
  evaluateVerifiedEntitlement,
  selectExactEntitlement,
} from "./entitlement.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, received ${
        JSON.stringify(actual)
      }`,
    );
  }
}

const now = Date.parse("2026-01-10T12:00:00.000Z");

Deno.test("selects only the exact configured RevenueCat entitlement", () => {
  const response = {
    subscriber: {
      entitlements: {
        premium: { purchase_date: "2026-01-01T00:00:00Z" },
        other: { purchase_date: "2026-01-01T00:00:00Z" },
      },
    },
  };
  assertEquals(selectExactEntitlement(response, "premium"), {
    purchase_date: "2026-01-01T00:00:00Z",
  });
  assertEquals(selectExactEntitlement(response, "missing"), null);
  assertEquals(selectExactEntitlement({ subscriber: [] }, "premium"), null);
});

Deno.test("accepts a current entitlement and lifetime purchase", () => {
  assertEquals(
    evaluateVerifiedEntitlement({
      purchase_date: "2026-01-01T00:00:00Z",
      expires_date: "2026-02-01T00:00:00Z",
    }, now),
    {
      eventAt: "2026-01-01T00:00:00.000Z",
      expiresAt: "2026-02-01T00:00:00.000Z",
      purchaseDate: "2026-01-01T00:00:00Z",
      expiresDate: "2026-02-01T00:00:00Z",
      gracePeriodExpiresDate: null,
      status: "active",
    },
  );
  assertEquals(
    evaluateVerifiedEntitlement({ purchase_date: "2026-01-01T00:00:00Z" }, now)
      ?.expiresAt,
    null,
  );
});

Deno.test("accepts valid billing grace only through its grace expiry", () => {
  const entitlement = {
    purchase_date: "2025-12-01T00:00:00Z",
    expires_date: "2026-01-05T00:00:00Z",
    grace_period_expires_date: "2026-01-15T00:00:00Z",
  };
  assertEquals(
    evaluateVerifiedEntitlement(entitlement, now)?.status,
    "grace_period",
  );
  assertEquals(
    evaluateVerifiedEntitlement(
      entitlement,
      Date.parse("2026-01-16T00:00:00Z"),
    ),
    null,
  );
});

Deno.test("fails closed for expired or malformed purchase/expiry dates", () => {
  assertEquals(
    evaluateVerifiedEntitlement({
      purchase_date: "2025-12-01T00:00:00Z",
      expires_date: "2026-01-05T00:00:00Z",
    }, now),
    null,
  );
  assertEquals(
    evaluateVerifiedEntitlement({
      purchase_date: "2026-01-01T00:00:00Z",
      expires_date: "not-a-date",
    }, now),
    null,
  );
  assertEquals(
    evaluateVerifiedEntitlement({
      purchase_date: "not-a-date",
      expires_date: null,
    }, now),
    null,
  );
});
