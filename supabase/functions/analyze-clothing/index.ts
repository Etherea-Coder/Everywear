import { createClient } from '@supabase/supabase-js'
import { createGeminiRequest } from '../_shared/gemini_request.ts'
import {
  parseClothingAnalysis,
  validateImageRequest,
} from './clothing_analysis.ts'

const GEMINI_MODEL = 'gemini-2.5-flash-lite'
const CORS_HEADERS = { 'Access-Control-Allow-Origin': '*' }

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
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: CORS_HEADERS,
      })
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: CORS_HEADERS,
      })
    }

    let requestBody: unknown
    try {
      requestBody = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid request body' }), {
        status: 400,
        headers: CORS_HEADERS,
      })
    }
    const validated = validateImageRequest(requestBody)
    if (!validated.ok) {
      return new Response(JSON.stringify({ error: validated.error }), {
        status: validated.status,
        headers: CORS_HEADERS,
      })
    }
    const { imageBase64 } = validated

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    const { data: allowed, error: quotaError } = await userClient.rpc(
      'consume_ai_quota',
      { quota_kind: 'suggestion' },
    )
    if (quotaError) throw new Error('Quota check failed')
    if (allowed !== true) {
      return new Response(JSON.stringify({ error: 'AI quota reached' }), {
        status: 429,
        headers: CORS_HEADERS,
      })
    }

    const prompt = `Analyze this clothing item image and respond ONLY with a JSON object in this exact format:
{
  "category": one of ["Tops", "Bottoms", "Shoes", "Outerwear", "Accessories", "Dresses", "Activewear"],
  "color": main color as a single word,
  "material": likely material as a single word,
  "confidence": a number between 0.5 and 0.99,
  "style_vibe": one of ["Casual", "Formal", "Sport", "Elegant", "Street"]
}
Respond with ONLY the JSON, no other text.`

    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
        contents: [{
          parts: [
            { text: prompt },
            { inline_data: { mime_type: 'image/jpeg', data: imageBase64 } }
          ]
        }],
        generationConfig: { maxOutputTokens: 200, temperature: 0.1 },
    })
    const geminiResponse = await fetch(geminiRequest)

    if (!geminiResponse.ok) {
      const err = await geminiResponse.text()
      throw new Error(`Gemini error: ${err}`)
    }

    const geminiData = await geminiResponse.json()
    const text = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    const result = parseClothingAnalysis(text)
    if (!result) {
      return new Response(JSON.stringify({ success: false, error: 'Invalid analysis response.' }), {
        status: 502,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  } catch {
    console.error('analyze-clothing failed')
    return new Response(
      JSON.stringify({ success: false, error: 'Clothing analysis failed.' }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
