import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { preferences } = await req.json();
    if (!preferences) {
      return new Response(JSON.stringify({ error: 'Missing preferences' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      console.error('GEMINI_API_KEY not configured');
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const prompt = buildPrompt(preferences);

    // Gemini API Request — using 1.5 Flash for speed and JSON output support
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          response_mime_type: 'application/json', // Force valid JSON output
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errorBody = await geminiResponse.text();
      console.error(`Gemini API error ${geminiResponse.status}: ${errorBody}`);
      return new Response(JSON.stringify({ error: `Gemini API error: ${geminiResponse.status}` }), {
        status: geminiResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiData = await geminiResponse.json();
    
    // Extract the text content from Gemini's response structure
    const textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (!textResult) {
      console.error('Empty response from Gemini');
      return new Response(JSON.stringify({ error: 'Empty response from Gemini' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Return the JSON string inside a content structure the Flutter app expects
    return new Response(
      JSON.stringify({
        content: [{ type: 'text', text: textResult }],
        model: 'gemini-1.5-flash',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Edge function error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

function buildPrompt(prefs: any): string {
  const allergiesText = !prefs.allergies || prefs.allergies.length === 0 ? 'none' : prefs.allergies.join(', ');

  return `You are an expert meal planning assistant.
Generate a 7-day meal plan based on the following preferences:
- Diet type: ${prefs.dietType}
- Health goal: ${prefs.healthGoal}
- Diet style: ${prefs.dietStyle}
- Allergies: ${allergiesText}
- Household size: ${prefs.householdSize}
- Weekly budget: ${prefs.budgetRange}

Return the response strictly as valid JSON according to this schema:
{
  "week_start": "YYYY-MM-DD",
  "days": [
    {
      "day": "Monday",
      "meals": {
        "breakfast": { "name": "Name", "ingredients": ["A", "B"], "calories": 0, "prep_minutes": 0 },
        "lunch":     { "name": "Name", "ingredients": ["A", "B"], "calories": 0, "prep_minutes": 0 },
        "dinner":    { "name": "Name", "ingredients": ["A", "B"], "calories": 0, "prep_minutes": 0 },
        "snack":     { "name": "Name", "ingredients": ["A", "B"], "calories": 0, "prep_minutes": 0 }
      }
    }
  ],
  "shopping_list": [
    { "item": "Name", "quantity": "Quantity", "estimated_cost": 0.0 }
  ]
}`;
}
