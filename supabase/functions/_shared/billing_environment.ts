export type BillingEnvironment = "production" | "sandbox";

export function parseBillingEnvironment(
  value: unknown,
): BillingEnvironment | null {
  if (typeof value !== "string") return null;
  switch (value.trim().toLowerCase()) {
    case "production":
      return "production";
    case "sandbox":
      return "sandbox";
    default:
      return null;
  }
}

export function revenueCatEnvironmentMatches(
  eventEnvironment: unknown,
  expectedEnvironment: BillingEnvironment,
): boolean {
  const parsed = parseBillingEnvironment(eventEnvironment);
  return parsed === expectedEnvironment;
}
