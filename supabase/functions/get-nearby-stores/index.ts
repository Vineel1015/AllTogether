import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const PLACES_BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { lat, lng, radius } = await req.json();

    if (lat == null || lng == null) {
      return new Response(JSON.stringify({ error: 'lat and lng are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const apiKey = Deno.env.get('GOOGLE_PLACES_API_KEY');
    if (!apiKey) {
      console.error('GOOGLE_PLACES_API_KEY not configured');
      return new Response(JSON.stringify({ error: 'Places API not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const url = new URL(PLACES_BASE_URL);
    url.searchParams.set('location', `${lat},${lng}`);
    url.searchParams.set('radius', String(radius ?? 5000));
    url.searchParams.set('type', 'grocery_or_supermarket');
    url.searchParams.set('key', apiKey);

    const placesResponse = await fetch(url.toString());

    if (!placesResponse.ok) {
      console.error(`Places API HTTP error: ${placesResponse.status}`);
      return new Response(
        JSON.stringify({ error: `Places API error: ${placesResponse.status}` }),
        {
          status: placesResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    // Forward the raw Places response body — Flutter parses it as-is.
    const placesData = await placesResponse.json();

    return new Response(JSON.stringify(placesData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Edge function error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
