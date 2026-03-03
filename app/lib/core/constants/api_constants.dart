/// Central location for API base URLs and endpoint constants.
///
/// All values come from --dart-define build-time environment variables.
/// Never hardcode URLs or keys here.
class ApiConstants {
  ApiConstants._();

  // ── Supabase ─────────────────────────────────────────────────────────────
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Google Places — proxied via Supabase Edge Function (key stays server-side)
  static const nearbyStoresEdgeFunction = 'get-nearby-stores';

  // ── Open Food Facts ───────────────────────────────────────────────────────
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  // ── Climatiq ──────────────────────────────────────────────────────────────
  static const climatiqApiKey = String.fromEnvironment('CLIMATIQ_API_KEY');
  static const climatiqBaseUrl = 'https://api.climatiq.io/data/v1';

  // ── Hive box names ────────────────────────────────────────────────────────
  static const mealCatalogCacheBox = 'meal_catalog_cache';
  static const weeklyPlanCacheBox = 'weekly_plan_cache';
  static const foodItemCacheBox = 'food_item_cache';
  static const placesCacheBox = 'places_cache';
  static const climatiqCacheBox = 'climatiq_cache';
}
