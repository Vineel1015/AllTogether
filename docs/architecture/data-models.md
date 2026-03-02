# AllTogether – Data Models

All models exist in two forms:
- **Supabase (PostgreSQL)** — server-side, source of truth.
- **Dart model class** — local representation in `app/lib/features/<feature>/models/`.

---

## User

**Supabase table:** Managed by `auth.users` (Supabase built-in).

**Dart model:** `app/lib/features/auth/models/app_user_model.dart`

```dart
class AppUser {
  final String id;        // UUID — maps to auth.users.id
  final String email;
  final String name;
  final DateTime createdAt;
}
```

---

## UserPreferences

**Supabase table:** `user_preferences`

```sql
CREATE TABLE user_preferences (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diet_type    TEXT NOT NULL,   -- 'omnivore' | 'vegetarian' | 'vegan' | 'pescatarian'
  health_goal  TEXT NOT NULL,   -- 'lose_weight' | 'gain_weight' | 'maintain' | 'build_muscle'
  diet_style   TEXT NOT NULL,   -- 'standard' | 'keto' | 'high_protein' | 'low_carb' | 'mediterranean'
  allergies    TEXT[] DEFAULT '{}',  -- e.g. ['gluten', 'dairy']
  household_size INT NOT NULL DEFAULT 1,
  budget_range TEXT NOT NULL,   -- e.g. '$50-$100'
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
```

**Dart model:** `app/lib/features/customizations/models/user_preferences_model.dart`

```dart
class UserPreferences {
  final String userId;
  final String dietType;
  final String healthGoal;
  final String dietStyle;
  final List<String> allergies;
  final int householdSize;
  final String budgetRange;

  // Used for Claude API caching
  String toFingerprintString() =>
    '$dietType|$healthGoal|$dietStyle|${(allergies..sort()).join(',')}|$householdSize|$budgetRange';
}
```

---

## MealPlan

**Supabase table:** `meal_plans`

```sql
CREATE TABLE meal_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  week_start_date DATE NOT NULL,
  plan_data       JSONB NOT NULL,   -- full Claude response JSON
  pref_fingerprint TEXT NOT NULL    -- SHA-256 of UserPreferences.toFingerprintString()
);
```

**Dart model:** `app/lib/features/finder/models/meal_plan_model.dart`

```dart
class MealPlan {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime weekStartDate;
  final Map<String, dynamic> planData;  // parsed from JSONB
  final String prefFingerprint;
}
```

---

## Receipt

**Supabase table:** `receipts`

```sql
CREATE TABLE receipts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scanned_at    TIMESTAMPTZ DEFAULT NOW(),
  store_name    TEXT,
  raw_ocr_text  TEXT NOT NULL,
  total_amount  NUMERIC(10, 2),
  image_url     TEXT   -- path in Supabase Storage
);
```

**Dart model:** `app/lib/features/history/models/receipt_model.dart`

```dart
class Receipt {
  final String id;
  final String userId;
  final DateTime scannedAt;
  final String? storeName;
  final String rawOcrText;
  final double? totalAmount;
  final String? imageUrl;
}
```

---

## ReceiptItem

**Supabase table:** `receipt_items`

```sql
CREATE TABLE receipt_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id      UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,      -- normalized OCR text
  raw_name        TEXT NOT NULL,      -- original OCR text
  quantity        NUMERIC DEFAULT 1,
  price           NUMERIC(10, 2),
  matched_food_id TEXT               -- Open Food Facts product ID (nullable)
);
```

**Dart model:** `app/lib/features/history/models/receipt_item_model.dart`

```dart
class ReceiptItem {
  final String id;
  final String receiptId;
  final String name;
  final String rawName;
  final double quantity;
  final double? price;
  final String? matchedFoodId;
}
```

---

## FoodItem

**Purpose:** Local cache of Open Food Facts nutrition data. Stored in Hive/Isar; not synced to Supabase.

**Dart model:** `app/lib/features/history/models/food_item_model.dart`

```dart
class FoodItem {
  final String id;            // Open Food Facts product ID or search key
  final String name;
  final String? barcode;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
  final double? co2ePerKg;    // from Climatiq or hardcoded fallback
  final double? waterPerKg;   // hardcoded by category
  final double? landPerKg;    // hardcoded by category
  final String? category;     // Open Food Facts category tag
  final DateTime cachedAt;
}
```

---

## Nutrition Summary (Computed — not stored)

Computed from `ReceiptItem` × `FoodItem` data. Used on the Analytics page.

```dart
class NutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;
}
```

---

## SustainabilitySummary (Computed — not stored)

```dart
class SustainabilitySummary {
  final DateTime date;
  final double totalCo2eKg;
  final double totalWaterL;
  final double totalLandM2;
  final String scoreColor;  // 'green' | 'yellow' | 'red'
}
```

---

## Supabase RLS Summary

| Table             | RLS Policy                              |
| ----------------- | --------------------------------------- |
| user_preferences  | `auth.uid() = user_id` on all ops       |
| meal_plans        | `auth.uid() = user_id` on all ops       |
| receipts          | `auth.uid() = user_id` on all ops       |
| receipt_items     | Via `receipts.user_id` join             |

Apply every RLS policy before any production data is stored.

---

## Local Cache Models (Hive/Isar)

| Cache Store         | Key                        | Value         | TTL     |
| ------------------- | -------------------------- | ------------- | ------- |
| `meal_plan_cache`   | pref_fingerprint           | MealPlan JSON | 7 days  |
| `food_item_cache`   | normalized item name       | FoodItem      | 30 days |
| `places_cache`      | `lat,lng_radius`           | Store list    | 24 hrs  |
| `climatiq_cache`    | `activity_id_weight_unit`  | co2e value    | 90 days |
