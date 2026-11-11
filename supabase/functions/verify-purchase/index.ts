import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Verify the caller is authenticated
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const revenueCatUserId = user.id
    const entitlementId = Deno.env.get('REVENUECAT_ENTITLEMENT_ID')
    const secretKey = Deno.env.get('REVENUECAT_SECRET_KEY')
    if (!entitlementId || !secretKey) throw new Error('RevenueCat is not configured')

    // Verify with the RevenueCat v1 subscriber endpoint.
    const rcResponse = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(revenueCatUserId)}`,
      {
        headers: {
          'Authorization': `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
      }
    )

    if (!rcResponse.ok) {
      return new Response(JSON.stringify({ error: 'RevenueCat verification failed' }), {
        status: 402,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rcData = await rcResponse.json()

    // RevenueCat v1 subscriber response. Require the exact configured
    // entitlement; missing/unknown data always fails closed.
    const entitlements = rcData?.subscriber?.entitlements ?? {}
    const entitlement = entitlements[entitlementId] as {
      expires_date?: string | null
      grace_period_expires_date?: string | null
    } | undefined
    const expiry = entitlement?.grace_period_expires_date ?? entitlement?.expires_date
    const isPremium = entitlement !== undefined &&
      (expiry === null || (typeof expiry === 'string' && new Date(expiry) > new Date()))

    if (!isPremium) {
      return new Response(JSON.stringify({ error: 'No active entitlement found' }), {
        status: 402,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Only now write to DB — purchase is verified
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // First check if user profile exists
    const { data: existingProfile } = await adminClient
      .from('user_profiles')
      .select('id')
      .eq('id', user.id)
      .single()

    if (!existingProfile) {
      return new Response(JSON.stringify({ error: 'User profile not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { error: updateError } = await adminClient
      .from('user_profiles')
      .update({
        tier: 'premium',
        subscription_status: entitlement?.grace_period_expires_date ? 'grace_period' : 'active',
        subscription_expires_at: expiry ?? null,
        revenuecat_customer_id: user.id,
      })
      .eq('id', user.id)

    if (updateError) {
      return new Response(JSON.stringify({ error: 'Failed to update user tier', details: updateError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : 'Unknown error'
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
