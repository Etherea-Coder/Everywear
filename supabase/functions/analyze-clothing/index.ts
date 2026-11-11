import { createClient } from 'jsr:@supabase/supabase-js@2'

const GEMINI_MODEL = 'gemini-2.5-flash-lite'
const GOOGLE_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { imageBase64 } = await req.json()
    if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
      return new Response(JSON.stringify({ error: 'Missing imageBase64' }), { status: 400 })
    }
    if (imageBase64.length > 10_000_000) {
      return new Response(JSON.stringify({ error: 'Image is too large' }), { status: 413 })
    }

    const { data: allowed, error: quotaError } = await userClient.rpc(
      'consume_ai_quota',
      { quota_kind: 'suggestion' },
    )
    if (quotaError) throw new Error(`Quota check failed: ${quotaError.message}`)
    if (allowed !== true) {
      return new Response(JSON.stringify({ error: 'AI quota reached' }), { status: 429 })
    }

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    const prompt = `Analyze this clothing item image and respond ONLY with a JSON object in this exact format:
{
  "category": one of ["Tops", "Bottoms", "Shoes", "Outerwear", "Accessories", "Dresses", "Activewear"],
  "color": main color as a single word,
  "material": likely material as a single word,
  "confidence": a number between 0.5 and 0.99,
  "style_vibe": one of ["Casual", "Formal", "Sport", "Elegant", "Street"]
}
Respond with ONLY the JSON, no other text.`

    const geminiResponse = await fetch(`${GOOGLE_API_URL}?key=${googleAiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            { inline_data: { mime_type: 'image/jpeg', data: imageBase64 } }
          ]
        }],
        generationConfig: { maxOutputTokens: 200, temperature: 0.1 },
      }),
    })

    if (!geminiResponse.ok) {
      const err = await geminiResponse.text()
      throw new Error(`Gemini error: ${err}`)
    }

    const geminiData = await geminiResponse.json()
    const text = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''

    const jsonMatch = text.match(/\{[\s\S]*\}/)
    if (!jsonMatch) throw new Error('No JSON in response')

    const result = JSON.parse(jsonMatch[0])

    return new Response(JSON.stringify({ success: true, ...result }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  } catch (error) {
    console.error('analyze-clothing error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Clothing analysis failed.' }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
