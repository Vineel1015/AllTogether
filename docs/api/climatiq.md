# Climatiq API – Integration Guide

## Purpose in AllTogether

Climatiq provides CO₂ equivalent emission factors for food categories. After receipt items are matched to food products, Climatiq data is used to calculate the sustainability impact (CO₂e, water usage, land use) displayed on the Analytics page.

---

## Authentication

```
Authorization: Bearer <CLIMATIQ_API_KEY>
```

```dart
const climatiqApiKey = String.fromEnvironment('CLIMATIQ_API_KEY');
```

---

## Base URL

```
https://api.climatiq.io
```

---

## Endpoint Used

### Data Explorer – Emission Factor Estimate

```
POST https://api.climatiq.io/data/v1/estimate
```

**Headers:**

```
Authorization: Bearer <API_KEY>
Content-Type: application/json
```

**Request body:**

```json
{
  "emission_factor": {
    "activity_id": "consumer_goods-type_food_and_beverages-beef",
    "source": "IPCC",
    "region": "US",
    "year": 2024,
    "calculation_method": "ar5"
  },
  "parameters": {
    "weight": 1,
    "weight_unit": "kg"
  }
}
```

**Response:**

```json
{
  "co2e": 27.0,
  "co2e_unit": "kg",
  "co2e_calculation_method": "ar5",
  "emission_factor": {
    "activity_id": "consumer_goods-type_food_and_beverages-beef",
    "name": "Beef",
    "category": "Consumer Goods",
    "region": "US"
  }
}
```

---

## Activity ID Reference (Food Categories)

Use category-level activity IDs when product-level data is unavailable:

| Food Category       | Activity ID                                                    |
| ------------------- | -------------------------------------------------------------- |
| Beef                | `consumer_goods-type_food_and_beverages-beef`                  |
| Pork                | `consumer_goods-type_food_and_beverages-pork`                  |
| Poultry (chicken)   | `consumer_goods-type_food_and_beverages-poultry`               |
| Fish / Seafood      | `consumer_goods-type_food_and_beverages-fish`                  |
| Dairy (milk, cheese)| `consumer_goods-type_food_and_beverages-dairy_and_eggs`        |
| Eggs                | `consumer_goods-type_food_and_beverages-dairy_and_eggs`        |
| Vegetables          | `consumer_goods-type_food_and_beverages-vegetables`            |
| Fruits              | `consumer_goods-type_food_and_beverages-fruits`                |
| Grains / Bread      | `consumer_goods-type_food_and_beverages-cereals_and_bakery`    |
| Legumes / Beans     | `consumer_goods-type_food_and_beverages-pulses`                |
| Nuts / Seeds        | `consumer_goods-type_food_and_beverages-nuts_and_oilseeds`     |
| Beverages           | `consumer_goods-type_food_and_beverages-non_alcoholic_beverages` |
| Sugar / Sweets      | `consumer_goods-type_food_and_beverages-sugar_and_confectionery` |

> **Tip:** Map Open Food Facts `categories_tags` to activity IDs. Fall back to a general food activity ID if no match.

---

## Rate Limits

| Tier         | Requests/month | Requests/second |
| ------------ | -------------- | --------------- |
| Free (Lumen) | 1,000          | 10 RPS          |
| Starter      | 10,000         | 10 RPS          |
| Growth       | 100,000        | 20 RPS          |

> For V1, the free tier (1,000 calls/month) is likely sufficient if caching is implemented properly.

---

## Error Codes

| HTTP Status | Meaning                         | Action                                           |
| ----------- | ------------------------------- | ------------------------------------------------ |
| 200         | Success                         | Parse `co2e` from response                       |
| 400         | Invalid request / bad activity_id | Fix activity ID; do not retry                  |
| 401         | Invalid API key                 | Check key; surface config error                  |
| 404         | Activity ID not found           | Fall back to parent category ID                  |
| 429         | Rate limit exceeded             | Backoff: 2s → 4s → 8s (max 3 retries)           |
| 500         | Server error                    | Retry once after 3s                              |

### Fallback Hierarchy

```
Product-level ID not found (404)
    → Try category-level activity ID
        → Still not found
            → Use hardcoded average CO₂e per category (see table below)
```

### Hardcoded Fallback CO₂e Values (kg CO₂e per kg food)

| Category    | CO₂e (kg/kg) |
| ----------- | ------------ |
| Beef        | 27.0         |
| Lamb        | 39.2         |
| Pork        | 12.1         |
| Poultry     | 6.9          |
| Fish        | 6.1          |
| Dairy       | 3.2          |
| Eggs        | 4.8          |
| Vegetables  | 2.0          |
| Fruits      | 1.1          |
| Grains      | 1.4          |
| Legumes     | 0.9          |

---

## Caching Strategy

- Cache by **activity_id + weight_unit** → `co2e` value.
- Store in local Hive/Isar.
- Cache TTL: **90 days** — emission factors rarely change.
- This dramatically reduces API calls; most food categories will hit cache quickly.

```dart
String cacheKey = '${activityId}_${weightUnit}';
final cached = await climatiqCache.get(cacheKey);
if (cached != null) return AppSuccess(cached);
// else call Climatiq API
```

---

## Water & Land Use

Climatiq does not provide water or land use data directly. Use these hardcoded per-category averages (sourced from Our World in Data / Poore & Nemecek 2018):

| Category    | Water (L/kg) | Land (m²/kg) |
| ----------- | ------------ | ------------ |
| Beef        | 15,400       | 164.0        |
| Pork        | 5,988        | 11.0         |
| Poultry     | 4,325        | 7.1          |
| Dairy       | 1,020        | 8.9          |
| Eggs        | 3,265        | 5.7          |
| Vegetables  | 322          | 0.5          |
| Fruits      | 962          | 0.6          |
| Grains      | 1,644        | 3.4          |
| Legumes     | 2,693        | 2.2          |

Store these as constants in `app/lib/core/constants/sustainability_constants.dart`.

---

## Service Location

`app/lib/services/climatiq_service.dart`
