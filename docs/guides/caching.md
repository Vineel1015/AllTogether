# Caching Strategy Guide

## Overview

Caching is critical in AllTogether for three reasons:
1. **Cost** — Claude API is billed per token; caching meal plans saves significant money.
2. **Performance** — most data doesn't change often; caching makes the app feel instant.
3. **Offline support** — cached data is available without a network connection.

---

## Local Cache: Hive or Isar

AllTogether uses on-device storage for all caches. Choose one:

| Library | Use When                                              |
| ------- | ----------------------------------------------------- |
| **Hive** | Simple key-value caching, lightweight, less setup    |
| **Isar** | Complex queries needed (filtering, sorting by field) |

**Recommendation:** Use **Hive** for V1. It's simpler and sufficient for all caching needs.

```yaml
# pubspec.yaml
hive_flutter: ^1.x
hive: ^2.x
```

Initialize in `main.dart`:

```dart
await Hive.initFlutter();
```

---

## Cache Store Reference

| Store Name          | Hive Box Name        | Key                            | Value Type         | TTL     |
| ------------------- | -------------------- | ------------------------------ | ------------------ | ------- |
| Meal plan cache     | `meal_plan_cache`    | SHA-256 preference fingerprint | JSON string        | 7 days  |
| Food item cache     | `food_item_cache`    | Normalized item name           | `FoodItem` JSON    | 30 days |
| Places cache        | `places_cache`       | `lat3,lng3_radius`             | Store list JSON    | 24 hrs  |
| Climatiq cache      | `climatiq_cache`     | `activityId_weightUnit`        | `co2e` double      | 90 days |

---

## Cache Helper Pattern

Define a reusable cache helper in `app/lib/core/utils/cache_utils.dart`:

```dart
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.cachedAt, required this.ttl});

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataSerializer) => {
    'data': dataSerializer(data),
    'cachedAt': cachedAt.toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };

  static CacheEntry<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataDeserializer,
  ) => CacheEntry(
    data: dataDeserializer(json['data']),
    cachedAt: DateTime.parse(json['cachedAt']),
    ttl: Duration(seconds: json['ttlSeconds']),
  );
}
```

### Reading from Cache

```dart
Future<T?> getCached<T>(Box box, String key, T Function(Map<String, dynamic>) fromJson) async {
  final raw = box.get(key);
  if (raw == null) return null;

  final entry = CacheEntry.fromJson<T>(jsonDecode(raw), fromJson);
  if (entry.isExpired) {
    await box.delete(key);
    return null;
  }
  return entry.data;
}
```

### Writing to Cache

```dart
Future<void> setCache<T>(
  Box box,
  String key,
  T data,
  Map<String, dynamic> Function(T) toJson,
  Duration ttl,
) async {
  final entry = CacheEntry(data: data, cachedAt: DateTime.now(), ttl: ttl);
  await box.put(key, jsonEncode(entry.toJson(toJson)));
}
```

---

## Per-API Caching Rules

### Claude API (Meal Plan)

```
Key:  SHA-256(userPrefs.toFingerprintString())
TTL:  7 days
When to skip cache:
  - User taps "Regenerate" button
  - Preferences have changed (new fingerprint)
  - Cached entry is expired
```

```dart
final fingerprint = sha256ofString(prefs.toFingerprintString());
final cached = await getCached(mealPlanBox, fingerprint, MealPlan.fromJson);
if (cached != null) return AppSuccess(cached);
// proceed with API call
```

### Open Food Facts (Nutrition Data)

```
Key:  normalized item name (lowercase, abbrevs expanded)
TTL:  30 days
When to skip cache:
  - Expired entry
  - User manually triggers refresh (V2 feature)
```

### Google Places (Nearby Stores)

```
Key:  "${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}_$radius"
TTL:  24 hours
When to skip cache:
  - Expired entry
  - User has moved >500m from cached location (optional V2 refinement)
```

### Climatiq (Emission Factors)

```
Key:  "${activityId}_${weightUnit}"
TTL:  90 days
When to skip cache:
  - Expired entry
```

---

## Offline-First Behavior

When the device is offline, serve cached data and display an indicator:

```dart
final connected = await isConnected();
if (!connected) {
  final cached = await getCached(...);
  if (cached != null) {
    // show banner: "Using cached data — connect for latest"
    return AppSuccess(cached);
  }
  return const AppFailure('No internet connection', code: 'offline', isRetryable: true);
}
```

---

## Cache Invalidation

| Trigger                              | Cache to invalidate              |
| ------------------------------------ | -------------------------------- |
| User updates dietary preferences     | `meal_plan_cache` (old fingerprint stays, new fingerprint is fresh) |
| User deletes account                 | All cache boxes (clear on logout)|
| App update with schema change        | Clear all boxes on version bump  |

Clear all caches on logout:

```dart
Future<void> clearAllCaches() async {
  await Hive.box('meal_plan_cache').clear();
  await Hive.box('food_item_cache').clear();
  await Hive.box('places_cache').clear();
  await Hive.box('climatiq_cache').clear();
}
```

---

## Cache Size Management

Hive boxes grow over time. Add a periodic cleanup for expired entries:

```dart
Future<void> evictExpiredEntries(Box box) async {
  final keysToDelete = <dynamic>[];
  for (final key in box.keys) {
    final raw = box.get(key);
    if (raw == null) continue;
    try {
      final entry = CacheEntry.fromJson(jsonDecode(raw), (d) => d);
      if (entry.isExpired) keysToDelete.add(key);
    } catch (_) {
      keysToDelete.add(key);  // corrupt entry — remove
    }
  }
  await box.deleteAll(keysToDelete);
}
```

Run during app startup (background, non-blocking):

```dart
unawaited(evictExpiredEntries(Hive.box('food_item_cache')));
```
