# Claude API – Integration Guide

## Purpose in AllTogether

The Claude API powers the **Finder** feature. It receives the user's dietary preferences and returns a structured 7-day meal plan as JSON.

---

## Model

```
claude-sonnet-4-6
```

Use Sonnet for meal plan generation — it balances output quality and cost. Do not use Opus unless instructed; do not use Haiku (output quality is insufficient for structured meal plans).

---

## Authentication

```
Authorization: x-api-key <CLAUDE_API_KEY>
anthropic-version: 2023-06-01
```

The key is read from the environment:

```dart
const claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');
```

**Never log or expose the API key.**

---

## Base URL

```
https://api.anthropic.com/v1/messages
```

---

## Request Shape

```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 4096,
  "messages": [
    {
      "role": "user",
      "content": "<structured prompt — see Prompt Template below>"
    }
  ]
}
```

### Prompt Template

```
You are a meal planning assistant. Generate a 7-day meal plan in valid JSON only.
No explanation, no markdown, no prose — return raw JSON.

User preferences:
- Diet type: {diet_type}
- Health goal: {health_goal}
- Diet style: {diet_style}
- Allergies: {allergies}
- Household size: {household_size}
- Weekly budget: {budget_range}
- Previously purchased (for variety): {recent_items_list}

Return JSON in this exact schema:
{
  "week_start": "YYYY-MM-DD",
  "days": [
    {
      "day": "Monday",
      "meals": {
        "breakfast": { "name": "", "ingredients": [], "calories": 0, "prep_minutes": 0 },
        "lunch":     { "name": "", "ingredients": [], "calories": 0, "prep_minutes": 0 },
        "dinner":    { "name": "", "ingredients": [], "calories": 0, "prep_minutes": 0 },
        "snack":     { "name": "", "ingredients": [], "calories": 0, "prep_minutes": 0 }
      }
    }
  ],
  "shopping_list": [
    { "item": "", "quantity": "", "estimated_cost": 0.0 }
  ]
}
```

---

## Rate Limits

| Tier          | Requests per minute (RPM) | Tokens per minute (TPM) | Tokens per day (TPD)  |
| ------------- | ------------------------- | ----------------------- | --------------------- |
| Free          | 5 RPM                     | 20,000 TPM              | —                     |
| Build (Tier 1)| 50 RPM                    | 40,000 TPM              | 1,000,000 TPD         |
| Scale (Tier 2)| 1,000 RPM                 | 80,000 TPM              | —                     |

> Meal plan generation uses ~1,500–2,500 input tokens and ~1,000–2,000 output tokens per request.

**Always check the `x-ratelimit-remaining-requests` and `x-ratelimit-remaining-tokens` response headers.**

---

## Error Codes

| HTTP Status | Meaning                        | Action                                           |
| ----------- | ------------------------------ | ------------------------------------------------ |
| 400         | Bad request / malformed prompt | Fix prompt; do not retry automatically           |
| 401         | Invalid API key                | Surface config error to user; do not retry       |
| 403         | Permission denied              | Check API key permissions; do not retry          |
| 429         | Rate limit exceeded            | Exponential backoff: 1s → 2s → 4s (max 3 retries) |
| 500         | Internal server error          | Retry once after 2s                              |
| 529         | API overloaded                 | Retry with backoff: 5s → 10s → 20s              |

### 429 Response Body

```json
{
  "type": "error",
  "error": {
    "type": "rate_limit_error",
    "message": "..."
  }
}
```

Check `Retry-After` header if present and honor it.

---

## Caching Strategy

> **Critical for cost control.** Claude is billed per token.

- Cache the full response JSON keyed by the **preference fingerprint**.
- Preference fingerprint = `SHA-256(diet_type + health_goal + diet_style + allergies.sorted().join(',') + household_size + budget_range)`.
- Store in local Hive/Isar with a `generated_at` timestamp.
- Cache TTL: **7 days** (one plan per week).
- Only regenerate when:
  - Preferences change (fingerprint changes).
  - User explicitly taps "Regenerate".
  - Cache is older than 7 days.

```dart
// Pseudocode
String fingerprint = sha256(userPrefs.toFingerprintString());
CachedPlan? cached = await planCache.get(fingerprint);
if (cached != null && !cached.isExpired()) return cached.plan;
// else call Claude API
```

---

## Output Validation

Claude may occasionally return malformed JSON. Always:

1. Try `jsonDecode(response)`.
2. If it fails, attempt to extract the JSON block between `{` and `}` using a regex.
3. Validate the decoded map against the expected schema.
4. If validation fails after two attempts, return `AppFailure('meal_plan_parse_error')`.

Do **not** show raw Claude output to the user.

---

## Cost Reference (approximate)

| Model              | Input (per 1M tokens) | Output (per 1M tokens) |
| ------------------ | --------------------- | ---------------------- |
| claude-sonnet-4-6  | $3.00                 | $15.00                 |

A typical meal plan call costs ~$0.005–$0.01. With caching, most users generate at most 1–2 plans per week.

---

## Service Location

`app/lib/services/claude_service.dart`
