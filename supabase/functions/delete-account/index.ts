// @ts-nocheck
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get the JWT from the request header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Create a client with the user's JWT to verify their identity
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify the user is authenticated
    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Use service role key to delete the user
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // First reset all their data (same order as ResetService)
    const tables = [
      'outfit_items', // handled separately via join
      'outfit_logs',
      'wardrobe_items',
      'purchases',
      'wishlist',
      'user_challenges',
      'style_events',
      'style_quiz_results',
      'user_budget',
      'user_module_progress',
      'user_profiles',
    ]

    // Delete outfit_items via join first
    const { data: logs } = await adminClient
      .from('outfit_logs')
      .select('id')
      .eq('user_id', user.id)

    if (logs && logs.length > 0) {
      const ids = logs.map((r: any) => r.id)
      await adminClient.from('outfit_items').delete().in('outfit_id', ids)
    }

    // Delete all other tables
    for (const table of tables.slice(1)) {
      await adminClient.from(table).delete().eq('user_id', user.id)
    }

    // Finally delete the auth user
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : 'Unknown error'
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})