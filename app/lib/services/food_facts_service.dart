import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/models/app_result.dart';
import '../core/utils/cache_utils.dart';
import '../features/history/models/food_item_model.dart';

/// Looks up nutrition data for food items via the Open Food Facts API.
///
/// All responses are cached in the `food_item_cache` Hive box for 30 days.
/// No API key is required — add `User-Agent: AllTogether/1.0` to be polite.
class FoodFactsService {
  final http.Client _client;
  final Future<bool> Function() _isConnected;

  /// Delays between retry attempts. Override in tests to speed up execution.
  @visibleForTesting
  List<Duration> retryDelays = const [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  FoodFactsService({
    http.Client? client,
    /// Override in tests to avoid platform-channel calls.
    Future<bool> Function()? isConnected,
  })  : _client = client ?? http.Client(),
        _isConnected = isConnected ?? _defaultConnectivityCheck;

  static Future<bool> _defaultConnectivityCheck() async {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty &&
        !result.every((r) => r == ConnectivityResult.none);
  }

  static const _cacheTtl = Duration(days: 30);
  static const _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const _userAgent = 'AllTogether/1.0';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns nutrition data for [normalizedName], or [AppSuccess(null)] when
  /// no matching product is found.
  ///
  /// Uses the 30-day Hive cache first; falls back to the API when stale/missing.
  Future<AppResult<FoodItem?>> lookupItem(String normalizedName) async {
    if (normalizedName.trim().isEmpty) return const AppSuccess(null);

    final box = Hive.box<String>(ApiConstants.foodItemCacheBox);

    // 1. Cache hit
    final cached = await getCached<FoodItem>(
      box,
      normalizedName,
      FoodItem.fromJson,
    );
    if (cached != null) {
      debugPrint('[FoodFactsService] Cache hit: $normalizedName');
      return AppSuccess(cached);
    }

    // 2. Connectivity check
    if (!await _isConnected()) {
      return const AppFailure(
        'No internet connection.',
        code: 'offline',
        isRetryable: true,
      );
    }

    // 3. Fetch from Open Food Facts with exponential backoff
    return _fetchWithRetry(normalizedName, box);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AppResult<FoodItem?>> _fetchWithRetry(
    String normalizedName,
    Box<String> box,
  ) async {
    AppResult<FoodItem?>? lastResult;

    for (var attempt = 0; attempt < 3; attempt++) {
      lastResult = await _fetchOnce(normalizedName, box);

      if (lastResult is AppSuccess<FoodItem?>) return lastResult;

      final failure = lastResult as AppFailure<FoodItem?>;
      if (!failure.isRetryable || attempt == 2) return lastResult;

      await Future.delayed(retryDelays[attempt]);
    }

    return lastResult ?? const AppFailure('Max retries exceeded');
  }

  Future<AppResult<FoodItem?>> _fetchOnce(
    String normalizedName,
    Box<String> box,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'search_terms': normalizedName,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '5',
      'fields': 'product_name,nutriments,categories_tags,id,code',
    });

    try {
      final response = await _client.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        return _parseResponse(response.body, normalizedName, box);
      }

      return _handleHttpError(response.statusCode);
    } on SocketException {
      return const AppFailure(
        'No internet connection.',
        code: 'offline',
        isRetryable: true,
      );
    } on TimeoutException {
      return const AppFailure(
        'Request timed out.',
        code: 'timeout',
        isRetryable: true,
      );
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  Future<AppResult<FoodItem?>> _parseResponse(
    String body,
    String normalizedName,
    Box<String> box,
  ) async {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final products = json['products'] as List? ?? [];

      if (products.isEmpty) {
        debugPrint('[FoodFactsService] No match for: $normalizedName');
        return const AppSuccess(null);
      }

      final best = products.first as Map<String, dynamic>;
      final item = FoodItem.fromOpenFoodFactsJson(best, normalizedName);

      await setCache<FoodItem>(
        box,
        normalizedName,
        item,
        (f) => f.toJson(),
        _cacheTtl,
      );

      debugPrint('[FoodFactsService] Fetched and cached: $normalizedName');
      return AppSuccess(item);
    } catch (e) {
      return AppFailure('Failed to parse Open Food Facts response: $e');
    }
  }

  AppFailure<FoodItem?> _handleHttpError(int statusCode) => switch (statusCode) {
        429 => const AppFailure(
            'Rate limit exceeded.',
            code: '429',
            isRetryable: true,
          ),
        >= 500 => AppFailure(
            'Server error.',
            code: '$statusCode',
            isRetryable: true,
          ),
        _ => AppFailure(
            'Request failed ($statusCode).',
            code: '$statusCode',
          ),
      };
}
