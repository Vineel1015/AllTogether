# Open Food Facts API – Integration Guide

## Purpose in AllTogether

Open Food Facts provides nutrition data (calories, protein, carbs, fat, fiber) for food items matched from scanned receipts. After OCR extracts item names from a receipt, this API is used to look up nutritional information.

---

## Key Facts

- **Free and open source** — no API key required.
- **No authentication** needed.
- **Be a good citizen** — do not hammer the API. Cache aggressively.
- Community-maintained data; some products may have incomplete nutrition info.

---

## Base URL

```
https://world.openfoodfacts.org
```

---

## Endpoints Used

### 1. Product Search by Name

```
GET https://world.openfoodfacts.org/cgi/search.pl
```

**Parameters:**

| Parameter         | Value                                              |
| ----------------- | -------------------------------------------------- |
| `search_terms`    | Food item name (URL-encoded)                       |
| `search_simple`   | `1`                                                |
| `action`          | `process`                                          |
| `json`            | `1`                                                |
| `page_size`       | `5` (only need top results)                        |
| `fields`          | `product_name,nutriments,categories_tags,image_url`|

**Example:**

```
GET https://world.openfoodfacts.org/cgi/search.pl
  ?search_terms=whole+milk
  &search_simple=1
  &action=process
  &json=1
  &page_size=5
  &fields=product_name,nutriments,categories_tags
```

**Response:**

```json
{
  "count": 243,
  "page": 1,
  "products": [
    {
      "product_name": "Whole Milk",
      "nutriments": {
        "energy-kcal_100g": 61,
        "proteins_100g": 3.2,
        "carbohydrates_100g": 4.8,
        "fat_100g": 3.3,
        "fiber_100g": 0
      },
      "categories_tags": ["en:dairy", "en:milks"]
    }
  ]
}
```

### 2. Product Lookup by Barcode

```
GET https://world.openfoodfacts.org/api/v3/product/{barcode}.json
```

> Barcode lookup is reserved for V2 (barcode scanning at point of purchase). Use name search for V1.

---

## Nutriments Field Reference

The key fields to extract from `nutriments`:

| Field                  | Unit       | Meaning              |
| ---------------------- | ---------- | -------------------- |
| `energy-kcal_100g`     | kcal       | Calories per 100g    |
| `proteins_100g`        | g          | Protein per 100g     |
| `carbohydrates_100g`   | g          | Carbs per 100g       |
| `fat_100g`             | g          | Fat per 100g         |
| `fiber_100g`           | g          | Fiber per 100g       |

Many products will be missing some fields. Always use null-safe access and default to `null` (display as "—" in UI).

---

## Rate Limits

No hard rate limit is enforced, but Open Food Facts requests responsible use:

- **Do not exceed ~100 requests/minute.**
- **Cache all responses** — this is the most important rule.
- Add a `User-Agent` header identifying your app:

```
User-Agent: AllTogether/1.0 (contact@example.com)
```

---

## Matching Strategy

Receipt OCR text is messy (e.g., `"WHL MLK 1GAL"`). Use this matching pipeline:

1. **Normalize** OCR text: lowercase, remove special characters, expand abbreviations.
2. **Search** Open Food Facts with the normalized string.
3. **Fuzzy match** the returned `product_name` values against the normalized query using Levenshtein distance.
4. **Pick the best match** above a similarity threshold (e.g., > 70%).
5. If no match found: store the item without nutrition data, flag for manual correction.

```dart
// Normalization examples
'WHL MLK 1GAL' → 'whole milk'
'CHKN BRST'    → 'chicken breast'
'OG SPNCH'     → 'organic spinach'
```

---

## Caching Strategy

- Cache by **normalized search term** → full product result.
- Store in local Hive/Isar as `FoodItem` model.
- Cache TTL: **30 days** — nutrition data changes rarely.
- If item is in cache and not expired, skip the API call entirely.

```dart
final cached = await foodCache.getByName(normalizedName);
if (cached != null) return AppSuccess(cached);
// else fetch from Open Food Facts
```

---

## Handling Missing Data

| Situation                          | Action                                              |
| ---------------------------------- | --------------------------------------------------- |
| Product not found                  | Store item with null nutrition; show "Data unavailable" |
| Specific nutriment field missing   | Default to `null`; show "—" in UI                  |
| `nutriments` object missing        | Treat as no data available                          |
| Multiple matches with low confidence | Store top match, allow user to correct manually   |

---

## HTTP Errors

| Status | Meaning              | Action                   |
| ------ | -------------------- | ------------------------ |
| 200    | Success              | Parse response           |
| 404    | Product not found    | Return empty result      |
| 429    | Too many requests    | Backoff: 2s → 4s → 8s   |
| 5xx    | Server error         | Retry once after 3s      |

---

## Service Location

`app/lib/services/food_facts_service.dart`
