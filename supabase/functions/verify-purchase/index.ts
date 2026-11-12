import { createClient } from "@supabase/supabase-js";
import {
  evaluateVerifiedEntitlement,
  selectExactEntitlement,
} from "./entitlement.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};
const json = (body: Record<string, unknown>, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const authorization = req.headers.get("Authorization");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!authorization || !supabaseUrl || !anonKey) {
      return json({ error: "Unauthorized" }, 401);
    }

    // Bind every subsequent operation to the server-validated Supabase user.
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: { user }, error: authError } = await userClient.auth
      .getUser();
    if (authError || !user) return json({ error: "Unauthorized" }, 401);

    const entitlementId = Deno.env.get("REVENUECAT_ENTITLEMENT_ID");
    const expectedEnvironment = Deno.env.get("REVENUECAT_EXPECTED_ENVIRONMENT");
    const secretKey = Deno.env.get("REVENUECAT_SECRET_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (
      !entitlementId || !secretKey || !serviceRoleKey ||
      !["production", "sandbox"].includes(expectedEnvironment ?? "")
    ) {
      return json({ error: "Purchase verification is not configured" }, 503);
    }

    // Use the RevenueCat v1 subscriber endpoint and its matching response
    // shape consistently. The customer identifier always comes from auth.getUser.
    const rcResponse = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${
        encodeURIComponent(user.id)
      }`,
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
        },
      },
    );
    if (!rcResponse.ok) {
      // Avoid returning provider response bodies or secret-bearing diagnostics.
      return json({ error: "RevenueCat verification failed" }, 502);
    }

    const rcData: unknown = await rcResponse.json();
    const entitlement = selectExactEntitlement(
      rcData,
      entitlementId,
      expectedEnvironment as "production" | "sandbox",
    );
    const now = Date.now();
    const verifiedEntitlement = evaluateVerifiedEntitlement(
      entitlement,
      now,
    );
    if (!entitlement || !verifiedEntitlement) {
      return json({ error: "Required entitlement is not active" }, 402);
    }
    const fingerprint =
      `${user.id}:${entitlementId}:${verifiedEntitlement.purchaseDate}:${
        verifiedEntitlement.expiresAt ?? "never"
      }`;
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(fingerprint),
    );
    const eventId = `verified:${
      Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0"))
        .join("")
    }`;

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: outcome, error: applyError } = await admin.rpc(
      "apply_subscription_event",
      {
        input_event_id: eventId,
        input_user_id: user.id,
        input_type: "VERIFIED_SNAPSHOT",
        input_event_at: verifiedEntitlement.eventAt,
        input_expires_at: verifiedEntitlement.expiresAt,
        input_entitlement: entitlementId,
        input_payload: {
          source: "revenuecat_v1_snapshot",
          expires_date: verifiedEntitlement.expiresDate,
          grace_period_expires_date: verifiedEntitlement.gracePeriodExpiresDate,
        },
        input_tier: "premium",
        input_status: verifiedEntitlement.status,
      },
    );
    if (applyError) {
      console.error(
        "Could not persist verified subscription state",
        applyError.message,
      );
      return json({ error: "Purchase verification could not be saved" }, 500);
    }

    if (outcome === "applied") return json({ success: true }, 200);

    // A newer webhook may have won the row lock. Confirm the persisted
    // authoritative state before reporting success for a duplicate/stale read.
    const { data: profile, error: profileError } = await admin
      .from("user_profiles")
      .select("tier,subscription_status,subscription_expires_at")
      .eq("id", user.id)
      .maybeSingle();
    const profileExpiry = profile?.subscription_expires_at == null
      ? null
      : Date.parse(profile.subscription_expires_at);
    const persistedStatus = profile?.subscription_status;
    const persistedActive = !profileError && profile?.tier === "premium" &&
      (persistedStatus === "active" &&
          (profileExpiry == null ||
            (Number.isFinite(profileExpiry) && profileExpiry > now)) ||
        ["grace_period", "cancelled"].includes(persistedStatus) &&
          profileExpiry != null &&
          Number.isFinite(profileExpiry) && profileExpiry > now);
    return persistedActive
      ? json({ success: true }, 200)
      : json({ error: "Required entitlement is not active" }, 402);
  } catch (error) {
    console.error("Purchase verification failed", error);
    return json({ error: "Purchase verification failed" }, 500);
  }
});
