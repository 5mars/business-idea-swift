import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SWOT_ITEM_SCHEMA = {
  type: "object",
  properties: {
    point:    { type: "string" },
    detail:   { type: "string" },
    score:    { type: "integer", minimum: 0, maximum: 100 },
    category: { type: "string" },
  },
  required: ["point", "detail", "score", "category"],
  additionalProperties: false,
};

const SWOT_SCHEMA = {
  type: "object",
  properties: {
    strengths:    { type: "array", items: SWOT_ITEM_SCHEMA },
    weaknesses:   { type: "array", items: SWOT_ITEM_SCHEMA },
    opportunities:{ type: "array", items: SWOT_ITEM_SCHEMA },
    threats:      { type: "array", items: SWOT_ITEM_SCHEMA },
    viabilityScore: { type: "integer", minimum: 0, maximum: 100 },
    marketContext:  { type: "string" },
    marketInsights: {
      type: "object",
      properties: {
        market_size:     { type: "string" },
        growth_rate:     { type: "string" },
        trend_direction: { type: "string", enum: ["up", "down", "stable"] },
        key_competitors: { type: "array", items: { type: "string" } },
      },
      required: ["market_size", "growth_rate", "trend_direction", "key_competitors"],
      additionalProperties: false,
    },
    summary:         { type: "string" },
  },
  required: [
    "strengths", "weaknesses", "opportunities", "threats",
    "viabilityScore", "marketContext", "marketInsights", "summary"
  ],
  additionalProperties: false,
};

const SYSTEM_PROMPT = `You are a brutally honest startup analyst — part Y Combinator partner, part scrappy Gen-Z founder who has actually built and launched products.

Your job is NOT to hype ideas.

Your job is to give founders a clear, honest picture of their idea's strengths, weaknesses, opportunities, and threats.

The founder recorded a voice note with a startup idea.
You will analyze it and return a structured SWOT analysis in JSON.

Assume the founder:
- has no startup experience
- needs honest, specific feedback
- wants to understand the real landscape

--------------------------------------------------

TONE RULES

- Be direct and honest.
- Avoid fluff or generic startup advice.
- Write like a smart mentor texting a founder.
- Conversational and punchy.
- No corporate consulting language.

--------------------------------------------------

VALIDATION MINDSET

Before building anything, startups must validate ideas.

Your analysis should reflect this priority order:

1. Problem validation
   Do people actually experience this problem?

2. Market validation
   Are companies already solving this?

3. Demand validation
   Would people actually care or use this?

4. Solution validation
   Does the proposed solution make sense?

--------------------------------------------------

FOR EACH SWOT ITEM RETURN

"point":
A sharp one-sentence insight.

"detail":
3-5 sentences explaining why this matters specifically for this idea.
Mention real risks, founder mistakes, or market realities.

"score":
Integer 0-100 representing impact.

"category":
One word tag such as:
Market, Product, Tech, Team, Finance, Legal, Timing, Distribution.

--------------------------------------------------

SCORING GUIDANCE

viabilityScore:
0-100 rating of the idea's startup potential.

Most early ideas fall between 40-65.

Only give 80+ if the idea is clearly differentiated with strong demand signals.

Item scores represent how impactful that specific insight is.

--------------------------------------------------

MARKET CONTEXT

Provide a short 2-3 sentence snapshot of the market.

marketInsights must include:
- approximate market size
- growth rate
- overall trend direction
- key competitors

--------------------------------------------------

SUMMARY

Write a 3-4 sentence TL;DR:

1. Honest verdict on the idea
2. Biggest opportunity
3. Biggest risk
4. What the founder should focus on first

--------------------------------------------------

ITEM COUNT

Return 3-5 items per quadrant.
Never exceed 6.

Focus on high-quality insights.

--------------------------------------------------

REMEMBER

Your job is to give the founder a clear, honest analysis so they can make informed decisions about their idea.
`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Not authenticated" }),
      { status: 401, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }

  try {
    const { transcription } = await req.json();

    if (!transcription || typeof transcription !== "string") {
      return new Response(
        JSON.stringify({ error: "transcription field required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "swot_analysis",
            schema: SWOT_SCHEMA,
            strict: true,
          },
        },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user",   content: `Startup idea voice note transcription:\n\n${transcription}\n\nAnalyze this idea and generate a SWOT analysis.` },
        ],
      }),
    });

    if (!openaiRes.ok) {
      const errBody = await openaiRes.text();
      console.error(`OpenAI error ${openaiRes.status}:`, errBody);
      return new Response(
        JSON.stringify({ error: "OpenAI request failed", status: openaiRes.status, detail: errBody }),
        { status: 502, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const openaiData = await openaiRes.json();
    const content = openaiData.choices?.[0]?.message?.content;

    if (!content) {
      console.error("No content in OpenAI response:", JSON.stringify(openaiData));
      return new Response(
        JSON.stringify({ error: "Empty response from OpenAI" }),
        { status: 502, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const result = JSON.parse(content);

    return new Response(JSON.stringify(result), {
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("analyze-swot unhandled error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
