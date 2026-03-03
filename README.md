# AllTogether

A cross-platform Flutter application for tracking food consumption habits, generating AI-powered meal plans, scanning grocery receipts, and visualising nutrition and sustainability metrics.

**Live demo:** [vineel1015.github.io/AllTogether](https://vineel1015.github.io/AllTogether/)

---

## Table of Contents

1. [What it does](#what-it-does)
2. [Tech stack](#tech-stack)
3. [Features](#features)
4. [Architecture overview](#architecture-overview)
5. [Folder structure](#folder-structure)
6. [Data models](#data-models)
7. [Service layer & caching](#service-layer--caching)
8. [Error handling](#error-handling)
9. [State management](#state-management)
10. [Getting started](#getting-started)
11. [Environment variables](#environment-variables)
12. [Running the app](#running-the-app)
13. [Running tests](#running-tests)
14. [Deployment](#deployment)

---

## What it does

AllTogether is built around one idea: helping people understand and improve their eating habits through data they already have — grocery receipts.

The workflow is:

```
User sets preferences  →  AI generates a 7-day meal plan  →  User shops
        ↓
User scans the receipt  →  OCR extracts items  →  Open Food Facts matches nutrition
        ↓
Analytics page shows calories, macros, CO₂ footprint, and sustainability score
```

The app is web-first (hosted on GitHub Pages) and also builds for iOS and Android.

---

## Tech stack

| Layer | Technology | Purpose |
|---|---|---|
| UI framework | Flutter (Dart) | Cross-platform — web, iOS, Android |
| UI components | Material 3 | Design system with green colour scheme |
| Font | Alte Haas Grotesk | Custom typeface (Regular + Bold) |
| Backend | Supabase | Auth, PostgreSQL database, Row Level Security |
| AI | Claude API (claude-sonnet-4-6) via Supabase Edge Function | Meal plan generation |
| Receipt OCR | Google ML Kit (on-device) | Text extraction from receipt photos |
| Store finder | Google Places Nearby Search API | Grocery stores near the user's location |
| Nutrition data | Open Food Facts API (no key required) | Calories, macros per food item |
| Sustainability | Climatiq API | CO₂ equivalent emissions per food category |
| Local cache | Hive | On-device TTL cache for all API responses |
| State management | Riverpod | Reactive providers throughout the app |
| Location | geolocator | Browser Geolocation API + iOS/Android GPS |

---

## Features

### Authentication
- Email/password sign up and sign in
- Google OAuth via Supabase
- Unified sign-in/sign-up card UI with tab toggle
- Session persists across app restarts

### Customizations (onboarding)
- Diet type: omnivore, vegetarian, vegan, pescatarian
- Health goal: lose weight, gain weight, maintain, build muscle
- Eating style: standard, keto, high protein, low carb, mediterranean
- Allergies & intolerances
- Household size and weekly grocery budget
- Preferences stored in Supabase with Row Level Security

### Finder (AI meal planner)
- Generates a 7-day meal plan (breakfast, lunch, dinner, snack per day) using Claude
- Each meal includes name, estimated calories, prep time, and ingredient list
- Shopping list aggregated from all meals
- Plans are cached by a SHA-256 fingerprint of the user's preferences — no unnecessary re-generation
- Nearby grocery stores displayed in a horizontal strip (Google Places API, 5 km radius, 24h cache)
- Regenerate button forces a fresh plan on demand

### History (receipt scanner)
- On mobile: take a photo or pick from gallery; Google ML Kit extracts text on-device
- Receipt parser normalises OCR output into line items (handles abbreviations, price formats)
- Receipts and items synced to Supabase
- Sort by date (newest/oldest) or total amount
- Swipe-to-delete with confirmation dialog
- Receipt detail view shows per-item nutrition data (fetched from Open Food Facts)
- Web: scan FAB is hidden; a note explains that scanning requires the mobile app

### Analytics
- 30-day bar chart of daily calorie intake (fl_chart)
- Nutrition summary: total and average daily calories, protein, carbs, fat
- Sustainability score badge: green (< 2.5 kg CO₂e/day), yellow (≤ 5.0), red (> 5.0)
- Sustainability breakdown by food category
- All analytics computed client-side from stored receipt data — no extra API calls

---

## Architecture overview

The codebase follows a **feature-first** structure. Each screen/flow lives in its own folder with its own models, services, providers, screens, and widgets. Shared infrastructure lives in `core/` and `services/`.

```
┌─────────────────────────────────────────────────────────┐
│                        Screens / Widgets                │
│           (features/auth, finder, history, analytics)   │
└────────────────────┬────────────────────────────────────┘
                     │ watch / read
┌────────────────────▼────────────────────────────────────┐
│                   Riverpod Providers                     │
│  (AsyncNotifier, FutureProvider, StateNotifierProvider) │
└────────────────────┬────────────────────────────────────┘
                     │ call
┌────────────────────▼────────────────────────────────────┐
│                   Service Layer                          │
│  Feature services (meal_plan, receipt, analytics, ...)  │
│  API services     (claude, places, food_facts, ...)     │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
  Supabase (auth, DB)      Hive (local cache)
  External APIs            On-device ML Kit
```

### Key design decisions

**`AppResult<T>`** — every service method returns either `AppSuccess<T>` or `AppFailure<T>`. No try/catch in providers or screens. See [Error handling](#error-handling).

**Preference fingerprint** — `UserPreferences.toFingerprintString()` produces a deterministic string; SHA-256 of that string is the cache key for Claude responses. The same preferences always hit the cache; changed preferences always generate fresh.

**Layered caching** — all external API responses are cached in Hive with per-store TTLs. Services check the cache first and only call the network on a miss or expiry.

**Web-first** — the app builds for web (GitHub Pages) and gracefully degrades mobile-only features (receipt scanning FAB hidden on web, location permission handled via browser Geolocation API).

---

## Folder structure

```
AllTogether/
├── README.md
├── AGENT_GUIDE.md          ← Agent/AI developer entry point
├── CLAUDE.md               ← Claude Code rules for this project
├── Planning.md             ← Non-technical product overview
│
├── docs/
│   ├── api/                ← One integration guide per external API
│   │   ├── claude-api.md
│   │   ├── supabase.md
│   │   ├── google-places.md
│   │   ├── open-food-facts.md
│   │   ├── climatiq.md
│   │   └── google-ml-kit.md
│   ├── architecture/
│   │   ├── app-structure.md   ← Full folder layout with rules
│   │   └── data-models.md     ← All Dart + Supabase SQL models
│   └── guides/
│       ├── error-handling.md  ← AppResult<T> pattern
│       └── caching.md         ← Per-API caching strategy
│
└── app/                    ← Flutter application
    ├── pubspec.yaml
    ├── assets/
    │   └── fonts/          ← Alte Haas Grotesk (Regular + Bold)
    ├── lib/
    │   ├── main.dart       ← Entry point; theme; Hive init; Supabase init
    │   ├── core/           ← Shared, feature-agnostic code
    │   │   ├── constants/
    │   │   │   ├── api_constants.dart           ← Base URLs, Hive box names
    │   │   │   └── sustainability_constants.dart
    │   │   ├── models/
    │   │   │   └── app_result.dart              ← AppResult<T> sealed class
    │   │   ├── utils/
    │   │   │   ├── cache_utils.dart             ← getCached / setCache helpers
    │   │   │   ├── crypto_utils.dart            ← SHA-256 fingerprint
    │   │   │   └── string_utils.dart            ← OCR normalisation, abbreviations
    │   │   └── widgets/
    │   │       ├── loading_indicator.dart
    │   │       └── error_banner.dart
    │   │
    │   ├── services/       ← External API wrappers (one file per API)
    │   │   ├── claude_service.dart      ← Calls Supabase Edge Function
    │   │   ├── places_service.dart      ← Google Places Nearby Search
    │   │   ├── food_facts_service.dart  ← Open Food Facts search
    │   │   └── gemini_service.dart      ← (legacy, superseded by claude_service)
    │   │
    │   ├── features/
    │   │   ├── auth/
    │   │   │   ├── models/app_user_model.dart
    │   │   │   ├── services/auth_service.dart   ← signIn, signUp, signOut, Google OAuth
    │   │   │   ├── providers/auth_provider.dart
    │   │   │   ├── screens/
    │   │   │   │   ├── login_screen.dart        ← Unified sign-in/sign-up card
    │   │   │   │   └── signup_screen.dart       ← Delegates to LoginScreen
    │   │   │   └── widgets/
    │   │   │       ├── auth_form_widget.dart
    │   │   │       └── google_sign_in_button.dart
    │   │   │
    │   │   ├── customizations/
    │   │   │   ├── models/user_preferences_model.dart
    │   │   │   ├── services/preferences_service.dart
    │   │   │   ├── providers/preferences_provider.dart
    │   │   │   ├── screens/customizations_screen.dart
    │   │   │   └── widgets/
    │   │   │       ├── diet_type_selector.dart
    │   │   │       └── allergy_selector.dart
    │   │   │
    │   │   ├── finder/
    │   │   │   ├── models/
    │   │   │   │   ├── meal_plan_model.dart
    │   │   │   │   └── store_result_model.dart
    │   │   │   ├── services/meal_plan_service.dart
    │   │   │   ├── providers/
    │   │   │   │   ├── meal_plan_provider.dart
    │   │   │   │   └── stores_provider.dart     ← geolocator + PlacesService
    │   │   │   ├── screens/finder_screen.dart
    │   │   │   └── widgets/
    │   │   │       ├── meal_card_widget.dart
    │   │   │       ├── shopping_list_widget.dart
    │   │   │       └── store_card_widget.dart
    │   │   │
    │   │   ├── history/
    │   │   │   ├── models/
    │   │   │   │   ├── receipt_model.dart
    │   │   │   │   ├── receipt_item_model.dart
    │   │   │   │   └── food_item_model.dart
    │   │   │   ├── services/
    │   │   │   │   ├── ocr_service.dart          ← ML Kit text recognition
    │   │   │   │   ├── receipt_parser_service.dart
    │   │   │   │   └── receipt_service.dart      ← Supabase CRUD
    │   │   │   ├── providers/
    │   │   │   │   ├── receipt_provider.dart
    │   │   │   │   └── scan_provider.dart
    │   │   │   ├── screens/
    │   │   │   │   ├── history_screen.dart
    │   │   │   │   ├── receipt_detail_screen.dart
    │   │   │   │   └── scan_screen.dart
    │   │   │   └── widgets/
    │   │   │       ├── receipt_list_item.dart
    │   │   │       └── nutrition_row_widget.dart
    │   │   │
    │   │   └── analytics/
    │   │       ├── models/
    │   │       │   ├── analytics_model.dart
    │   │       │   ├── daily_nutrition_model.dart
    │   │       │   ├── nutrition_summary_model.dart
    │   │       │   └── sustainability_summary_model.dart
    │   │       ├── services/analytics_service.dart
    │   │       ├── providers/analytics_provider.dart
    │   │       ├── screens/analytics_screen.dart
    │   │       └── widgets/
    │   │           ├── nutrition_chart_widget.dart  ← fl_chart bar chart
    │   │           ├── sustainability_card_widget.dart
    │   │           └── score_badge_widget.dart
    │   │
    │   └── shared/
    │       ├── app_scaffold.dart    ← Bottom nav shell; tab routing
    │       └── bottom_nav_widget.dart
    │
    └── test/
        └── unit/
            ├── services/
            │   └── food_facts_service_test.dart
            └── features/
                ├── auth/auth_service_test.dart
                ├── finder/meal_plan_service_test.dart
                ├── history/receipt_parser_service_test.dart
                └── analytics/analytics_service_test.dart
```

---

## Data models

### Supabase tables

| Table | Purpose | Key columns |
|---|---|---|
| `auth.users` | Managed by Supabase Auth | `id`, `email`, `raw_user_meta_data` |
| `user_preferences` | Diet and health settings | `user_id`, `diet_type`, `health_goal`, `diet_style`, `allergies[]`, `household_size`, `budget_range` |
| `meal_plans` | Claude-generated weekly plans | `user_id`, `plan_data` (JSONB), `pref_fingerprint`, `week_start_date` |
| `receipts` | Scanned receipt headers | `user_id`, `store_name`, `raw_ocr_text`, `total_amount`, `image_url` |
| `receipt_items` | Line items from receipts | `receipt_id`, `name`, `raw_name`, `quantity`, `price`, `matched_food_id` |

All tables use Row Level Security with `auth.uid() = user_id` policies — users can only read and write their own data.

### Local cache (Hive)

| Box | Cache key | TTL | What's stored |
|---|---|---|---|
| `meal_plan_cache` | SHA-256 of preference fingerprint | 7 days | Full meal plan JSON |
| `food_item_cache` | Normalised item name | 30 days | `FoodItem` with nutrition data |
| `places_cache` | `lat(3dp),lng(3dp)_radius` | 24 hours | List of `StoreResult` |
| `climatiq_cache` | `activityId_weightUnit` | 90 days | CO₂e value |

### Dart models

All models use `fromJson` / `toJson` for Hive serialisation. Models returned by external APIs have an additional named constructor — e.g. `FoodItem.fromOpenFoodFactsJson()`, `StoreResult.fromPlacesJson()` — to keep raw API field names out of the domain model.

---

## Service layer & caching

Every external API lives in `app/lib/services/` as its own class with an injectable `http.Client` for testing.

**Request flow for any service:**

```
1. Check Hive cache → return immediately on hit
2. Check connectivity → return AppFailure('offline') if no network
3. Make HTTP request
4. On success → write to cache, return AppSuccess(data)
5. On 429 / 5xx → exponential backoff (1s → 2s → 4s), retry up to 3×
6. On other errors → return AppFailure with code and isRetryable flag
```

### Claude (meal plan generation)

Claude's API key lives on the Supabase server, not in the Flutter app. The Flutter client calls a **Supabase Edge Function** (`generate-meal-plan`) which calls the Claude API server-side and returns the structured JSON. This keeps the key out of the client bundle entirely.

The cache key is a SHA-256 hash of `UserPreferences.toFingerprintString()` — a pipe-delimited string of all preference fields. If the user has not changed their preferences, the cached plan is served for up to 7 days. If they tap "Regenerate", the cache is bypassed and a fresh plan is stored.

### Google Places (store finder)

`PlacesService.getNearbyStores(lat, lng)` calls the Nearby Search endpoint with `type=grocery_or_supermarket` and `radius=5000`. The cache key rounds coordinates to 3 decimal places (~111 m precision) so minor GPS drift doesn't cause unnecessary re-fetches.

### Open Food Facts (nutrition lookup)

`FoodFactsService.lookupItem(normalizedName)` searches by normalised item name. The OCR output goes through `string_utils.dart` which expands common grocery abbreviations (e.g. `ORG` → `organic`, `WHL` → `whole`) before searching. No API key required.

---

## Error handling

All service methods return `AppResult<T>`, a sealed class with two variants:

```dart
sealed class AppResult<T> {}

final class AppSuccess<T> extends AppResult<T> {
  final T data;
}

final class AppFailure<T> extends AppResult<T> {
  final String message;
  final String? code;       // e.g. '429', 'offline', 'request_denied'
  final bool isRetryable;
}
```

Providers convert failures to exceptions (`throw Exception(message)`) so Riverpod's `.when(error:)` handler can display them. Screens use `ErrorBanner` with an optional retry callback. User-facing messages are mapped from error codes in `string_utils.dart::toUserMessage()` — raw API errors are never shown directly.

---

## State management

The app uses **Riverpod** throughout. Key providers:

| Provider | Type | What it holds |
|---|---|---|
| `authStateProvider` | `StreamProvider<AuthState>` | Live Supabase auth stream; drives the `AuthWrapper` router |
| `userPreferencesProvider` | `FutureProvider<UserPreferences?>` | User's saved preferences; invalidated on save |
| `mealPlanNotifierProvider` | `AsyncNotifier<MealPlan?>` | Current meal plan; exposes `regenerate()` |
| `receiptsProvider` | `AsyncNotifier<List<Receipt>>` | All user receipts; exposes `deleteReceipt()`, `refresh()` |
| `storesProvider` | `FutureProvider<List<StoreResult>>` | Nearby stores; fetches location then calls Places API |
| `analyticsProvider` | `FutureProvider<Analytics>` | Computed from `receiptsProvider.future`; auto-refreshes |
| `foodItemByNameProvider` | `FutureProvider.family<FoodItem?, String>` | Per-item nutrition lookup in receipt detail |

---

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.24 (`flutter --version`)
- Dart SDK ≥ 3.2 (bundled with Flutter)
- A Supabase project with the schema applied (see `docs/api/supabase.md`)
- Google Cloud project with **Places API** enabled
- Claude API key

### Supabase setup

Run the following SQL in your Supabase SQL editor to create all tables and RLS policies:

```sql
-- User preferences
CREATE TABLE user_preferences (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diet_type     TEXT NOT NULL,
  health_goal   TEXT NOT NULL,
  diet_style    TEXT NOT NULL,
  allergies     TEXT[] DEFAULT '{}',
  household_size INT NOT NULL DEFAULT 1,
  budget_range  TEXT NOT NULL,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own preferences" ON user_preferences
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Meal plans
CREATE TABLE meal_plans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  week_start_date  DATE NOT NULL,
  plan_data        JSONB NOT NULL,
  pref_fingerprint TEXT NOT NULL
);
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own meal plans" ON meal_plans
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Receipts
CREATE TABLE receipts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scanned_at   TIMESTAMPTZ DEFAULT NOW(),
  store_name   TEXT,
  raw_ocr_text TEXT NOT NULL,
  total_amount NUMERIC(10, 2),
  image_url    TEXT
);
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own receipts" ON receipts
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Receipt items (cascade-deleted with their receipt)
CREATE TABLE receipt_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id      UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  raw_name        TEXT NOT NULL,
  quantity        NUMERIC DEFAULT 1,
  price           NUMERIC(10, 2),
  matched_food_id TEXT
);
```

Then enable Google as an OAuth provider in the Supabase dashboard under **Authentication → Providers → Google** and paste your Google OAuth client ID and secret.

---

## Environment variables

All secrets are injected at build time via `--dart-define`. They are never stored in source files or `.env` files.

| Variable | Where to get it |
|---|---|
| `SUPABASE_URL` | Supabase project → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase project → Settings → API → anon/public key |
| `CLAUDE_API_KEY` | console.anthropic.com → API Keys |
| `GOOGLE_PLACES_API_KEY` | Google Cloud Console → Credentials → API key (Places API enabled) |
| `CLIMATIQ_API_KEY` | climatiq.io → Dashboard → API Keys |

Access in Dart:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
```

For Google OAuth to work on web you must also add these URLs to **Supabase → Authentication → URL Configuration → Redirect URLs**:
```
http://localhost:*
https://vineel1015.github.io/AllTogether/
```

---

## Running the app

### Web (Chrome)

```bash
cd app
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-key> \
  --dart-define=CLAUDE_API_KEY=<your-key> \
  --dart-define=GOOGLE_PLACES_API_KEY=<your-key> \
  --dart-define=CLIMATIQ_API_KEY=<your-key>
```

Or use the convenience script:

```bash
bash app/scripts/run_dev.sh -d chrome
```

### iOS Simulator

Requires Xcode installed. After installing from the App Store:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
open -a Simulator
```

Then:

```bash
cd app
flutter run -d <simulator-device-id> \
  --dart-define=SUPABASE_URL=<your-url> ...
```

### Android Emulator

```bash
cd app
flutter run -d <emulator-id> \
  --dart-define=SUPABASE_URL=<your-url> ...
```

---

## Running tests

```bash
cd app
flutter test
```

The test suite has 70 unit tests covering:

| Test file | What it covers |
|---|---|
| `auth_service_test.dart` | `AppUser` JSON serialisation |
| `preferences_service_test.dart` | `UserPreferences` fingerprint stability, round-trip JSON |
| `meal_plan_service_test.dart` | `MealPlan` parsing, `GeminiService` result propagation |
| `receipt_parser_service_test.dart` | OCR line parsing, amount extraction, skip rules |
| `food_facts_service_test.dart` | HTTP responses, cache hit/miss, retry logic |
| `analytics_service_test.dart` | Calorie aggregation, CO₂ scoring, category mapping |

All service classes accept an injectable `http.Client` so tests run without network access.

---

## Deployment

The app is automatically deployed to GitHub Pages on every push to `main` via `.github/workflows/deploy-pages.yml`.

The workflow:
1. Checks out the repo
2. Installs the latest stable Flutter
3. Runs `flutter pub get`
4. Runs `flutter build web --release --base-href /AllTogether/` with all secrets injected from GitHub repository secrets
5. Uploads `app/build/web/` as a GitHub Pages artifact and deploys it

### Setting up deployment for the first time

1. Go to **GitHub → Repository → Settings → Pages** and set the source to **"GitHub Actions"**
2. Go to **Settings → Secrets and variables → Actions** and add all five secrets listed in [Environment variables](#environment-variables)
3. Push to `main` — the workflow triggers automatically

The live URL will be: `https://<your-github-username>.github.io/AllTogether/`
