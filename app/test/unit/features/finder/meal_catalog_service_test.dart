import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:all_together/core/models/app_result.dart';
import 'package:all_together/features/finder/models/meal_model.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

const _userId = 'user-abc';

/// Builds a cache entry the same way MealCatalogService._writeCache does.
String _buildCacheEntry(List<Meal> meals,
    {Duration ttl = const Duration(hours: 1), DateTime? cachedAt}) {
  final map = {
    'meals': meals.map((m) => m.toJson()).toList(),
    'cachedAt': (cachedAt ?? DateTime.now()).toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };
  return jsonEncode(map);
}

/// Reads a cache entry the same way MealCatalogService._readCache does.
List<Meal>? _readCacheEntry(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final cachedAt = DateTime.parse(map['cachedAt'] as String);
  final ttl = Duration(seconds: map['ttlSeconds'] as int);
  if (DateTime.now().isAfter(cachedAt.add(ttl))) return null;
  return (map['meals'] as List)
      .map((m) => Meal.fromJson(m as Map<String, dynamic>))
      .toList();
}

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_catalog_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('meal_catalog_cache');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await box.clear();
  });

  group('MealCatalogService – cache logic', () {
    const meal1 = Meal(
      id: 'preset_b1',
      name: 'Overnight Oats',
      ingredients: ['oats', 'milk'],
      calories: 380,
      prepMinutes: 5,
      isPreset: true,
    );
    const meal2 = Meal(
      id: 'user-1',
      userId: _userId,
      name: 'My Salad',
      ingredients: ['lettuce', 'tomato'],
      calories: 200,
      prepMinutes: 5,
    );

    test('fresh cache entry returns meals correctly', () {
      final raw = _buildCacheEntry([meal1, meal2]);
      final meals = _readCacheEntry(raw);

      expect(meals, isNotNull);
      expect(meals!.length, 2);
      expect(meals.first.name, 'Overnight Oats');
      expect(meals.last.name, 'My Salad');
    });

    test('expired cache entry returns null', () {
      final raw = _buildCacheEntry(
        [meal1],
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final meals = _readCacheEntry(raw);
      expect(meals, isNull);
    });

    test('cache survives Hive put/get round-trip', () async {
      const key = 'user_meals:$_userId';
      await box.put(key, _buildCacheEntry([meal1]));

      final raw = box.get(key);
      expect(raw, isNotNull);

      final meals = _readCacheEntry(raw!);
      expect(meals!.first.name, 'Overnight Oats');
    });
  });

  group('Meal model – serialization', () {
    test('toJson / fromJson round-trips all fields', () {
      const meal = Meal(
        id: 'test-1',
        userId: _userId,
        name: 'Test Meal',
        ingredients: ['eggs', 'butter'],
        calories: 300,
        prepMinutes: 8,
      );
      final restored = Meal.fromJson(meal.toJson());

      expect(restored.id, meal.id);
      expect(restored.userId, meal.userId);
      expect(restored.name, meal.name);
      expect(restored.ingredients, meal.ingredients);
      expect(restored.calories, meal.calories);
      expect(restored.prepMinutes, meal.prepMinutes);
    });

    test('toSupabaseJson omits id', () {
      const meal = Meal(
        id: 'local-id',
        userId: _userId,
        name: 'Insert Me',
        ingredients: ['egg'],
        calories: 100,
        prepMinutes: 5,
      );
      final row = meal.toSupabaseJson();
      expect(row.containsKey('id'), isFalse);
      expect(row['user_id'], _userId);
    });

    test('fromSupabaseJson with null user_id sets isPreset=true', () {
      final row = {
        'id': 'preset_s1',
        'user_id': null,
        'name': 'Trail Mix',
        'ingredients': ['almonds', 'raisins'],
        'calories': 250,
        'prep_minutes': 0,
      };
      final meal = Meal.fromSupabaseJson(row);
      expect(meal.isPreset, isTrue);
      expect(meal.userId, isNull);
    });
  });

  group('AppResult pattern – MealCatalogService error shapes', () {
    test('AppFailure carries message, code, isRetryable', () {
      const failure = AppFailure<List<Meal>>(
        'Failed to load meals',
        code: 'unknown',
        isRetryable: false,
      );
      expect(failure.message, 'Failed to load meals');
      expect(failure.code, 'unknown');
      expect(failure.isRetryable, isFalse);
    });

    test('AppSuccess wraps meal list', () {
      const meals = <Meal>[
        Meal(
          id: 'x',
          name: 'X',
          ingredients: ['x'],
          calories: 1,
          prepMinutes: 1,
        ),
      ];
      const result = AppSuccess<List<Meal>>(meals);
      expect(result.data.first.name, 'X');
    });
  });
}
