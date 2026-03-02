# Error Handling Guide

## Core Pattern: AppResult<T>

Every service method in AllTogether returns an `AppResult<T>`. This eliminates try/catch boilerplate in providers and screens.

**`app/lib/core/models/app_result.dart`**

```dart
sealed class AppResult<T> {
  const AppResult();
}

final class AppSuccess<T> extends AppResult<T> {
  final T data;
  const AppSuccess(this.data);
}

final class AppFailure<T> extends AppResult<T> {
  final String message;
  final String? code;       // API error code or HTTP status
  final bool isRetryable;   // whether the UI should offer a retry button

  const AppFailure(
    this.message, {
    this.code,
    this.isRetryable = false,
  });
}
```

### Usage in a Service

```dart
Future<AppResult<MealPlan>> generateMealPlan(UserPreferences prefs) async {
  try {
    final response = await _httpClient.post(...);
    if (response.statusCode == 200) {
      final plan = MealPlan.fromJson(jsonDecode(response.body));
      return AppSuccess(plan);
    }
    return _handleHttpError(response.statusCode, response.body);
  } on SocketException {
    return const AppFailure('No internet connection', code: 'offline', isRetryable: true);
  } on TimeoutException {
    return const AppFailure('Request timed out', code: 'timeout', isRetryable: true);
  } catch (e) {
    return AppFailure('Unexpected error: $e');
  }
}
```

### Usage in a Provider (Riverpod)

```dart
final mealPlanProvider = FutureProvider<MealPlan>((ref) async {
  final prefs = ref.watch(preferencesProvider).value!;
  final result = await ref.read(claudeServiceProvider).generateMealPlan(prefs);

  return switch (result) {
    AppSuccess(:final data) => data,
    AppFailure(:final message) => throw Exception(message),
  };
});
```

### Usage in a Screen

```dart
ref.watch(mealPlanProvider).when(
  data: (plan) => MealPlanView(plan: plan),
  loading: () => const LoadingIndicator(),
  error: (e, _) => ErrorBanner(
    message: e.toString(),
    onRetry: () => ref.invalidate(mealPlanProvider),
  ),
);
```

---

## HTTP Error Handler (Reusable)

Define this in a base service or mixin:

```dart
AppFailure _handleHttpError(int statusCode, String body) {
  return switch (statusCode) {
    400 => AppFailure('Bad request', code: '400'),
    401 => AppFailure('Authentication failed', code: '401'),
    403 => AppFailure('Access denied', code: '403'),
    404 => AppFailure('Resource not found', code: '404'),
    429 => AppFailure('Rate limit exceeded', code: '429', isRetryable: true),
    >= 500 => AppFailure('Server error', code: '$statusCode', isRetryable: true),
    _   => AppFailure('Request failed ($statusCode)', code: '$statusCode'),
  };
}
```

---

## Retry with Exponential Backoff

Use this for 429 (rate limit) and 5xx (server) errors.

```dart
Future<AppResult<T>> withRetry<T>(
  Future<AppResult<T>> Function() call, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  Duration delay = initialDelay;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    final result = await call();

    if (result is AppSuccess<T>) return result;

    final failure = result as AppFailure<T>;
    final isLastAttempt = attempt == maxAttempts;

    // Only retry on retryable errors
    if (!failure.isRetryable || isLastAttempt) return result;

    await Future.delayed(delay);
    delay *= 2;  // exponential backoff: 1s → 2s → 4s
  }

  return const AppFailure('Max retries exceeded');
}
```

**Usage:**

```dart
final result = await withRetry(() => claudeService.generateMealPlan(prefs));
```

---

## Per-API Error Behavior

| API              | 401         | 429                        | 5xx              | Network error |
| ---------------- | ----------- | -------------------------- | ---------------- | ------------- |
| Claude           | Config error, no retry | Backoff 3x (1s/2s/4s) | Retry once (2s)  | Offline error |
| Supabase Auth    | Re-login    | N/A in practice            | Retry once       | Offline error |
| Supabase DB      | RLS denied  | N/A in practice            | Retry once       | Offline error |
| Google Places    | Key invalid | Backoff 3x (1s/2s/4s)     | Retry once (2s)  | Offline error |
| Open Food Facts  | N/A (no key)| Backoff 3x (2s/4s/8s)     | Retry once (3s)  | Offline error |
| Climatiq         | Key invalid | Backoff 3x (2s/4s/8s)     | Retry once (3s)  | Offline error |
| ML Kit           | N/A (offline) | N/A                      | N/A              | N/A (on-device) |

---

## Connectivity Check

Before making any external API call, check connectivity:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isConnected() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}
```

Add `connectivity_plus` to `pubspec.yaml`.

---

## User-Facing Error Messages

Never expose raw API errors to users. Map error codes to friendly messages:

```dart
String toUserMessage(String code) => switch (code) {
  'offline'         => 'No internet connection. Check your network and try again.',
  'timeout'         => 'The request took too long. Please try again.',
  '429'             => 'We\'re experiencing high demand. Please try again in a moment.',
  '401'             => 'Authentication error. Please sign in again.',
  'ocr_failed'      => 'Receipt scan failed. Please try again with better lighting.',
  'no_text_detected'=> 'No text was found on the receipt. Please retake the photo.',
  'meal_plan_parse_error' => 'Could not process the meal plan. Please try generating again.',
  _                 => 'Something went wrong. Please try again.',
};
```

---

## Supabase-Specific Error Handling

```dart
try {
  await supabase.from('receipts').insert(data);
} on PostgrestException catch (e) {
  return switch (e.code) {
    '23505' => AppFailure('This item already exists.', code: e.code),
    '42501' => AppFailure('Permission denied.', code: e.code),
    _       => AppFailure(e.message, code: e.code, isRetryable: true),
  };
} on AuthException catch (e) {
  return AppFailure('Session expired. Please sign in again.', code: 'auth_expired');
}
```

---

## Logging

Log errors for debugging, never log sensitive data (API keys, user tokens, PII):

```dart
// OK — log the error type and code
debugPrint('[ClaudeService] Error: ${failure.code} - ${failure.message}');

// NOT OK — never log these
debugPrint('API key: $apiKey');          // ← never
debugPrint('User email: ${user.email}'); // ← never
debugPrint('Raw OCR: $rawText');         // ← avoid (contains receipt details)
```

Use `debugPrint` in development. Wire to a proper logging package (e.g., `logger`) before production.
