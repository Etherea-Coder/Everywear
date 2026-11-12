import {
  parseBillingEnvironment,
  revenueCatEnvironmentMatches,
} from "./billing_environment.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, received ${String(actual)}`);
  }
}

Deno.test("parses configured RevenueCat environments fail-closed", () => {
  assertEquals(parseBillingEnvironment("production"), "production");
  assertEquals(parseBillingEnvironment("SANDBOX"), "sandbox");
  assertEquals(parseBillingEnvironment(undefined), null);
  assertEquals(parseBillingEnvironment("test"), null);
});

Deno.test("webhook events cannot cross production and sandbox environments", () => {
  assertEquals(revenueCatEnvironmentMatches("PRODUCTION", "production"), true);
  assertEquals(revenueCatEnvironmentMatches("SANDBOX", "production"), false);
  assertEquals(revenueCatEnvironmentMatches(undefined, "production"), false);
  assertEquals(revenueCatEnvironmentMatches("SANDBOX", "sandbox"), true);
});
