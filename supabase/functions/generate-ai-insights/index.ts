// @ts-nocheck
import { createClient } from 'jsr:@supabase/supabase-js@2'

const GEMINI_MODEL   = 'gemini-2.5-flash-lite'
const GOOGLE_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Extracts a colour keyword from semantic_label (no `color` column exists in DB)
const COLOUR_KEYWORDS = [
  'black','white','gray','grey','brown','beige','cream','navy',
  'blue','red','green','yellow','orange','pink','purple','burgundy',
  'camel','khaki','olive','coral','teal','gold','silver','tan',
]

function extractColour(semanticLabel: string): string | null {
  if (!semanticLabel) return null
  const lower = semanticLabel.toLowerCase()
  return COLOUR_KEYWORDS.find((c) => lower.includes(c)) ?? null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: CORS })

  try {
    // ── Auth (identical pattern to style-coach) ───────────────────────────
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
    }

    const { timeRange = 'month', category = null } = await req.json()

    // ── Date window ───────────────────────────────────────────────────────
    const now   = new Date()
    const start = new Date()
    if (timeRange === 'week')   start.setDate(now.getDate() - 7)
    if (timeRange === 'month')  start.setMonth(now.getMonth() - 1)
    if (timeRange === 'season') start.setMonth(now.getMonth() - 3)

    // ── Fetch wardrobe items ──────────────────────────────────────────────
    // wear_count / last_worn / cost_per_wear already maintained by DB — no need to compute
    let wardrobeQ = supabase
      .from('wardrobe_items')
      .select('id, name, category, semantic_label, wear_count, last_worn, cost_per_wear, purchase_price, purchase_date')

    if (category) wardrobeQ = wardrobeQ.eq('category', category)

    const { data: items = [], error: itemsErr } = await wardrobeQ
    if (itemsErr) throw new Error(`wardrobe_items: ${itemsErr.message}`)

    // ── Fetch outfit logs (used for silhouette evolution only) ────────────
    // outfit_items uses `item_id`, NOT `wardrobe_item_id`
    const { data: logs = [], error: logsErr } = await supabase
      .from('outfit_logs')
      .select('id, worn_date, occasion, rating, outfit_items(item_id)')
      .gte('worn_date', start.toISOString())
    if (logsErr) throw new Error(`outfit_logs: ${logsErr.message}`)

    // ── Compute per-item average ratings from outfit logs ─────────────────
    const itemRatingAccum: Record<string, number[]> = {}
    logs.forEach((log: any) => {
      if (log.rating == null) return
      log.outfit_items?.forEach((oi: any) => {
        if (!oi.item_id) return
        if (!itemRatingAccum[oi.item_id]) itemRatingAccum[oi.item_id] = []
        itemRatingAccum[oi.item_id].push(log.rating)
      })
    })
    const itemRatingAverages: Record<string, { avg: number; count: number; name?: string }> = {}
    for (const [id, ratings] of Object.entries(itemRatingAccum)) {
      const avg = ratings.reduce((a, b) => a + b, 0) / ratings.length
      const item = items.find((i: any) => i.id === id)
      itemRatingAverages[id] = {
        avg: Math.round(avg * 10) / 10,
        count: ratings.length,
        name: item?.name ?? undefined,
      }
    }

    // Top-rated and lowest-rated items for AI prompt
    const ratedItems = Object.entries(itemRatingAverages)
      .filter(([, v]) => v.count >= 2)
      .sort(([, a], [, b]) => b.avg - a.avg)
    const topRated = ratedItems.slice(0, 5)
    const lowestRated = ratedItems.filter(([, v]) => v.avg < 3).slice(0, 3)

    // ── Fetch style quiz (all available columns for richer AI context) ────
    const { data: quiz } = await supabase
      .from('style_quiz_results')
      .select('style_profile, preferred_colors, style_goals, style_intention, answers')
      .order('completed_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    // ══════════════════════════════════════════════════════════════════════
    // PURE DATA — no AI needed
    // ══════════════════════════════════════════════════════════════════════

    // ── Dominant colours (from semantic_label — no color column in DB) ────
    const colourCount: Record<string, number> = {}
    items.forEach((i: any) => {
      const c = extractColour(i.semantic_label ?? '')
      if (c) colourCount[c] = (colourCount[c] ?? 0) + 1
    })
    const sortedColours    = Object.entries(colourCount).sort(([, a], [, b]) => b - a).slice(0, 4)
    const dominantColors   = sortedColours.map(([c]) => c.charAt(0).toUpperCase() + c.slice(1))
    const colorPercentages = sortedColours.map(([, n]) =>
      Math.round((n / Math.max(items.length, 1)) * 100)
    )

    // ── Versatility scores (top 4 by wear_count from DB) ─────────────────
    const versatilityScores = [...items]
      .sort((a: any, b: any) => (b.wear_count ?? 0) - (a.wear_count ?? 0))
      .slice(0, 4)
      .map((item: any) => ({
        item:         item.name,
        score:        Math.min(100, Math.round(((item.wear_count ?? 0) / 20) * 100)),
        combinations: item.wear_count ?? 0,
      }))

    // ── Underutilized items (last_worn from DB — no log joins needed) ─────
    const underutilizedItems = items
      .map((item: any) => {
        const last = item.last_worn ? new Date(item.last_worn) : null
        const days = last
          ? Math.floor((now.getTime() - last.getTime()) / 86_400_000)
          : 999
        return { item: item.name, lastWorn: `${days} days ago`, suggestions: 2, _days: days }
      })
      .filter((i: any) => i._days > 30)
      .sort((a: any, b: any) => b._days - a._days)
      .slice(0, 3)
      .map(({ _days, ...rest }: any) => rest)

    // ── Sustainability (cost_per_wear from DB) ────────────────────────────
    const cpwValues = items
      .map((i: any) => i.cost_per_wear)
      .filter((v: any) => v !== null && v !== undefined)

    const avgCostPerWear = cpwValues.length
      ? Math.round((cpwValues.reduce((a: number, b: number) => a + Number(b), 0) / cpwValues.length) * 100) / 100
      : 0

    const recentPurchases = items.filter((i: any) => {
      const d = i.purchase_date ? new Date(i.purchase_date) : null
      return d && d > start
    }).length

    const sustainabilityMetrics = {
      avgCostPerWear,
      costTrend:                  -12.5,
      purchaseFrequency:          recentPurchases,
      carbonImpact:               recentPurchases * 15,
      carbonGoal:                 200,
      sustainabilityGoalProgress: Math.min(100, Math.max(0, Math.round((1 - recentPurchases / 10) * 100))),
    }

    // ── Silhouette evolution (semantic_label keywords, last 3 months) ─────
    const MONTH_LABELS     = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    const FITTED_KEYWORDS  = ['fitted','slim','skinny','tailored','formal','structured','blazer','pencil']
    const RELAXED_KEYWORDS = ['oversized','loose','relaxed','wide','baggy','flowy','jogger','sweat','hoodie','casual']

    const itemMap = Object.fromEntries(items.map((i: any) => [i.id, i]))

    const silhouetteEvolution = [2, 1, 0].map((offset) => {
      const d = new Date(now.getFullYear(), now.getMonth() - offset, 1)
      let fitted = 0, relaxed = 0

      logs
        .filter((log: any) => {
          const ld = new Date(log.worn_date)
          return ld.getMonth() === d.getMonth() && ld.getFullYear() === d.getFullYear()
        })
        .forEach((log: any) => {
          log.outfit_items?.forEach((oi: any) => {
            const item  = itemMap[oi.item_id]   // ✅ correct column name
            const label = (item?.semantic_label ?? '').toLowerCase()
            if (FITTED_KEYWORDS.some((f) => label.includes(f)))        fitted++
            else if (RELAXED_KEYWORDS.some((r) => label.includes(r)))  relaxed++
          })
        })

      const total = fitted + relaxed || 1
      return {
        month:   MONTH_LABELS[d.getMonth()],
        fitted:  Math.round((fitted  / total) * 100),
        relaxed: Math.round((relaxed / total) * 100),
      }
    })

    // ══════════════════════════════════════════════════════════════════════
    // GEMINI — style profile + recommendations (same API as style-coach)
    // ══════════════════════════════════════════════════════════════════════
    const googleAiApiKey = Deno.env.get('GOOGLE_AI_API_KEY')
    if (!googleAiApiKey) throw new Error('GOOGLE_AI_API_KEY not configured')

    const categoryBreakdown = items.reduce((acc: any, i: any) => {
      acc[i.category ?? 'other'] = (acc[i.category ?? 'other'] ?? 0) + 1
      return acc
    }, {})

    const quizContext = quiz ? {
      styleProfile:    quiz.style_profile,
      preferredColors: quiz.preferred_colors,
      styleGoals:      quiz.style_goals,
      styleIntention:  quiz.style_intention,
      answers:         quiz.answers,
    } : {}

    const prompt = `You are a fashion AI analyst. Analyze this wardrobe and return ONLY a raw JSON object — no markdown, no explanation, no code block.

WARDROBE SUMMARY:
- Total items: ${items.length}
- Category breakdown: ${JSON.stringify(categoryBreakdown)}
- Dominant colors: ${dominantColors.join(', ')}
- Outfit logs in period: ${logs.length}
- Occasions logged: ${[...new Set(logs.map((l: any) => l.occasion).filter(Boolean))].join(', ') || 'none'}

USER STYLE PROFILE (from quiz):
${JSON.stringify(quizContext)}

${topRated.length > 0 ? `TOP-RATED ITEMS (by outfit rating):
${topRated.map(([, v]) => `- ${v.name ?? 'Unknown'}: avg ${v.avg}/5 (${v.count} outfits)`).join('\n')}
These are proven favourites — prefer recommending outfits around them.` : ''}

${lowestRated.length > 0 ? `LOWEST-RATED ITEMS:
${lowestRated.map(([, v]) => `- ${v.name ?? 'Unknown'}: avg ${v.avg}/5 (${v.count} outfits)`).join('\n')}
Consider suggesting alternative styling or replacement for these.` : ''}

Return exactly this structure:
{
  "confidenceScore": <integer 60-95>,
  "styleProfile": "<2-3 word label like Casual Minimalist>",
  "emergingStyles": ["<style1>", "<style2>"],
  "recommendations": [
    {
      "type": "gap",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    },
    {
      "type": "seasonal",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    },
    {
      "type": "style",
      "title": "<short title>",
      "description": "<2 sentences max>",
      "confidence": <60-95>,
      "reasoning": "<one line>"
    }
  ]
}`

    const geminiResponse = await fetch(`${GOOGLE_API_URL}?key=${googleAiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 800, temperature: 0.4 },
      }),
    })

    if (!geminiResponse.ok) {
      const err = await geminiResponse.text()
      throw new Error(`Gemini error: ${err}`)
    }

    const geminiData = await geminiResponse.json()
    const rawText    = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? '{}'

    let aiInsights: any = {}
    try {
      const jsonMatch = rawText.match(/\{[\s\S]*\}/)
      if (jsonMatch) aiInsights = JSON.parse(jsonMatch[0])
    } catch {
      console.error('Failed to parse Gemini JSON:', rawText)
    }

    // ── Final response — matches _aiData shape in ai_intelligence.dart exactly
    const result = {
      confidenceScore:      aiInsights.confidenceScore ?? 70,
      styleProfile:         aiInsights.styleProfile    ?? quiz?.style_profile ?? 'Modern Casual',
      dominantColors,
      colorPercentages,
      silhouetteEvolution,
      emergingStyles:       aiInsights.emergingStyles  ?? [],
      versatilityScores,
      underutilizedItems,
      sustainabilityMetrics,
      recommendations:      aiInsights.recommendations ?? [],
      topRatedItems:         topRated.map(([id, v]) => ({ id, name: v.name, avgRating: v.avg, outfitCount: v.count })),
    }

    return new Response(JSON.stringify(result), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })

  } catch (error: any) {
    console.error('generate-ai-insights error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS, 'Content-Type': 'application/json' } }
    )
  }
})
