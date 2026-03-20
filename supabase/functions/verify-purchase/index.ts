// @ts-nocheck - Deno types not available in VSCode TypeScript server
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

    // Get the RevenueCat customer ID from request body
    const body = await req.json()
    const revenueCatUserId = body.revenue_cat_user_id as string | null

    if (!revenueCatUserId) {
      return new Response(JSON.stringify({ error: 'Missing revenue_cat_user_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify with RevenueCat REST API (v2)
    const rcResponse = await fetch(
      `https://api.revenuecat.com/v2/subscribers/${revenueCatUserId}`,
      {
        headers: {
          'Authorization': `Bearer ${Deno.env.get('REVENUECAT_SECRET_KEY')!}`,
          'Content-Type': 'application/json',
        },
      }
    )

    if (!rcResponse.ok) {
      const errorText = await rcResponse.text()
      return new Response(JSON.stringify({ error: 'RevenueCat verification failed', details: errorText }), {
        status: 402,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rcData = await rcResponse.json()

    // Check if user has an active entitlement (v2 API structure)
    const entitlements = rcData?.subscriber?.entitlements ?? {}
    const entitlement = Object.values(entitlements)[0] as any
    const isPremium = entitlement?.is_period_type !== 'trial' && 
                      (entitlement?.expires_date === null || 
                       entitlement?.expires_date === undefined ||
                       new Date(entitlement?.expires_date) > new Date())

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
      .update({ tier: 'premium' })
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