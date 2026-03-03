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
    const { url } = await req.json();
    if (!url) {
      return new Response(JSON.stringify({ error: 'Missing url' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Fetch the webpage content
    const webResponse = await fetch(url);
    if (!webResponse.ok) {
      return new Response(JSON.stringify({ error: `Failed to fetch website: ${webResponse.status}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const html = await webResponse.text();
    // Truncate HTML to avoid token limits (first 10k chars is usually enough for recipe data)
    const truncatedHtml = html.substring(0, 15000);

    const prompt = `
      You are an expert culinary AI. 
      Analyze the following HTML content from a cooking website and extract the recipe.
      
      URL: ${url}
      HTML Content:
      ${truncatedHtml}
      
      Return a structured JSON response with:
      - title: The name of the meal
      - ingredients: A list of ingredients with quantities if available
      - steps: A list of cooking instructions
      - source_name: The name of the website (e.g., "AllRecipes", "Food Network")
      
      Return ONLY valid JSON.
    `;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          response_mime_type: 'application/json',
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errorBody = await geminiResponse.text();
      return new Response(JSON.stringify({ error: `Gemini API error: ${geminiResponse.status}` }), {
        status: geminiResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiData = await geminiResponse.json();
    const textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (!textResult) {
      return new Response(JSON.stringify({ error: 'Empty response from Gemini' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(textResult, {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
