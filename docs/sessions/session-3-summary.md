# Session 3 Summary — Google Sign-In (OAuth)

**Status:** ✅ Complete — Google OAuth implemented, tested in Chrome, app running end-to-end

---

## What Was Built

### New Files Created

| File | Purpose |
|---|---|
| `app/lib/features/auth/widgets/google_sign_in_button.dart` | Reusable `OutlinedButton` with blue "G" logo and `CircularProgressIndicator` while loading |

### Files Modified

| File | Change |
|---|---|
| `app/lib/features/auth/services/auth_service.dart` | Added `signInWithGoogle()` using `signInWithOAuth(OAuthProvider.google)` with mobile deep-link redirect URI |
| `app/lib/features/auth/screens/login_screen.dart` | Added `_isGoogleLoading` state, `_signInWithGoogle()` method, `_OrDivider` private widget, `GoogleSignInButton` below Sign In button |
| `app/android/app/src/main/AndroidManifest.xml` | Added `io.supabase.alltogether` deep-link `<intent-filter>` inside `<activity>` |
| `app/ios/Runner/Info.plist` | Added `CFBundleURLTypes` with `io.supabase.alltogether` URL scheme |

---

## Architecture: Google OAuth Flow

```
User taps "Continue with Google"
    │
    ▼
authService.signInWithGoogle()
    │  calls: _supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: ...)
    │  web:    redirectTo = null (Supabase uses Site URL)
    │  mobile: redirectTo = 'io.supabase.alltogether://login-callback'
    │
    ▼
Supabase OAuth → Google consent screen (browser)
    │
    ▼
Google callback → https://<project>.supabase.co/auth/v1/callback
    │
    ▼
Supabase sets session → deep-link fires (mobile) or Site URL redirect (web)
    │
    ▼
authStateChanges stream fires (SIGNED_IN event)
    │
    ▼
AuthWrapper in main.dart → _MainAppRouter → AppScaffold
    (no explicit navigation in signInWithGoogle — stream handles routing)
```

---

## Deep-Link URI Scheme

```
io.supabase.alltogether://login-callback
```

- **Android:** `<intent-filter>` with `android:scheme="io.supabase.alltogether"` in `AndroidManifest.xml`
- **iOS:** `CFBundleURLTypes` with `CFBundleURLSchemes` array in `Info.plist`
- **Web:** No redirect needed — Supabase uses the configured Site URL

---

## Manual Prerequisites (User Must Complete in Supabase/Google Console)

### Google Cloud Console
1. APIs & Services → Credentials → Create OAuth 2.0 Client ID (Web application)
2. Authorized redirect URI: `https://<supabase-project-id>.supabase.co/auth/v1/callback`
3. Copy Client ID and Client Secret

### Supabase Dashboard
1. Authentication → Providers → Google → Enable → paste Client ID + Client Secret → Save
2. Authentication → URL Configuration:
   - Site URL: `http://localhost` (dev) or production URL
   - Additional Redirect URLs: `io.supabase.alltogether://login-callback`

---

## Login Screen Changes

- `_isGoogleLoading` state field (separate from existing `_isLoading`)
- Both buttons disable while either loading flag is true (prevents double-submit)
- Layout order:
  1. Email field
  2. Password field
  3. Error message (if any)
  4. Sign In button (FilledButton)
  5. `_OrDivider` (Row with two Dividers and "or" text)
  6. `GoogleSignInButton` (OutlinedButton)
  7. "Don't have an account? Sign up" TextButton

---

## Run Script

Existing `app/scripts/run_dev.sh` reads `.env` and passes all `--dart-define` flags automatically:

```bash
bash app/scripts/run_dev.sh -d chrome        # web
bash app/scripts/run_dev.sh -d "iPhone 15"   # iOS simulator
bash app/scripts/run_dev.sh                  # auto-selects device
```

---

## Test Status (End of Session 3)

```
flutter test    → 70/70 passing (no new tests — no service logic changes)
flutter analyze → 2 pre-existing warnings in gemini_service.dart:66 (not introduced here)
```

---

## What the Next Session Should Address

Session 4 (History page) is complete — see `docs/sessions/session-4-summary.md`.
