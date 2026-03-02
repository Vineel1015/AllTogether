# Session 2 Summary — Finder + Claude API Integration

**Status:** ⚠️ Partially complete — UI built and deployed, end-to-end Claude flow needs verification

---

## What Was Built

### New Files Created

| File | Purpose |
|---|---|
| `app/lib/services/claude_service.dart` | Calls Claude via Supabase Edge Function; handles retry + JSON extraction |
| `app/lib/features/finder/models/meal_plan_model.dart` | `MealPlan`, `DayPlan`, `MealEntry`, `ShoppingItem` model hierarchy |
| `app/lib/features/finder/models/store_result_model.dart` | `StoreResult` model stub (wired in Session 6) |
| `app/lib/features/finder/services/meal_plan_service.dart` | Orchestrates: Hive cache → Claude → Supabase upsert → cache |
| `app/lib/features/finder/providers/meal_plan_provider.dart` | `MealPlanNotifier` (AsyncNotifier) with `regenerate()` action |
| `app/lib/features/finder/providers/stores_provider.dart` | Stubbed — returns empty list until Session 6 |
| `app/lib/features/finder/screens/finder_screen.dart` | Full Finder screen with Meals/Shopping tabs + error/loading states |
| `app/lib/features/finder/widgets/meal_card_widget.dart` | Day card with expandable meal rows (ExpansionTile) |
| `app/lib/features/finder/widgets/shopping_list_widget.dart` | Shopping list with per-item cost + estimated total footer |
| `app/lib/features/finder/widgets/store_card_widget.dart` | Store card stub for Session 6 |
| `supabase/functions/generate-meal-plan/index.ts` | Deno Edge Function — calls Claude API server-side, returns response |

### Files Modified

| File | Change |
|---|---|
| `app/pubspec.yaml` | Added `http: ^1.2.2` |
| `app/lib/shared/app_scaffold.dart` | Replaced `_FinderPlaceholder` with `FinderScreen` |
| `app/lib/core/constants/api_constants.dart` | Removed `claudeApiKey`; added `claudeEdgeFunction = 'generate-meal-plan'` |
| `app/lib/core/utils/string_utils.dart` | Fixed dangling doc comment lint |
| `app/test/widget_test.dart` | Replaced stale boilerplate test with no-op placeholder |

---

## Architecture: How Claude Is Called

```
FinderScreen
    │
    ▼
mealPlanNotifierProvider  (Riverpod AsyncNotifier)
    │
    ▼
MealPlanService.getMealPlan(prefs)
    │  1. Check Hive cache (key = SHA-256 fingerprint of prefs)
    │  2. If cache hit → return immediately (no network call)
    │  3. If miss → check connectivity
    │  4. Call ClaudeService.generateMealPlan(prefs)
    │
    ▼
ClaudeService.generateMealPlan(prefs)
    │  Uses: supabase.functions.invoke('generate-meal-plan', body: {preferences})
    │  Auth: Supabase JWT added automatically by supabase_flutter
    │
    ▼
Supabase Edge Function: generate-meal-plan
    │  File: supabase/functions/generate-meal-plan/index.ts
    │  Secret: CLAUDE_API_KEY (stored in Supabase, never in Flutter)
    │  Calls: POST https://api.anthropic.com/v1/messages
    │  Model: claude-sonnet-4-6, max_tokens: 4096
    │
    ▼
Claude API returns JSON meal plan in message content
    │
    ▼
ClaudeService._extractMealPlanJson() → parses Claude envelope
    │  content[0].text → JSON string → Map<String, dynamic>
    │  Fallback: regex extracts first {...} block if Claude adds prose
    │
    ▼
MealPlan.fromClaudeJson(json, userId, fingerprint)
    │
    ├──► Supabase upsert → meal_plans table (conflict: user_id + pref_fingerprint)
    └──► Hive setCache (key: fingerprint, TTL: 7 days)
```

---

## Current Problem to Investigate

### Symptom
The Finder screen shows an error after login. The exact error message varies — earlier errors were:
1. First: `Something went wrong. Please try again.` (error code was being swallowed)
2. After fix: `[cors] Network error — Claude API cannot be called directly from a browser.`

### Root Cause (Resolved by Edge Function)
Direct calls from Flutter Web (Chrome) to `https://api.anthropic.com` are blocked by CORS — the Claude API does not set `Access-Control-Allow-Origin` headers for browser requests.

**Fix applied:** Routed all Claude calls through a Supabase Edge Function (`generate-meal-plan`) which calls Claude server-side. The Edge Function is deployed and the `CLAUDE_API_KEY` secret is set on Supabase.

### Current Status (End of Session 2 + follow-up fixes)
- **Edge Function deployed:** ✅ `supabase functions deploy generate-meal-plan --project-ref bzdmmdfodffcnwruygma`
- **Secret set:** ✅ `CLAUDE_API_KEY` stored as Supabase secret
- **Flutter updated:** ✅ `claude_service.dart` calls `supabase.functions.invoke('generate-meal-plan', ...)`
- **Error display fixed:** ✅ `_ErrorBody` now extracts error code from `[code] message` format and passes only the code to `toUserMessage()`
- **Auth error handling:** ✅ On 401, the error button calls `Supabase.instance.client.auth.signOut()` instead of retrying — this routes the user back to LoginScreen
- **End-to-end test:** ⚠️ Not yet confirmed working — a 401 "Invalid JWT" error is raised on startup, indicating the Chrome session JWT is expired. User must log in fresh.

### What caused the 401 "Invalid JWT"
The Flutter app recovered a stale/expired Supabase session from Chrome's IndexedDB. The `AuthWrapper` briefly showed `AppScaffold` (session object was non-null), which triggered `MealPlanNotifier.build()`, which called `supabase.functions.invoke()` with the expired JWT. The Supabase gateway rejected it before reaching the Edge Function.

**Resolution for the user:** Open the app → Finder tab will show "Authentication error. Please sign in again." → tap the button → logs in fresh → Edge Function receives a valid JWT → meal plan generates.

---

## What the Next Agent Should Do First

### 1. Verify the Edge Function is reachable
Test from curl:
```bash
curl -X POST \
  https://bzdmmdfodffcnwruygma.supabase.co/functions/v1/generate-meal-plan \
  -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"preferences":{"dietType":"omnivore","healthGoal":"maintain","dietStyle":"standard","allergies":[],"householdSize":2,"budgetRange":"$50-$100"}}'
```
Expected: JSON with `content[0].text` containing the meal plan.

### 2. Run the Flutter app and check for errors
```bash
cd app && flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://bzdmmdfodffcnwruygma.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=GOOGLE_PLACES_API_KEY=<key> \
  --dart-define=CLIMATIQ_API_KEY=<key>
```
Note: `CLAUDE_API_KEY` is NO LONGER needed as a dart-define — it lives on Supabase.

### 3. Check Chrome DevTools Console for any remaining errors
Open F12 → Console tab after navigating to the Finder tab.

---

## Possible Remaining Issues to Fix

### Issue A: FunctionException status field type mismatch
`FunctionException.status` in `supabase_flutter` may be `int` or `String` depending on the package version. File: `app/lib/services/claude_service.dart` line 66–70.
```dart
// Current code — may need adjustment if status is String not int:
final isRateLimit = e.status == 429;
isRetryable: isRateLimit || e.status >= 500,
```

### Issue B: Edge Function response shape
`supabase.functions.invoke()` in `supabase_flutter` automatically decodes JSON — `response.data` is already a `Map<String, dynamic>`, not a raw string. However, depending on the package version, `.data` might be `dynamic`. Check that `_extractMealPlanJson` receives the correct shape.

The Edge Function returns the **raw Claude response envelope**:
```json
{
  "content": [{"type": "text", "text": "<raw JSON string>"}],
  "model": "claude-sonnet-4-6",
  ...
}
```
So `_extractMealPlanJson` must parse `envelope['content'][0]['text']` as a JSON string.

### Issue C: Hive cache key collision
If the app was previously running with an old cache entry, the first load may serve stale data. Clear with:
```dart
await Hive.box('meal_plan_cache').clear();
```
Or just uninstall/re-install the Chrome app (IndexedDB stores Hive data in browser).

### Issue D: Supabase RLS on meal_plans
The `meal_plans` table has RLS. The Supabase upsert uses the user's JWT (from `_supabase.auth.currentUser`). Verify the RLS policy allows INSERT + UPDATE where `auth.uid() = user_id`.

---

## Data Flow: MealPlan Model

```
Claude JSON text (string inside content[0].text)
    │
    ▼ jsonDecode
Map<String, dynamic>  {week_start, days: [...], shopping_list: [...]}
    │
    ▼ MealPlan.fromClaudeJson(json, userId, fingerprint)
MealPlan {
  userId, createdAt, weekStartDate,
  days: [DayPlan {day, breakfast, lunch, dinner, snack: MealEntry}],
  shoppingList: [ShoppingItem {item, quantity, estimatedCost}],
  prefFingerprint
}
    │
    ├──► toSupabaseJson() → upsert to meal_plans
    │     {user_id, created_at, week_start_date, plan_data: {days, shopping_list}, pref_fingerprint}
    │
    └──► toJson() → stored in Hive (same shape as toSupabaseJson)
```

---

## Key Constants and Config

| Constant | Value | Location |
|---|---|---|
| Supabase project ref | `bzdmmdfodffcnwruygma` | Supabase dashboard |
| Supabase URL | `https://bzdmmdfodffcnwruygma.supabase.co` | `--dart-define` |
| Edge Function name | `generate-meal-plan` | `ApiConstants.claudeEdgeFunction` |
| Claude model | `claude-sonnet-4-6` | Edge Function hardcoded |
| Hive cache box | `meal_plan_cache` | `ApiConstants.mealPlanCacheBox` |
| Cache TTL | 7 days | `MealPlanService._planTtl` |
| Cache key | SHA-256 of `prefs.toFingerprintString()` | `MealPlanService.getMealPlan` |

---

## Test Status (End of Session 2)

```
flutter test → 28/28 passing
flutter analyze → 0 issues
```

Tests covering Session 2 code:
- `test/unit/services/claude_service_test.dart` — JSON extraction, regex fallback, AppFailure on bad input
- `test/unit/features/finder/meal_plan_service_test.dart` — model round-trips, AppSuccess/AppFailure propagation

---

## Files NOT to Touch in Session 3

Session 3 is **Receipt Scanning** (ML Kit → Open Food Facts → Supabase). Do not modify finder feature files — they are complete pending the above verification.

Session 3 targets:
- `app/lib/features/history/` (all new files)
- `app/lib/services/food_facts_service.dart`
- `app/lib/shared/app_scaffold.dart` → replace `_HistoryPlaceholder` with `HistoryScreen`
