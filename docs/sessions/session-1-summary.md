# Session 1 Summary — Auth + Supabase Setup

**Status:** ✅ Complete and verified (running in Chrome simulator)

---

## What was built

### Foundation (core/)

| File | Purpose |
|---|---|
| `app/pubspec.yaml` | All dependencies declared |
| `app/lib/main.dart` | App entry, Supabase init, Hive init, `AuthWrapper`, `_MainAppRouter` |
| `app/lib/core/models/app_result.dart` | `sealed class AppResult<T>` — `AppSuccess` \| `AppFailure` |
| `app/lib/core/constants/api_constants.dart` | All env-var keys + Hive box name constants |
| `app/lib/core/constants/sustainability_constants.dart` | CO₂ / water / land fallback values by food category |
| `app/lib/core/utils/cache_utils.dart` | `CacheEntry<T>`, `getCached`, `setCache`, `evictExpiredEntries`, `clearAllCaches` |
| `app/lib/core/utils/crypto_utils.dart` | `sha256ofString()` — used for Claude cache key |
| `app/lib/core/utils/string_utils.dart` | `normalizeItemName()`, `toUserMessage()` error mapper |
| `app/lib/core/widgets/loading_indicator.dart` | Centered `CircularProgressIndicator` |
| `app/lib/core/widgets/error_banner.dart` | Error display + optional retry button |

### Auth feature (features/auth/)

| File | Purpose |
|---|---|
| `models/app_user_model.dart` | `AppUser` — `fromSupabaseUser(User)`, `toJson()` |
| `services/auth_service.dart` | `signUp`, `signIn`, `signOut`, `sendPasswordReset` — all return `AppResult<T>` |
| `providers/auth_provider.dart` | `authServiceProvider`, `authStateProvider` (stream), `isAuthenticatedProvider` |
| `screens/login_screen.dart` | Email/password login form with validation and error display |
| `screens/signup_screen.dart` | Name/email/password/confirm signup form |
| `widgets/auth_form_widget.dart` | Reusable `AuthFormField` text field wrapper |

### Customizations feature (features/customizations/)

| File | Purpose |
|---|---|
| `models/user_preferences_model.dart` | Full model with `toFingerprintString()`, `fromJson()`, `toJson()`, `copyWith()` |
| `services/preferences_service.dart` | `getPreferences(userId)`, `savePreferences(prefs)` — Supabase upsert |
| `providers/preferences_provider.dart` | `preferencesServiceProvider`, `userPreferencesProvider` (FutureProvider) |
| `screens/customizations_screen.dart` | Full preferences UI — diet type, health goal, diet style, allergies, household size, budget. Dual mode: `isOnboarding: true` (no back button) or settings edit |
| `widgets/diet_type_selector.dart` | `ChoiceChip` row for omnivore / vegetarian / vegan / pescatarian |
| `widgets/allergy_selector.dart` | `FilterChip` grid for 9 common allergens |

### Shared (shared/)

| File | Purpose |
|---|---|
| `bottom_nav_widget.dart` | `NavigationBar` with Finder / History / Analytics tabs |
| `app_scaffold.dart` | Main app shell, holds tab state, placeholder screens for Sessions 2–4 |

### Tests (test/)

| File | Coverage |
|---|---|
| `test/unit/features/auth/auth_service_test.dart` | `AppUser` model — `toJson`, null email, null name defaults |
| `test/unit/features/customizations/preferences_service_test.dart` | Fingerprint stability, allergy order-independence, fingerprint change detection, JSON round-trip, `toJson` omits null id, `copyWith` |

**All 12 tests pass.**

---

## Auth routing logic (main.dart)

```
App start
  └── AuthWrapper watches authStateProvider (Supabase stream)
        ├── No session → LoginScreen
        │     └── "Sign up" → SignupScreen
        └── Session exists → _MainAppRouter
              ├── user_preferences row missing → CustomizationsScreen(isOnboarding: true)
              │     └── On save → invalidates userPreferencesProvider → routes to AppScaffold
              └── user_preferences row exists → AppScaffold (bottom nav)
                    └── tune icon (Finder tab AppBar) → CustomizationsScreen(isOnboarding: false)
```

---

## Supabase schema applied

All four tables created with RLS enabled:

```sql
user_preferences  -- diet_type, health_goal, diet_style, allergies[], household_size, budget_range
meal_plans        -- week_start_date, plan_data JSONB, pref_fingerprint
receipts          -- store_name, raw_ocr_text, total_amount, image_url
receipt_items     -- name, raw_name, quantity, price, matched_food_id
```

RLS policy pattern on every table: `auth.uid() = user_id` for SELECT / INSERT / UPDATE.

---

## Dependencies added (pubspec.yaml)

```yaml
supabase_flutter: ^2.6.0
flutter_riverpod: ^2.6.1
hive: ^2.2.3
hive_flutter: ^1.1.0
connectivity_plus: ^6.1.1
crypto: ^3.0.6
flutter_secure_storage: ^9.2.4
intl: ^0.19.0
```

Dev:
```yaml
mockito: ^5.4.5
build_runner: ^2.4.14
```

---

## Known issues fixed during session

| Issue | Fix |
|---|---|
| `AppSuccess` / `AppFailure` undefined in screens | Added `app_result.dart` import to `login_screen.dart`, `signup_screen.dart`, `customizations_screen.dart` |
| `value:` deprecated on `DropdownButtonFormField` | Auto-fixed by linter to `initialValue:` in `customizations_screen.dart` |
| `ios/` platform directory missing | Run `flutter create . --project-name all_together --org com.alltogether` from `app/` |

---

## Platform status

| Platform | Status |
|---|---|
| Chrome (web) | ✅ Running — Supabase init confirmed |
| iOS Simulator | Requires Xcode.app from App Store (only CLI tools present) |
| iOS Device | Same as above |

---

## What Session 2 must build

> **Session 2 — Finder + Claude API integration**

Files to create per `docs/architecture/app-structure.md`:

- `app/lib/services/claude_service.dart` — Claude API HTTP calls, exponential backoff, response caching by preference fingerprint
- `app/lib/features/finder/models/meal_plan_model.dart`
- `app/lib/features/finder/models/store_result_model.dart`
- `app/lib/features/finder/services/meal_plan_service.dart` — orchestrates Claude + cache + Supabase
- `app/lib/features/finder/providers/meal_plan_provider.dart`
- `app/lib/features/finder/providers/stores_provider.dart`
- `app/lib/features/finder/screens/finder_screen.dart` — replaces placeholder
- `app/lib/features/finder/widgets/meal_card_widget.dart`
- `app/lib/features/finder/widgets/shopping_list_widget.dart`
- `app/lib/features/finder/widgets/store_card_widget.dart`

Read before starting: `docs/api/claude-api.md`, `docs/guides/caching.md`, `docs/guides/error-handling.md`
