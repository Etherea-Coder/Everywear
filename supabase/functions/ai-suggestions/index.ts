// @ts-nocheck
// @ts-ignore
import { createClient } from 'jsr:@supabase/supabase-js@2'

const OPENROUTER_API_URL = 'https://openrouter.ai/api/v1/chat/completions'
const GEMINI_MODEL = 'google/gemini-2.5-flash-lite'

interface RequestBody {
  imageUrl: string
  language: 'EN' | 'FR' | 'ES'
}

Deno.serve(async (req) => {
  // CORS headers
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
    const { imageUrl, language }: RequestBody = await req.json()

    // Validate inputs
    if (!imageUrl || !language) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: imageUrl and language' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get user from authorization header
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get user from auth
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check suggestion limit before processing
    const { data: canRequest, error: limitError } = await supabaseClient
      .rpc('can_request_suggestion', { user_uuid: user.id })

    if (limitError) {
      console.error('Error checking suggestion limit:', limitError)
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to check suggestion limit' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!canRequest) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Monthly suggestion limit reached. Upgrade to premium for more suggestions.'
        }),
        { status: 429, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get OpenRouter API key from environment
    const openRouterApiKey = Deno.env.get('OPENROUTER_API_KEY')
    if (!openRouterApiKey) {
      throw new Error('OPENROUTER_API_KEY not configured')
    }

    // Convert image to base64
    let base64Image: string
    try {
      const imageResponse = await fetch(imageUrl)
      const imageBlob = await imageResponse.blob()
      const arrayBuffer = await imageBlob.arrayBuffer()
      const bytes = new Uint8Array(arrayBuffer)
      base64Image = btoa(String.fromCharCode(...bytes))
    } catch (error) {
      console.error('Error fetching/converting image:', error)
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to process image' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
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

    // Call OpenRouter with Gemini 2.5 Flash Lite
    const geminiResponse = await fetch(OPENROUTER_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openRouterApiKey}`,
        'HTTP-Referer': Deno.env.get('SUPABASE_URL') || 'https://everywear.app',
        'X-Title': 'EveryWear AI Suggestions',
      },
      body: JSON.stringify({
        model: GEMINI_MODEL,
        messages: [
          {
            role: 'system',
            content: systemPrompt
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: languageInstructions[language]
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`
                }
              }
            ]
          }
        ],
        max_tokens: 500,
        temperature: 0.1,
      }),
    })

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('OpenRouter API error:', errorText)
      throw new Error(`OpenRouter API error: ${errorText}`)
    }

    const geminiData = await geminiResponse.json()
    const suggestions = geminiData.choices?.[0]?.message?.content || ''

    if (!suggestions) {
      throw new Error('No suggestions received from Gemini')
    }

    // Increment suggestion count for user
    const { error: incrementError } = await supabaseClient
      .rpc('increment_suggestions_count', { user_uuid: user.id })

    if (incrementError) {
      console.error('Error incrementing suggestions count:', incrementError)
    }

    // Return successful response
    return new Response(
      JSON.stringify({
        success: true,
        suggestions: suggestions.trim(),
        language,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error: unknown) {
    console.error('AI Suggestions Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Failed to generate suggestions'

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})