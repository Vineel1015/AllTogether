import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/models/app_result.dart';
import '../core/utils/cache_utils.dart';
import '../features/finder/models/store_result_model.dart';

/// Fetches nearby grocery stores from the Google Places Nearby Search API.
///
/// Results are cached in the `places_cache` Hive box for 24 hours, keyed by
/// rounded coordinates (3 d.p. ≈ 111 m precision) + radius.
class PlacesService {
  final http.Client _client;

  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  static const _cacheTtl = Duration(hours: 24);
  static const _defaultRadius = 5000;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns up to 20 grocery stores within [radiusMeters] of [lat]/[lng].
  ///
  /// Uses the 24-hour Hive cache first; falls back to the API when stale/missing.
  Future<AppResult<List<StoreResult>>> getNearbyStores({
    required double lat,
    required double lng,
    int radiusMeters = _defaultRadius,
  }) async {
    final cacheKey =
        '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}_$radiusMeters';
    final box = Hive.box<String>(ApiConstants.placesCacheBox);

    // 1. Cache hit
    final cached = await getCached<List<StoreResult>>(
      box,
      cacheKey,
      _listFromJson,
    );
    if (cached != null) {
      debugPrint('[PlacesService] Cache hit: $cacheKey');
      return AppSuccess(cached);
    }

    // 2. Fetch from Google Places
    return _fetchOnce(lat: lat, lng: lng, radius: radiusMeters, cacheKey: cacheKey, box: box);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AppResult<List<StoreResult>>> _fetchOnce({
    required double lat,
    required double lng,
    required int radius,
    required String cacheKey,
    required Box<String> box,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.googlePlacesBaseUrl}/nearbysearch/json',
    ).replace(queryParameters: {
      'location': '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
      'radius': '$radius',
      'type': 'grocery_or_supermarket',
      'key': ApiConstants.googlePlacesApiKey,
    });

    try {
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        return AppFailure(
          'HTTP ${response.statusCode}',
          code: '${response.statusCode}',
          isRetryable: response.statusCode >= 500,
        );
      }

      return _parseResponse(response.body, cacheKey, box);
    } on Exception catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  AppResult<List<StoreResult>> _parseResponse(
    String body,
    String cacheKey,
    Box<String> box,
  ) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';

      switch (status) {
        case 'OK':
          final results = (json['results'] as List)
              .cast<Map<String, dynamic>>()
              .map(StoreResult.fromPlacesJson)
              .toList();
          // Cache asynchronously — don't block the return.
          setCache<List<StoreResult>>(
            box,
            cacheKey,
            results,
            _listToJson,
            _cacheTtl,
          );
          debugPrint(
              '[PlacesService] Fetched ${results.length} stores, cached as $cacheKey');
          return AppSuccess(results);

        case 'ZERO_RESULTS':
          return const AppSuccess([]);

        case 'OVER_QUERY_LIMIT':
          return const AppFailure(
            'Places API rate limit exceeded.',
            code: '429',
            isRetryable: true,
          );

        case 'REQUEST_DENIED':
          return const AppFailure(
            'Places API key invalid or not enabled.',
            code: 'request_denied',
          );

        default:
          return AppFailure(
            'Places API error: $status',
            code: 'places_error',
          );
      }
    } catch (e) {
      return AppFailure('Failed to parse Places response: $e');
    }
  }

  // ── Cache serialization helpers ───────────────────────────────────────────

  static List<StoreResult> _listFromJson(Map<String, dynamic> json) {
    final items = json['items'] as List;
    return items
        .cast<Map<String, dynamic>>()
        .map(StoreResult.fromJson)
        .toList();
  }

  static Map<String, dynamic> _listToJson(List<StoreResult> stores) => {
        'items': stores.map((s) => s.toJson()).toList(),
      };
}
