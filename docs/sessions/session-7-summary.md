# Session 7 Summary — Web Polish, UI Redesign & Bug Fixes

**Date:** 2026-03-02
**Branch:** main
**Tests:** 70 passing (no regressions)

---

## What Was Built / Changed

### 1. Web Scan FAB Guard (`history_screen.dart`)
- Added `import 'package:flutter/foundation.dart' show kIsWeb;`
- FAB hidden on web: `kIsWeb ? null : FloatingActionButton(...)`
- Empty state shows note: "Receipt scanning is available on the mobile app."

### 2. Google Places Integration (`stores_provider.dart`, `places_service.dart`)
- Created `app/lib/services/places_service.dart` — HTTP client, 24h Hive cache, `AppResult<T>` wrapping
- Cache key: `'${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}_$radius'` (3 d.p. ≈ 111m precision)
- Status handling: `OK` → AppSuccess, `ZERO_RESULTS` → AppSuccess([]), `OVER_QUERY_LIMIT` → AppFailure(429), `REQUEST_DENIED` → AppFailure
- Replaced stub `storesProvider` with real geolocator + PlacesService call
- Added `geolocator: ^13.0.2` to `pubspec.yaml`
- Added `fromPlacesJson` factory to `StoreResult` (uses `vicinity` not `address`)

### 3. Custom Font (`pubspec.yaml`, `main.dart`)
- Added Alte Haas Grotesk (Regular + Bold) to `app/assets/fonts/`
- Declared under `fonts:` in `pubspec.yaml`
- Set `fontFamily: 'AlteHaasGrotesk'` globally in `ThemeData`

### 4. GitHub Pages Deployment (`.github/workflows/deploy-pages.yml`)
- Created GitHub Actions workflow: build Flutter web → deploy to GitHub Pages
- Fixed: removed pinned `flutter-version: '3.27.4'` (didn't exist), uses `channel: stable`
- Fixed: Pages source must be set to **GitHub Actions** in repo Settings → Pages
- Fixed: 5 GitHub Actions secrets must be set (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `CLAUDE_API_KEY`, `GOOGLE_PLACES_API_KEY`, `CLIMATIQ_API_KEY`)

### 5. Google OAuth Fix (`auth_service.dart`)
- Fixed 404 after Google sign-in by using `redirectTo: kIsWeb ? Uri.base.toString() : 'io.supabase.alltogether://login-callback'`
- Previously `redirectTo: null` sent users to Supabase's dashboard Site URL

### 6. Auth Screen Redesign (`login_screen.dart`, `signup_screen.dart`)
- Unified Sign In + Sign Up into one card with `SegmentedButton<_AuthMode>` toggle
- DoorDash-style modal card on plain background (max-width 480, 28px padding, 24px radius)
- `AnimatedSwitcher` crossfade between sign-in and sign-up forms
- Eco info banner with June Bud background
- `SignupScreen` simplified to delegate: `LoginScreen(startOnSignUp: true)`
- Google button styled with blue `#4285F4` background

### 7. Global Design System (`main.dart`)
- Replaced `colorSchemeSeed: Colors.green` with full custom `ColorScheme`:
  - `primary: #4C0089` (Dark Blue) → all FilledButton backgrounds
  - `primaryContainer: #B0CE6F` (June Bud) → banners, chips, SegmentedButton
  - `scaffoldBackgroundColor: #EFE8D3` (White Chocolate) → every screen background
  - `error: #FF5E33` (Portland Orange) → error states
- Added global button padding (vertical 16, horizontal 24), rounded corners (10px), w600 weight
- Added `CardThemeData` (elevation 0, 16px radius, no margin)
- Added `InputDecorationTheme` (10px radius, consistent padding)
- Added `AppBarTheme` (scrolledUnderElevation 1, centerTitle false)

### 8. Customizations Screen → Modal Bottom Sheet (`customizations_screen.dart`)
- **Removed:** Full-page `Scaffold` layout
- **Added:** `DraggableScrollableSheet` modal (75%–92% height, rounded top corners)
- Drag handle + header with title and X close button (hidden during onboarding)
- 6 accordion sections — each collapses to show label + current value; expands on tap:
  - Diet Type, Health Goal, Eating Style, Allergies, Household Size, Weekly Budget
- `AnimatedSize` + `AnimatedRotation` for smooth expand/collapse
- Save button pinned at bottom with shadow separator
- Used `UncontrolledProviderScope` to pass Riverpod container into the modal
- Added `_OnboardingGate` in `main.dart` as thin wrapper for the onboarding route

### 9. Preferences Save Bug Fix (`preferences_service.dart`)
- **Root cause:** `upsert(onConflict: 'user_id')` requires a UNIQUE constraint on `user_id`; the schema only had `NOT NULL`
- **Fix:** Replaced upsert with check-then-insert/update pattern:
  1. `SELECT id ... maybeSingle()` to check for existing row
  2. If exists → `UPDATE ... .eq('user_id')`; if not → `INSERT`
- Also removed broken `.order('id').limit(1)` chained after upsert
- **Schema fix:** Users must also run `ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_key UNIQUE (user_id);` in Supabase SQL Editor

### 10. Animated Recycling Loading Indicator (`loading_indicator.dart`)
- Replaced `CircularProgressIndicator` with custom `CustomPainter` animation
- 3 curved arcs arranged like ♻ symbol (120° apart, 100° arc span, 20° gaps)
- One arc highlighted green (`#4CAF50`) at a time, cycling every 500ms (1.5s full loop)
- Arrowheads drawn as filled triangles pointing in direction of arc motion
- Applies everywhere `LoadingIndicator` is used (auth, routing, meal plan, etc.)

### 11. README (`README.md`)
- Created comprehensive project README at repo root
- Covers: features, tech stack, architecture, data models, environment variables, run commands, deployment

---

## Files Changed

| File | Change |
|---|---|
| `app/lib/features/history/screens/history_screen.dart` | kIsWeb FAB guard + empty state note |
| `app/lib/services/places_service.dart` | **New** — Google Places HTTP service |
| `app/lib/features/finder/providers/stores_provider.dart` | Real geolocator + PlacesService |
| `app/lib/features/finder/models/store_result_model.dart` | Added `fromPlacesJson` factory |
| `app/assets/fonts/AlteHaasGroteskRegular.ttf` | **New** — custom font asset |
| `app/assets/fonts/AlteHaasGroteskBold.ttf` | **New** — custom font asset |
| `app/pubspec.yaml` | Added geolocator, font declaration |
| `app/lib/main.dart` | Custom ColorScheme, global theme, `_OnboardingGate` |
| `app/lib/features/auth/services/auth_service.dart` | Google OAuth redirectTo fix |
| `app/lib/features/auth/screens/login_screen.dart` | Full redesign as unified card |
| `app/lib/features/auth/screens/signup_screen.dart` | Simplified delegate to LoginScreen |
| `app/lib/features/auth/widgets/google_sign_in_button.dart` | Blue FilledButton style |
| `app/lib/features/customizations/screens/customizations_screen.dart` | Full rewrite as modal |
| `app/lib/features/customizations/services/preferences_service.dart` | Fixed save bug |
| `app/lib/core/widgets/loading_indicator.dart` | Recycling symbol animation |
| `.github/workflows/deploy-pages.yml` | **New** — GitHub Pages CI/CD |
| `README.md` | **New** — project README |

---

## Bugs Fixed

| Bug | Root Cause | Fix |
|---|---|---|
| Web scan FAB crash | `image_picker` + ML Kit are mobile-only | `kIsWeb ? null : FAB` |
| GitHub Actions Flutter version not found | Pinned `3.27.4` didn't exist in cache | Use `channel: stable` only |
| Google OAuth 404 after sign-in | `redirectTo: null` → Supabase used wrong Site URL | `Uri.base.toString()` on web |
| GitHub Pages showing README | Source set to "Deploy from branch" not "GitHub Actions" | Changed source in repo Settings |
| Preferences save "Something went wrong" | `onConflict: 'user_id'` requires UNIQUE constraint; schema had none | Check-then-insert/update pattern |

---

## Known Issues / Next Steps

### Broken / Not Working
- **Google OAuth on web** — Supabase redirect URL whitelist needs `https://vineel1015.github.io/AllTogether/`; Google Cloud Console needs `https://bzdmmdfodffcnwruygma.supabase.co/auth/v1/callback` in Authorized Redirect URIs; OAuth consent screen must be published or test email added
- **GitHub Pages may 404** — Pages source must be set to "GitHub Actions" in repo Settings → Pages
- **Meal plan generation** — `CLAUDE_API_KEY` lives on Supabase Edge Function; Edge Function `generate-meal-plan` must be deployed to Supabase for meal plans to work

### Missing Features / Incomplete
- **No Settings tab** — no way to edit preferences after onboarding except direct navigation
- **No sign-out button** — users have no way to log out from the app UI
- **Nearby stores strip empty** — requires `GOOGLE_PLACES_API_KEY` set + browser location permission granted
- **Analytics shows no data** — depends on receipts existing; Open Food Facts nutrition lookup may return no matches for dummy data item names
- **Receipt scanning web** — disabled on web by design (mobile only)

### Polish / UX
- **Browser tab title** shows "all_together" — should be "AllTogether" (`web/index.html` title field)
- **No empty state for Finder tab** — if meal plan fails, shows error with no friendly fallback
- **No password reset UI** — `AuthService.sendPasswordReset()` exists but no screen for it
- **iOS testing blocked** — Xcode not installed; install from App Store then run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch`

### Pre-existing Analyzer Warnings
- `gemini_service.dart:66` — 2 warnings (`unnecessary_type_check`, `unnecessary_cast`); not introduced this session
