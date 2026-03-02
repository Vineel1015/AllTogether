/// Central location for API base URLs and endpoint constants.
///
/// All values come from --dart-define build-time environment variables.
/// Never hardcode URLs or keys here.
class ApiConstants {
  ApiConstants._();

  // ── Supabase ─────────────────────────────────────────────────────────────
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Gemini API via Supabase Edge Function
  static const geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const geminiModel = 'gemini-1.5-flash';
  static const mealPlanEdgeFunction = 'generate-meal-plan';

  // ── Google Places ─────────────────────────────────────────────────────────
  static const googlePlacesApiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  static const googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // ── Open Food Facts ───────────────────────────────────────────────────────
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  // ── Climatiq ──────────────────────────────────────────────────────────────
  static const climatiqApiKey = String.fromEnvironment('CLIMATIQ_API_KEY');
  static const climatiqBaseUrl = 'https://api.climatiq.io/data/v1';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const mealPlanCacheBox = 'meal_plan_cache';
  static const foodItemCacheBox = 'food_item_cache';
  static const placesCacheBox = 'places_cache';
  static const climatiqCacheBox = 'climatiq_cache';
}
