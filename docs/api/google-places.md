# Google Places API – Integration Guide

## Purpose in AllTogether

The Google Places API powers the **"Find Nearby Stores"** feature in the Finder screen. After a meal plan is generated, the user taps a button to find nearby grocery stores where they can purchase the shopping list items.

---

## API Key

```
Environment variable: GOOGLE_PLACES_API_KEY
```

For Flutter, inject via `--dart-define` and access:

```dart
const placesApiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
```

**Restrict the API key in Google Cloud Console:**
- Restrict to `Maps SDK for Android` and `Maps SDK for iOS` application restrictions.
- Restrict to `Places API` service.

---

## Endpoint Used

### Nearby Search

```
GET https://maps.googleapis.com/maps/api/place/nearbysearch/json
```

**Parameters:**

| Parameter    | Required | Value                                    |
| ------------ | -------- | ---------------------------------------- |
| `location`   | Yes      | `{lat},{lng}` — user's current location  |
| `radius`     | Yes      | `5000` (5 km default, max 50,000 m)      |
| `type`       | Yes      | `grocery_or_supermarket`                 |
| `key`        | Yes      | API key                                  |
| `rankby`     | No       | `distance` (use instead of `radius` for closest-first) |

> **Note**: `rankby=distance` and `radius` are mutually exclusive. Default to `radius=5000` unless the user is in a rural area.

**Example request:**

```
https://maps.googleapis.com/maps/api/place/nearbysearch/json
  ?location=37.7749,-122.4194
  &radius=5000
  &type=grocery_or_supermarket
  &key=<API_KEY>
```

**Example response:**

```json
{
  "status": "OK",
  "results": [
    {
      "name": "Whole Foods Market",
      "place_id": "ChIJ...",
      "vicinity": "123 Main St",
      "geometry": {
        "location": { "lat": 37.775, "lng": -122.419 }
      },
      "rating": 4.3,
      "opening_hours": { "open_now": true }
    }
  ],
  "next_page_token": "..."
}
```

---

## Getting User Location

Use the `geolocator` Flutter package:

```dart
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.medium,
);
```

Always handle `LocationPermission.denied` and `LocationPermission.deniedForever`.

---

## Rate Limits & Quotas

| Metric                      | Limit                                    |
| --------------------------- | ---------------------------------------- |
| Requests per day            | 100,000 (default quota)                  |
| Requests per second         | 100 QPS per project                      |
| Results per request         | Up to 20 (first page), up to 60 with pagination |

---

## Pricing

| Request Type          | Cost per 1,000 requests |
| --------------------- | ----------------------- |
| Nearby Search (basic) | $17.00                  |
| Free monthly credit   | $200 (Google gives this automatically) |

With $200/month in free credit you get ~11,764 Nearby Search calls for free. For V1 this is more than sufficient.

---

## Error Codes (`status` field in response)

| Status                | Meaning                                        | Action                                        |
| --------------------- | ---------------------------------------------- | --------------------------------------------- |
| `OK`                  | Success                                        | Parse results                                 |
| `ZERO_RESULTS`        | No stores found in radius                      | Show "No stores found nearby" to user         |
| `NOT_FOUND`           | Referenced location not found                  | Check coordinates                             |
| `INVALID_REQUEST`     | Missing or invalid parameter                   | Fix request construction; do not retry        |
| `OVER_DAILY_LIMIT`    | API key billing issue or quota exceeded        | Check billing; do not retry automatically     |
| `OVER_QUERY_LIMIT`    | Too many requests in a short time              | Backoff: 1s → 2s → 4s                        |
| `REQUEST_DENIED`      | API key invalid or not enabled for Places API  | Check key restrictions in Cloud Console       |
| `UNKNOWN_ERROR`       | Server-side error                              | Retry once after 2s                           |

---

## Caching Strategy

- Cache the Nearby Search results keyed by **rounded location** (round lat/lng to 3 decimal places ≈ 111m precision) + `radius`.
- Cache TTL: **24 hours** — store locations don't change frequently.
- Do not re-fetch if the user taps "Find Stores" multiple times without leaving the area.

```dart
String cacheKey = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}_$radius';
```

---

## Pagination

If more than 20 results are needed, use `next_page_token`:

```dart
// Wait at least 2 seconds before fetching the next page
await Future.delayed(const Duration(seconds: 2));
final nextPage = await fetchNearbyStores(pageToken: nextPageToken);
```

For V1, 20 results (one page) is sufficient.

---

## Permissions Required

Add to Android `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

Add to iOS `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>AllTogether needs your location to find nearby grocery stores.</string>
```

---

## Service Location

`app/lib/services/places_service.dart`
