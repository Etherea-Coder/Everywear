// @ts-nocheck
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const today = new Date().toISOString().split("T")[0];

    const { data: profile, error: fetchError } = await adminClient
      .from("user_profiles")
      .select("tier, daily_suggestions_used, suggestions_reset_at")
      .eq("id", user.id)
      .single();

    if (fetchError || !profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const tier = (profile.tier as string) || "free";
    const used = (profile.daily_suggestions_used as number) || 0;
    const resetAt = profile.suggestions_reset_at as string | null;

    const dailyLimit = tier === "premium" ? 999999 : tier === "essential" ? 10 : 3;

    if (resetAt !== today) {
      await adminClient
        .from("user_profiles")
        .update({
          daily_suggestions_used: 1,
          suggestions_reset_at: today,
        })
        .eq("id", user.id);

      return new Response(
        JSON.stringify({ allowed: true, daily_suggestions_used: 1, daily_limit: dailyLimit }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (used >= dailyLimit) {
      return new Response(
        JSON.stringify({ allowed: false, daily_suggestions_used: used, daily_limit: dailyLimit }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    await adminClient.rpc("increment_daily_suggestions", { user_id_input: user.id });

    return new Response(
      JSON.stringify({ allowed: true, daily_suggestions_used: used + 1, daily_limit: dailyLimit }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : "Unknown error";
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});