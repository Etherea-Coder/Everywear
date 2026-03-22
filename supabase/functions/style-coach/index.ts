// @ts-nocheck
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

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { userName, localHour, mode, userProfile, insights, wardrobeSummary, question, event } = await req.json()

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    const guardrails = `
IMPORTANT:
- Do not shame the user
- Do not mention body weight or sensitive appearance assumptions
- Do not recommend expensive purchases unless truly necessary
- Do not invent wardrobe items that are not provided
- If data is missing, be transparent and still helpful
- Sound like a supportive, tasteful stylist friend — not a chatbot or fashion influencer`

    const profileBlock = `
USER PROFILE:
${userName ? `- Name: ${userName}` : ''}
- Style profile: ${userProfile?.styleProfile ?? 'Not set yet'}
- Preferred colors: ${userProfile?.preferredColors ?? 'Not specified'}
- Style goals: ${userProfile?.styleGoals ?? 'Not specified'}
- Style intention (in their own words): ${userProfile?.styleIntention ?? 'Not provided'}`

    const insightsBlock = `
WARDROBE DATA:
- Total items: ${insights?.totalItems ?? 0}
- Top category: ${insights?.topCategory ?? 'Unknown'}
- Top occasion: ${insights?.topOccasion ?? 'Casual'}
- Wardrobe summary: ${wardrobeSummary ?? 'Limited data available'}`

    let prompt = ''
    const nameIntro = userName ? ` for ${userName}` : ''

    if (mode === 'passive') {
      let timeString = 'unknown'
      if (typeof localHour === 'number') {
        if (localHour >= 5 && localHour < 12) timeString = 'Morning'
        else if (localHour >= 12 && localHour < 17) timeString = 'Afternoon'
        else if (localHour >= 17 && localHour < 21) timeString = 'Evening'
        else timeString = 'Night'
      }
      const timeContext = typeof localHour === 'number'
        ? `\nCURRENT CONTEXT:\n- Time of Day: ${timeString} (local hour: ${localHour})\n- Instruction: Subtly nod to the time of day if it makes the tip feel more relevant (e.g. morning prep, afternoon slump, evening planning).`
        : ''

      prompt = `You are a personal style coach${nameIntro} inside a wardrobe app.
Your job is to give one short weekly coaching tip. Be warm, encouraging, concise, and practical.
Do not sound like a chatbot or fashion magazine. Base advice only on the user data below.
${profileBlock}
${insightsBlock}${timeContext}
${guardrails}

TASK:
Give exactly one coaching tip for this week.
- Be specific and personal
- Suggest one realistic action
- 2 to 4 sentences maximum
- Start with a short observation, then one practical suggestion
- Output only the tip text, nothing else`

    } else if (mode === 'active') {
      prompt = `You are a personal style coach${nameIntro} inside a wardrobe app.
Help users style themselves using their own wardrobe, style profile, and goals.
Be helpful, personal, concise, and confident.
${profileBlock}
${insightsBlock}
${guardrails}

USER QUESTION:
${question}

TASK:
Answer as their personal style coach. Prioritize items they already own.
Keep the answer under 180 words. The "next_step" must be a concrete action, never a question. Example: "Try pairing your blazer with white trousers this week".
Output a JSON object with keys: "answer" and "next_step"`

    } else if (mode === 'event') {
      const daysLeft = event?.daysLeft ?? '?'
      prompt = `You are a personal style coach${nameIntro} inside a wardrobe app.
Help users prepare outfits for real upcoming events. Be personal, practical, and appropriate.
Use the user existing wardrobe first. Do not invent wardrobe items not provided.
${profileBlock}
${insightsBlock}

EVENT:
- Title: ${event?.title ?? 'Unknown'}
- Type: ${event?.type ?? 'Other'}
- Date: ${event?.date ?? 'Unknown'}
- Days left: ${daysLeft}
- Dress code: ${event?.dressCode ?? 'Not specified'}
${guardrails}

TASK:
Suggest up to 3 outfit directions for this event. Keep full answer under 220 words.
Output a JSON object with keys: "intro", "outfit_1", "outfit_2", "outfit_3", "prep_tip"`
    }

    const geminiResponse = await fetch(`${GOOGLE_API_URL}?key=${googleAiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 400, temperature: 0.7 },
      }),
    })

    if (!geminiResponse.ok) {
      const err = await geminiResponse.text()
      throw new Error(`Gemini error: ${err}`)
    }

    const geminiData = await geminiResponse.json()
    const text = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''

    // Try to parse JSON for structured modes
    let result: any = { success: true, mode, raw: text }
    if (mode === 'passive') {
      result.tip = text.trim()
    } else {
      try {
        const jsonMatch = text.match(/\{[\s\S]*\}/)
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0])
          result = { success: true, mode, ...parsed }
        } else {
          result.tip = text.trim()
        }
      } catch {
        result.tip = text.trim()
      }
    }

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (error) {
    console.error('style-coach error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
