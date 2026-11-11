import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const jsonHeaders = { 'Content-Type': 'application/json' }

async function deleteStoragePrefix(adminClient: any, bucket: string, prefix: string): Promise<void> {
  const paths: string[] = []

  async function collect(folder: string): Promise<void> {
    let offset = 0
    while (true) {
      const { data, error } = await adminClient.storage
        .from(bucket)
        .list(folder, { limit: 100, offset, sortBy: { column: 'name', order: 'asc' } })
      if (error) throw new Error(`Unable to list ${bucket}: ${error.message}`)
      if (!data || data.length === 0) break

      for (const entry of data) {
        const path = `${folder}/${entry.name}`
        if (entry.id == null && entry.metadata == null) {
          await collect(path)
        } else {
          paths.push(path)
        }
      }
      if (data.length < 100) break
      offset += data.length
    }
  }

  await collect(prefix)
  for (let index = 0; index < paths.length; index += 100) {
    const { error } = await adminClient.storage
      .from(bucket)
      .remove(paths.slice(index, index + 100))
    if (error) throw new Error(`Unable to delete ${bucket} objects: ${error.message}`)
  }
}

serve(async (req) => {
  try {
    // Get the JWT from the request header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: jsonHeaders,
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
        headers: jsonHeaders,
      })
    }

    // Use service role key to delete the user
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Storage is not covered by database cascades. Abort the deletion if it
    // cannot be removed so the user never receives a false success response.
    await deleteStoragePrefix(adminClient, 'wardrobe-images', user.id)
    await deleteStoragePrefix(adminClient, 'avatars', user.id)

    // Delete outfit_items via join first
    const { data: logs } = await adminClient
      .from('outfit_logs')
      .select('id')
      .eq('user_id', user.id)

    if (logs && logs.length > 0) {
      const ids = logs.map((r: any) => r.id)
      const { error } = await adminClient.from('outfit_items').delete().in('outfit_id', ids)
      if (error) throw new Error(`Unable to delete outfit_items: ${error.message}`)
    }

    const userOwnedTables = [
      'feedback',
      'user_module_progress',
      'user_challenges',
      'style_quiz_results',
      'style_events',
      'wishlist',
      'purchases',
      'outfit_logs',
      'wardrobe_items',
      'user_budget',
      'subscription_transactions',
    ]
    for (const table of userOwnedTables) {
      const { error } = await adminClient.from(table).delete().eq('user_id', user.id)
      if (error) throw new Error(`Unable to delete ${table}: ${error.message}`)
    }

    const { error: profileError } = await adminClient
      .from('user_profiles')
      .delete()
      .eq('id', user.id)
    if (profileError) throw new Error(`Unable to delete user profile: ${profileError.message}`)

    // Finally delete the auth user
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: jsonHeaders,
    })
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : 'Unknown error'
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: jsonHeaders,
    })
  }
})
