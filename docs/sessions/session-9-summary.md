# Session 9 Summary — Meal & User Grading System

**Date:** 2026-03-03
**Branch:** main
**Tests:** 102 passing (83 prior + 19 new, no regressions)
**Analyzer:** No issues

---

## What Was Built

### 1. `MealScore` Model (`app/lib/features/finder/models/meal_score_model.dart`)
- Data class holding `healthScore`, `sustainabilityScore`, `compositeScore` (all 0–100), and `grade` ('A'–'F').
- `MealScore.fromScores(health, sustainability)` factory computes composite and grade automatically.
- `gradeColor(ColorScheme)` returns green/lightGreen/yellow/orange/red.
- `gradeDescription` returns "Excellent"/"Good"/"Fair"/"Poor"/"Very Poor".

### 2. `MealScoringService` (`app/lib/features/finder/services/meal_scoring_service.dart`)
Pure, stateless `const` service — no network calls.

**Healthiness score (0–100), 70/30 weighted:**
- Calorie tier: ≤200→100 | 201–350→85 | 351–500→70 | 501–650→55 | 651–800→35 | >800→20
- Ingredient diversity: 1–3→30 | 4–6→60 | 7–9→80 | 10+→100

**Sustainability score (0–100):**
- Each ingredient substring-matched against 80-entry keyword map → `SustainabilityConstants.co2ePerKgByCategory`
- Average CO₂e across ingredients → mapped to score bucket (≤0.9→100 … >10.0→10)

**Composite & grade:**
- `compositeScore = (healthScore + sustainabilityScore) / 2`
- Grade: A ≥ 80 | B ≥ 65 | C ≥ 50 | D ≥ 35 | F < 35

**Public API:**
- `scoreMeal(Meal) → MealScore`
- `scoreUserPlan(WeeklyPlan?) → double?` (null when plan is null or empty)

Reuses `SustainabilityConstants` (existing, no changes needed).

### 3. `meal_scoring_provider.dart` (`app/lib/features/finder/providers/meal_scoring_provider.dart`)
- `mealScoringServiceProvider` — singleton `Provider<MealScoringService>`.
- `userPlanScoreProvider` — `Provider<double?>` watching `weeklyPlanNotifierProvider`; returns avg composite score across all meals in plan, or null.

### 4. Grade Badge in Meal Cards (`app/lib/features/finder/widgets/meal_catalog_card_widget.dart`)
- Added `_GradeBadge` widget: 22×22 rounded rect, grade-colour background, white bold letter (10px), positioned top-left of the gradient image area.
- Added import for `MealScoringService`; `_GradeBadge` instantiates `const MealScoringService()` inline (safe — pure/stateless).

### 5. `MealScoreCardWidget` (`app/lib/features/analytics/widgets/meal_score_card_widget.dart`)
- Watches `weeklyPlanNotifierProvider` + `userPlanScoreProvider`.
- **Empty state:** grey icon + "Add meals to your plan to see your score".
- **Score state:** circular arc gauge (`CustomPainter`, 270° sweep, colour-coded), grade letter centred in arc, two sub-score rows (health + sustainability), grade description + tagline.
- `_ArcGaugePainter` draws a grey track arc and a coloured progress arc on top.

### 6. Analytics Screen Updates (`app/lib/features/analytics/screens/analytics_screen.dart`)
- "Your Meal Score" section with `MealScoreCardWidget` is **always rendered** at the top — visible even with no receipts scanned.
- Removed the old full-screen `_EmptyState`; replaced with inline `_ReceiptEmptyState` shown below the score card when `analytics.isEmpty`.
- Receipt-dependent sections (nutrition chart, sustainability card) only render when `!analytics.isEmpty`.
- `_AnalyticsBody` no longer needs to check `analytics.isEmpty` before rendering — the `build` always passes through to `_AnalyticsBody`.

### 7. Unit Tests (`app/test/unit/features/finder/meal_scoring_service_test.dart`)
19 new tests covering:
- `scoreUserPlan(null)` → null
- `scoreUserPlan` on empty plan → null
- `scoreUserPlan` on 2-meal plan → correct weighted average
- Buddha Bowl (vegetable-heavy) → `sustainabilityScore >= 70`
- High-calorie beef meal → `compositeScore < 50`, grade 'D' or 'F'
- Grade thresholds: 80→A, 65→B, 50→C, 35→D, 34→F
- Ingredient category mapping (via sustainability score): "chicken breast"→poultry (score=35), "red lentils"→legumes (score=100), "olive oil"→default (score=55)
- Calorie tier verification: ≤200, 201–350, >800
- Diversity tier verification: 1–3, 10+

---

## Files Changed

| File | Change |
|---|---|
| `app/lib/features/finder/models/meal_score_model.dart` | **New** — MealScore data class |
| `app/lib/features/finder/services/meal_scoring_service.dart` | **New** — pure scoring engine |
| `app/lib/features/finder/providers/meal_scoring_provider.dart` | **New** — Riverpod providers |
| `app/lib/features/analytics/widgets/meal_score_card_widget.dart` | **New** — arc gauge card widget |
| `app/lib/features/finder/widgets/meal_catalog_card_widget.dart` | Added `_GradeBadge` top-left |
| `app/lib/features/analytics/screens/analytics_screen.dart` | Always-show score section, receipt sections conditional |
| `app/test/unit/features/finder/meal_scoring_service_test.dart` | **New** — 19 unit tests |

---

## Key Design Decisions

- `MealScoringService` is `const` and stateless — safe to instantiate inline in widgets without providers.
- Grade badge uses `const MealScoringService()` directly in `_GradeBadge` to avoid needing `ConsumerWidget` for every card.
- `userPlanScoreProvider` uses `ref.watch` on the plan notifier so it recomputes reactively when meals are added/removed.
- `MealScoreCardWidget` computes sub-score breakdowns by re-scoring all meals in the plan (O(n) on plan size — always small).
- No Supabase schema changes required — all scoring is pure Dart.

---

## Known Issues / Next Steps

- **iOS testing blocked** — Xcode not installed; install from App Store then run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch`
- **No Settings tab** — no way to edit preferences after onboarding except direct navigation
- **No sign-out button in UI** — users have no way to log out from app UI
- **Nearby stores strip empty** — requires `GOOGLE_PLACES_API_KEY` set + browser location permission
- **Receipt scanning web disabled** — mobile only by design
- **User-created meals not shown in catalog** — Supabase tables (`public.meals`, `public.weekly_plans`) must be created via SQL (see Session 8 notes)
