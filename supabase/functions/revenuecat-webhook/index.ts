import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0'

interface RevenueCatEvent {
  type: string
  app_user_id: string
  product_id?: string
  expiration_at_ms?: number
  store?: string
}

serve(async (req) => {
  try {
    // Verify the request is from RevenueCat
    const authHeader = req.headers.get('Authorization')
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
    
    if (!webhookSecret || authHeader !== `Bearer ${webhookSecret}`) {
      return new Response('Unauthorized', { status: 401 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // RevenueCat sends the event directly in the request body
    const event: RevenueCatEvent = await req.json()
    const { type, app_user_id, product_id, expiration_at_ms, store } = event

    // Map RevenueCat event types to subscription status
    const activeEvents = [
      'INITIAL_PURCHASE',
      'RENEWAL',
      'PRODUCT_CHANGE',
      'REACTIVATION',
      'NON_RENEWING_PURCHASE',
    ]

    const inactiveEvents = [
      'EXPIRATION',
      'CANCELLATION',
      'BILLING_ISSUE',
    ]

    let tier: string | null = null

    if (activeEvents.includes(type)) {
      tier = 'premium'
    } else if (inactiveEvents.includes(type)) {
      tier = 'free'
    } else {
      // Ignore other event types (e.g. TEST, TRANSFER)
      return new Response(JSON.stringify({ received: true, type: type }), { status: 200 })
    }

    const expiresAt = expiration_at_ms
      ? new Date(expiration_at_ms).toISOString()
      : null

    // Update user_profiles — app_user_id is the Supabase user ID
    // (only works if you call Purchases.logIn(user.id) in your app)
    const { error: profileError } = await supabase
      .from('user_profiles')
      .update({
        tier,
        subscription_expires_at: expiresAt,
        revenue_cat_id: app_user_id,
      })
      .eq('id', app_user_id)

    if (profileError) {
      console.error('Profile update error:', profileError)
      // Continue even if profile doesn't exist (user might not have completed onboarding)
    }

    // Store transaction record if we have a product_id
    if (product_id) {
      const { error: transactionError } = await supabase
        .from('subscription_transactions')
        .upsert({
          user_id: app_user_id,
          product_id,
          event_type: type,
          store: store || 'unknown',
          expires_at: expiresAt,
          created_at: new Date().toISOString(),
        }, { onConflict: 'user_id,product_id,event_type' })

      if (transactionError) {
        console.error('Transaction upsert error:', transactionError)
      }
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 })

  } catch (error) {
    console.error('RevenueCat webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400 },
    )
  }
})
