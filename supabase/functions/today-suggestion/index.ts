// @ts-nocheck
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
    const {
      userProfile,
      weather,
      occasion,
      mood,
      wardrobeItems,
      recentItems,
      nextEvent,
    } = await req.json()

    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    // Build wardrobe list for prompt
    const wardrobeList = (wardrobeItems ?? []).map((item: any) =>
      `- id:${item.id} | ${item.name} | ${item.category} | ${item.color ?? 'unknown color'} | worn ${item.times_worn ?? 0}x | last worn: ${item.last_worn ?? 'never'} | imageUrl: ${item.image_url ?? ''}`
    ).join('\n')

    const recentList = (recentItems ?? []).join(', ') || 'none'
    const weatherStr = weather ? `${weather.temperature}${weather.unit}, ${weather.condition}` : 'unknown'
    const eventStr = nextEvent ? `${nextEvent.title} in ${nextEvent.daysLeft} days (${nextEvent.event_type}, dress code: ${nextEvent.dress_code ?? 'none'})` : 'none'

    const prompt = `You are a personal stylist inside a wardrobe app.
Your task is to create one realistic outfit suggestion for today using ONLY items from the user's actual wardrobe list below.

USER PROFILE:
- Style profile: ${userProfile?.styleProfile ?? 'not set'}
- Preferred colors: ${userProfile?.preferredColors ?? 'not specified'}
- Style goals: ${userProfile?.styleGoals ?? 'not specified'}
- Style intention: ${userProfile?.styleIntention ?? 'not specified'}

TODAY CONTEXT:
- Weather: ${weatherStr}
- Occasion: ${occasion ?? 'none selected'}
- Mood: ${mood ?? 'none selected'}
- Upcoming event: ${eventStr}

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

Return ONLY valid JSON in this exact format, no markdown, no explanation:
{
  "title": "Today's Style Idea",
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

    const geminiResponse = await fetch(`${GOOGLE_API_URL}?key=${googleAiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 600, temperature: 0.7 },
      }),
    })

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
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
    )
  }
})
