import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:all_together/core/constants/api_constants.dart';
import 'package:all_together/core/models/app_result.dart';
import 'package:all_together/features/history/models/food_item_model.dart';
import 'package:all_together/services/food_facts_service.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

const _validProductJson = '''
{
  "count": 1,
  "products": [
    {
      "id": "abc123",
      "product_name": "Whole Milk",
      "code": "0012345678901",
      "nutriments": {
        "energy-kcal_100g": 61,
        "proteins_100g": 3.2,
        "carbohydrates_100g": 4.8,
        "fat_100g": 3.3,
        "fiber_100g": 0.0
      },
      "categories_tags": ["en:dairy", "en:milks"]
    }
  ]
}
''';

const _emptyProductsJson = '{"count": 0, "products": []}';

MockClient _stub(int statusCode, String body) =>
    MockClient((_) async => http.Response(body, statusCode));

/// Always reports the device as online so platform channels are never invoked.
Future<bool> _alwaysOnline() async => true;

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    // Open the box the service expects
    await Hive.openBox<String>(ApiConstants.foodItemCacheBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await Hive.box<String>(ApiConstants.foodItemCacheBox).clear();
  });

  group('FoodFactsService', () {
    test('200 with products returns AppSuccess<FoodItem?> with data', () async {
      final service = FoodFactsService(
          client: _stub(200, _validProductJson), isConnected: _alwaysOnline);

      final result = await service.lookupItem('whole milk');

      expect(result, isA<AppSuccess<FoodItem?>>());
      final item = (result as AppSuccess<FoodItem?>).data!;
      expect(item.name, 'Whole Milk');
      expect(item.caloriesPer100g, closeTo(61.0, 0.001));
      expect(item.proteinPer100g, closeTo(3.2, 0.001));
    });

    test('200 with empty products returns AppSuccess(null)', () async {
      final service = FoodFactsService(
          client: _stub(200, _emptyProductsJson), isConnected: _alwaysOnline);

      final result = await service.lookupItem('xyzzy unknown item');

      expect(result, isA<AppSuccess<FoodItem?>>());
      expect((result as AppSuccess<FoodItem?>).data, isNull);
    });

    test('429 response returns AppFailure with isRetryable true', () async {
      // Always returns 429 so all retry attempts fail.
      final service = FoodFactsService(
          client: _stub(429, ''), isConnected: _alwaysOnline)
        ..retryDelays = const [Duration.zero, Duration.zero, Duration.zero];

      final result = await service.lookupItem('milk');

      expect(result, isA<AppFailure<FoodItem?>>());
      final failure = result as AppFailure<FoodItem?>;
      expect(failure.isRetryable, isTrue);
      expect(failure.code, '429');
    });

    test('500 response returns AppFailure with isRetryable true', () async {
      final service = FoodFactsService(
          client: _stub(500, 'Internal Server Error'),
          isConnected: _alwaysOnline)
        ..retryDelays = const [Duration.zero, Duration.zero, Duration.zero];

      final result = await service.lookupItem('bread');

      expect(result, isA<AppFailure<FoodItem?>>());
      expect((result as AppFailure<FoodItem?>).isRetryable, isTrue);
    });

    test('cache hit skips HTTP — call count stays at 1', () async {
      int callCount = 0;
      final countingClient = MockClient((_) async {
        callCount++;
        return http.Response(_validProductJson, 200);
      });

      final service = FoodFactsService(
          client: countingClient, isConnected: _alwaysOnline);

      // First call — network
      await service.lookupItem('butter');
      expect(callCount, 1);

      // Second call — should be served from Hive cache
      await service.lookupItem('butter');
      expect(callCount, 1,
          reason: 'Second lookup should use cache, not HTTP');
    });

    test('blank normalized name returns AppSuccess(null) without HTTP call',
        () async {
      int callCount = 0;
      final noCallClient = MockClient((_) async {
        callCount++;
        return http.Response(_validProductJson, 200);
      });

      final service = FoodFactsService(
          client: noCallClient, isConnected: _alwaysOnline);
      final result = await service.lookupItem('   ');

      expect(result, isA<AppSuccess<FoodItem?>>());
      expect((result as AppSuccess<FoodItem?>).data, isNull);
      expect(callCount, 0);
    });
  });
}
