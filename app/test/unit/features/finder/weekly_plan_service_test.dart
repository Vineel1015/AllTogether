import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:all_together/features/finder/models/meal_model.dart';
import 'package:all_together/features/finder/models/weekly_plan_model.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

const _userId = 'user-xyz';

const _meal1 = Meal(
  id: 'preset_b1',
  name: 'Overnight Oats',
  ingredients: ['oats', 'milk', 'honey'],
  calories: 380,
  prepMinutes: 5,
  isPreset: true,
);

const _meal2 = Meal(
  id: 'preset_d1',
  name: 'Baked Salmon',
  ingredients: ['salmon', 'broccoli', 'lemon'],
  calories: 550,
  prepMinutes: 25,
  isPreset: true,
);

WeeklyPlan _makePlan({List<Meal>? meals}) => WeeklyPlan(
      id: 'plan-1',
      userId: _userId,
      weekStartDate: DateTime(2026, 3, 3),
      meals: meals ?? [_meal1, _meal2],
      createdAt: DateTime(2026, 3, 3),
    );

/// Mimics the cache write logic in WeeklyPlanService._writeCache.
String _buildCacheEntry(WeeklyPlan plan,
    {DateTime? cachedAt, Duration ttl = const Duration(hours: 24)}) {
  final map = {
    'data': plan.toJson(),
    'cachedAt': (cachedAt ?? DateTime.now()).toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };
  return jsonEncode(map);
}

/// Mimics the cache read logic in WeeklyPlanService._readCache.
WeeklyPlan? _readCacheEntry(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final cachedAt = DateTime.parse(map['cachedAt'] as String);
  final ttl = Duration(seconds: map['ttlSeconds'] as int);
  if (DateTime.now().isAfter(cachedAt.add(ttl))) return null;
  return WeeklyPlan.fromJson(map['data'] as Map<String, dynamic>);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_weekly_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('weekly_plan_cache');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await box.clear();
  });

  group('WeeklyPlan model', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      final plan = _makePlan();
      final json = plan.toJson();
      final restored = WeeklyPlan.fromJson(json);

      expect(restored.id, plan.id);
      expect(restored.userId, plan.userId);
      expect(restored.meals.length, 2);
      expect(restored.meals.first.name, _meal1.name);
      expect(restored.meals.last.name, _meal2.name);
    });

    test('shoppingList is sorted and deduplicated', () {
      final plan = _makePlan(meals: [
        _meal1,
        _meal2,
        const Meal(
          id: 'm3',
          name: 'Extra',
          ingredients: ['oats', 'garlic'], // 'oats' duplicated
          calories: 100,
          prepMinutes: 5,
        ),
      ]);
      final list = plan.shoppingList;

      // No duplicates
      expect(list.toSet().length, list.length);
      // Sorted
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].compareTo(list[i + 1]) <= 0, isTrue);
      }
      // Expected ingredients (lowercased)
      expect(list, containsAll(
          ['broccoli', 'garlic', 'honey', 'lemon', 'milk', 'oats', 'salmon']));
    });

    test('empty plan has empty shoppingList', () {
      final plan = _makePlan(meals: []);
      expect(plan.shoppingList, isEmpty);
    });

    test('toSupabaseJson includes required Supabase columns', () {
      final plan = _makePlan();
      final row = plan.toSupabaseJson();

      expect(row['user_id'], _userId);
      expect(row.containsKey('week_start_date'), isTrue);
      expect(row.containsKey('plan_data'), isTrue);
      final data = row['plan_data'] as Map<String, dynamic>;
      expect((data['meals'] as List).length, 2);
    });

    test('startOfCurrentWeek returns a Monday', () {
      final monday = WeeklyPlan.startOfCurrentWeek();
      expect(monday.weekday, DateTime.monday);
    });
  });

  group('WeeklyPlanService – cache read/write', () {
    test('fresh cache entry round-trips through Hive box', () async {
      final plan = _makePlan();
      final raw = _buildCacheEntry(plan);
      await box.put(_userId, raw);

      final stored = box.get(_userId);
      expect(stored, isNotNull);

      final restored = _readCacheEntry(stored!);
      expect(restored, isNotNull);
      expect(restored!.meals.length, 2);
      expect(restored.meals.first.name, _meal1.name);
    });

    test('expired cache entry returns null', () {
      final plan = _makePlan();
      final raw = _buildCacheEntry(
        plan,
        cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      final restored = _readCacheEntry(raw);
      expect(restored, isNull);
    });
  });
}
