import { createClient } from 'jsr:@supabase/supabase-js@2'

type RevenueCatEvent = {
  id: string
  type: string
  app_user_id: string
  entitlement_ids?: string[]
  event_timestamp_ms?: number
  expiration_at_ms?: number | null
  grace_period_expiration_at_ms?: number | null
}

Deno.serve(async (req) => {
  try {
    const secret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
    if (!secret || req.headers.get('Authorization') !== `Bearer ${secret}`) {
      return new Response('Unauthorized', { status: 401 })
    }

    const body = await req.json() as { event?: RevenueCatEvent }
    const event = body.event
    if (!event?.id || !event.type || !event.app_user_id ||
        !Number.isFinite(event.event_timestamp_ms)) {
      return Response.json({ error: 'Invalid RevenueCat event envelope' }, { status: 400 })
    }

    const entitlementId = Deno.env.get('REVENUECAT_ENTITLEMENT_ID')
    if (!entitlementId) throw new Error('REVENUECAT_ENTITLEMENT_ID not configured')

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )
    const eventAt = new Date(event.event_timestamp_ms!).toISOString()
    const accessUntil = Math.max(event.expiration_at_ms ?? 0,
      event.grace_period_expiration_at_ms ?? 0)
    const expiresAt = accessUntil > 0 ? new Date(accessUntil).toISOString() : null

    // Ignore events for other entitlements when RevenueCat supplies the list.
    if (!event.entitlement_ids?.includes(entitlementId)) {
      return Response.json({ received: true, irrelevant: true })
    }

    let tier = 'premium'
    let status = 'active'
    if (event.type === 'EXPIRATION') {
      tier = 'free'; status = 'expired'
    } else if (event.type === 'CANCELLATION') {
      // Cancellation disables renewal but access remains through expiration.
      const stillActive = event.expiration_at_ms != null && event.expiration_at_ms > Date.now()
      tier = stillActive ? 'premium' : 'free'; status = stillActive ? 'cancelled' : 'expired'
    } else if (event.type === 'BILLING_ISSUE') {
      const graceUntil = event.grace_period_expiration_at_ms ?? 0
      tier = graceUntil > Date.now() ? 'premium' : 'free'
      status = graceUntil > Date.now() ? 'grace_period' : 'expired'
    } else if (!['INITIAL_PURCHASE','RENEWAL','PRODUCT_CHANGE','REACTIVATION','NON_RENEWING_PURCHASE'].includes(event.type)) {
      return Response.json({ received: true, ignored: true })
    }

    if (tier === 'premium' && accessUntil <= Date.now()) {
      tier = 'free'; status = 'expired'
    }
    const { data: outcome, error: updateError } = await admin.rpc('apply_subscription_event', {
      input_event_id: event.id,
      input_user_id: event.app_user_id,
      input_type: event.type,
      input_event_at: eventAt,
      input_expires_at: expiresAt,
      input_entitlement: entitlementId,
      input_payload: body,
      input_tier: tier,
      input_status: status,
    })
    if (updateError) throw updateError

    return Response.json({ received: true, outcome })
  } catch (error) {
    console.error('RevenueCat webhook error', error)
    return Response.json({ error: 'Webhook processing failed' }, { status: 500 })
  }
})
