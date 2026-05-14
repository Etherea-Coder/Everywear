import { createClient } from 'jsr:@supabase/supabase-js@2'

const GEMINI_MODEL = 'gemini-2.5-flash-lite'
const GOOGLE_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`

const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') || '').split(',').filter(Boolean)
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGINS.length > 0 ? ALLOWED_ORIGINS.join(',') : '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function corsResponse(body: string, status = 200, extraHeaders: Record<string, string> = {}): Response {
  return new Response(body, {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS, ...extraHeaders },
  })
}

function isPrivateIP(hostname: string): boolean {
  return /^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|127\.|0\.|169\.254\.|::1|fc00:|fe80:)/i.test(hostname)
}

function isValidImageUrl(url: string): boolean {
  try {
    const parsed = new URL(url)
    if (!['https:', 'http:'].includes(parsed.protocol)) return false
    if (isPrivateIP(parsed.hostname)) return false
    return true
  } catch {
    return false
  }
}

interface RequestBody {
  imageUrl: string
  language: 'EN' | 'FR' | 'ES'
}

const VALID_LANGUAGES = ['EN', 'FR', 'ES']

function uint8ArrayToBase64(bytes: Uint8Array): string {
  const chunkSize = 8192
  let binary = ''
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length))
    binary += String.fromCharCode(...chunk)
  }
  return btoa(binary)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS })
  }

  try {
    const { imageUrl, language }: RequestBody = await req.json()

    if (!imageUrl || !language) {
      return corsResponse(JSON.stringify({ error: 'Missing required fields: imageUrl and language' }), 400)
    }

    if (!VALID_LANGUAGES.includes(language)) {
      return corsResponse(JSON.stringify({ error: 'Invalid language. Must be EN, FR, or ES' }), 400)
    }

    if (!isValidImageUrl(imageUrl)) {
      return corsResponse(JSON.stringify({ error: 'Invalid or disallowed image URL' }), 400)
    }

    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return corsResponse(JSON.stringify({ error: 'Missing authorization header' }), 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error('Supabase environment variables not configured')
    }

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return corsResponse(JSON.stringify({ error: 'Unauthorized' }), 401)
    }

    const { data: canRequest, error: limitError } = await supabaseClient
      .rpc('can_request_suggestion', { user_uuid: user.id })

    if (limitError) {
      console.error('Error checking suggestion limit:', limitError)
      return corsResponse(JSON.stringify({ success: false, error: 'Failed to check suggestion limit' }), 500)
    }

    if (!canRequest) {
      return corsResponse(JSON.stringify({
        success: false,
        error: 'Monthly suggestion limit reached. Upgrade to premium for more suggestions.',
      }), 429)
    }

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) {
      throw new Error('GOOGLE_AI_API_KEY not configured')
    }

    let base64Image: string
    let mimeType = 'image/jpeg'
    try {
      const imageResponse = await fetch(imageUrl, { signal: AbortSignal.timeout(15000) })
      if (!imageResponse.ok) {
        return corsResponse(JSON.stringify({ success: false, error: 'Failed to fetch image' }), 400)
      }
      const contentLength = imageResponse.headers.get('content-length')
      if (contentLength && parseInt(contentLength) > 10 * 1024 * 1024) {
        return corsResponse(JSON.stringify({ success: false, error: 'Image too large (max 10MB)' }), 400)
      }
      const contentType = imageResponse.headers.get('content-type')
      if (contentType) {
        mimeType = contentType.split(';')[0].trim()
      }
      const arrayBuffer = await imageResponse.arrayBuffer()
      const bytes = new Uint8Array(arrayBuffer)
      base64Image = uint8ArrayToBase64(bytes)
    } catch (error) {
      console.error('Error fetching/converting image:', error)
      return corsResponse(JSON.stringify({ success: false, error: 'Failed to process image' }), 500)
    }

    const languageInstructions = {
      EN: 'Analyze this clothing image and provide 2-3 short, friendly styling suggestions in English.',
      FR: 'Analysez cette image de vêtements et fournissez 2-3 suggestions de style courtes et amicales en français.',
      ES: 'Analiza esta imagen de ropa y proporciona 2-3 sugerencias de estilo cortas y amigables en español.',
    }

    const systemPrompt = `You are a friendly fashion assistant. Based on the outfit in the image:
1. First, provide an objective description with bullet points (item type, colors, patterns, style elements)
2. Then give 2-3 short, positive styling suggestions
Be encouraging and constructive. Keep each suggestion to 1-2 sentences.`

    const geminiResponse = await fetch(GOOGLE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': googleAiApiKey,
      },
      signal: AbortSignal.timeout(30000),
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: languageInstructions[language] },
              { inline_data: { mime_type: mimeType, data: base64Image } },
            ],
          },
        ],
        system_instruction: { parts: [{ text: systemPrompt }] },
        generationConfig: { maxOutputTokens: 500, temperature: 0.1 },
      }),
    })

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Google AI API error:', errorText)
      throw new Error('AI service error. Please try again later.')
    }

    const geminiData = await geminiResponse.json()
    const suggestions = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || ''

    if (!suggestions) {
      throw new Error('No suggestions received from AI')
    }

    const { error: incrementError } = await supabaseClient
      .rpc('increment_suggestions_count', { user_uuid: user.id })

    if (incrementError) {
      console.error('Error incrementing suggestions count:', incrementError)
    }

    return corsResponse(JSON.stringify({ success: true, suggestions: suggestions.trim(), language }))
  } catch (error: unknown) {
    console.error('AI Suggestions Error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Failed to generate suggestions'
    return corsResponse(JSON.stringify({ success: false, error: errorMessage }), 500)
  }
})
