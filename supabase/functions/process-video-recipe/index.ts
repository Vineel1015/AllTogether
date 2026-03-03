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
    const { video_url } = await req.json();
    if (!video_url) {
      return new Response(JSON.stringify({ error: 'Missing video_url' }), {
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

    // Build prompt for Gemini
    // We ask Gemini to identify the recipe if it knows the video, 
    // or to extract details if it can access the URL content.
    const prompt = `
      You are an expert culinary AI. 
      Analyze this video URL: ${video_url}
      Identify the recipe being made in the video. 
      If you can't access the video directly, use your knowledge of common viral recipes or extract information from the URL pattern.
      
      Return a structured JSON response with:
      - title: The name of the meal
      - ingredients: A list of ingredients mentioned or used
      - steps: A list of cooking instructions
      - extracted_text: Any text that would likely be seen on screen (captions, labels)
      
      Example:
      {
        "title": "Viral Feta Pasta",
        "ingredients": ["Cherry tomatoes", "Feta cheese", "Olive oil", "Pasta", "Garlic"],
        "steps": ["Bake tomatoes and feta", "Boil pasta", "Mix together"],
        "extracted_text": ["The original TikTok pasta", "15 minutes at 400F"]
      }
      
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
