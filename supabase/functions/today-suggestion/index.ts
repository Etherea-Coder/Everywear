import { createClient } from '@supabase/supabase-js'
import { createGeminiRequest } from '../_shared/gemini_request.ts'

const GEMINI_MODEL = 'gemini-2.5-flash-lite'

type WardrobePromptItem = {
  id?: string
  name?: string
  category?: string
  color?: string | null
  times_worn?: number | null
  last_worn?: string | null
  image_url?: string | null
  avg_rating?: number | null
  rated_count?: number | null
}

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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }
    const { data: allowed, error: quotaError } = await supabase
      .rpc('consume_ai_quota', { quota_kind: 'suggestion' })
    if (quotaError) throw new Error('Unable to verify AI quota')
    if (!allowed) {
      return new Response(JSON.stringify({ error: 'AI quota reached' }), { status: 429 })
    }

    const {
      userName,
      localHour,
      userProfile,
      weather,
      occasion,
      mood,
      wardrobeItems,
      recentItems,
      nextEvent,
      occasionPatterns,
    } = await req.json()

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    // Build wardrobe list for prompt
    const wardrobeList = (Array.isArray(wardrobeItems) ? wardrobeItems : []).map((item: WardrobePromptItem) => {
      let line = `- id:${item.id} | ${item.name} | ${item.category} | ${item.color ?? 'unknown color'} | worn ${item.times_worn ?? 0}x | last worn: ${item.last_worn ?? 'never'} | imageUrl: ${item.image_url ?? ''}`
      if (item.avg_rating) line += ` | avg outfit rating: ${item.avg_rating}/5 (${item.rated_count ?? 0} outfits)`
      return line
    }).join('\n')

    const recentList = (recentItems ?? []).join(', ') || 'none'
    const weatherStr = weather ? `${weather.temperature}${weather.unit}, ${weather.condition}` : 'unknown'
    const eventStr = nextEvent ? `${nextEvent.title} in ${nextEvent.daysLeft} days (${nextEvent.event_type}, dress code: ${nextEvent.dress_code ?? 'none'})` : 'none'

    const nameLine = userName ? ` for ${userName}` : ''
    const titleName = userName ? `${userName}'s Style Idea for Today` : "Today's Style Idea"

    let timeString = 'unknown'
    if (typeof localHour === 'number') {
      if (localHour >= 5 && localHour < 12) timeString = 'Morning'
      else if (localHour >= 12 && localHour < 17) timeString = 'Afternoon'
      else if (localHour >= 17 && localHour < 21) timeString = 'Evening'
      else timeString = 'Night'
    }

    const prompt = `You are a personal stylist${nameLine} inside a wardrobe app.
Your task is to create one realistic outfit suggestion for today using ONLY items from the user's actual wardrobe list below.

USER PROFILE:
${userName ? `- Name: ${userName}` : ''}
- Style profile: ${userProfile?.styleProfile ?? 'not set'}
- Preferred colors: ${userProfile?.preferredColors ?? 'not specified'}
- Style goals: ${userProfile?.styleGoals ?? 'not specified'}
- Style intention: ${userProfile?.styleIntention ?? 'not specified'}

TODAY CONTEXT:
- Time of Day: ${timeString} (local hour: ${localHour ?? '?'})
- Weather: ${weatherStr}
- Occasion: ${occasion ?? 'none selected'}
- Mood: ${mood ?? 'none selected'}
- Upcoming event: ${eventStr}
- Instruction: Tone of the description can hint at the time of day (e.g. morning prep, afternoon slump, evening out).

${(() => {
  if (!occasionPatterns || typeof occasionPatterns !== 'object') return ''
  const weekday = occasionPatterns.weekday ?? {}
  const weekend = occasionPatterns.weekend ?? {}
  const fmtTop = (counts: Record<string, number>) => {
    const entries = Object.entries(counts).sort(([,a], [,b]) => b - a)
    if (entries.length === 0) return 'no data yet'
    return entries.slice(0, 3).map(([k, v]) => `${k} (${v}x)`).join(', ')
  }
  if (Object.keys(weekday).length === 0 && Object.keys(weekend).length === 0) return ''
  return `HABIT PATTERNS (last 60 days):\n- Weekdays: ${fmtTop(weekday)}\n- Weekends: ${fmtTop(weekend)}\n- Instruction: If no occasion is selected, lean toward the user's most common occasion for today's day type.`
})()}

RECENTLY WORN ITEMS (avoid if possible):
${recentList}

WARDROBE (use ONLY these items):
${wardrobeList || 'No items available - return a generic suggestion with empty ids'}

OUTFIT RULES:
- Build around one anchor item (outerwear, jacket, or statement piece)
- Choose 2 to 4 supporting items
- Prefer variety - avoid recently worn items unless no strong alternative exists
- Match the occasion and mood if selected
- Match the weather conditions
- Keep the outfit coherent in color, formality and practicality
- If wardrobe is limited, return the best possible combination

VARIETY RULE:
Avoid items worn in the last 3 days unless they are the only strong match.
Prefer underused items when they fit the outfit well.

RATING PREFERENCE:
Items with a high average outfit rating (4+) are proven favourites — prefer them when they fit the occasion and weather.
Items with low average ratings (below 3) should be deprioritised unless no better option exists.

Return ONLY valid JSON in this exact format, no markdown, no explanation:
{
  "title": "${titleName}",
  "description": "one sentence describing the look",
  "styling_note": "one practical tip for wearing this outfit",
  "anchor": {
    "id": "item id or empty string",
    "name": "item name",
    "category": "category",
    "imageUrl": "image url or empty string",
    "slot": "anchor"
  },
  "items": [
    {
      "id": "item id or empty string",
      "name": "item name",
      "category": "category",
      "imageUrl": "image url or empty string",
      "slot": "top or bottom or shoes or accessory"
    }
  ]
}`

    const geminiRequest = createGeminiRequest(GEMINI_MODEL, googleAiApiKey, {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 600, temperature: 0.7 },
    })
    const geminiResponse = await fetch(geminiRequest)

    if (!geminiResponse.ok) {
      const err = await geminiResponse.text()
      throw new Error(`Gemini error: ${err}`)
    }

    const geminiData = await geminiResponse.json()
    const text = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? ''

    const jsonMatch = text.match(/\{[\s\S]*\}/)
    if (!jsonMatch) throw new Error('No JSON in Gemini response')

    const result = JSON.parse(jsonMatch[0])

    return new Response(JSON.stringify({ success: true, ...result }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (error) {
    console.error('today-suggestion error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Suggestion generation failed.' }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
