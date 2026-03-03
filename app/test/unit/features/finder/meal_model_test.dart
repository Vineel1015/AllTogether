import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/finder/models/meal_model.dart';
import 'package:all_together/features/finder/models/weekly_plan_model.dart';
import 'package:all_together/features/finder/models/preset_meals.dart';

void main() {
  group('Meal model', () {
    const meal = Meal(
      id: 'test-1',
      userId: 'user-abc',
      name: 'Test Meal',
      ingredients: ['eggs', 'butter', 'toast'],
      calories: 400,
      prepMinutes: 10,
    );

    test('toJson / fromJson round-trip', () {
      final json = meal.toJson();
      final restored = Meal.fromJson(json);

      expect(restored.id, meal.id);
      expect(restored.userId, meal.userId);
      expect(restored.name, meal.name);
      expect(restored.ingredients, meal.ingredients);
      expect(restored.calories, meal.calories);
      expect(restored.prepMinutes, meal.prepMinutes);
    });

    test('fromSupabaseJson parses list ingredients', () {
      final row = {
        'id': 'sup-1',
        'user_id': 'user-1',
        'name': 'Supabase Meal',
        'ingredients': ['chicken', 'rice'],
        'calories': 600,
        'prep_minutes': 30,
      };
      final m = Meal.fromSupabaseJson(row);

      expect(m.id, 'sup-1');
      expect(m.ingredients, ['chicken', 'rice']);
      expect(m.isPreset, isFalse); // user_id is set
    });

    test('fromSupabaseJson marks preset when user_id is null', () {
      final row = {
        'id': 'preset_b1',
        'user_id': null,
        'name': 'Overnight Oats',
        'ingredients': ['oats', 'milk'],
        'calories': 380,
        'prep_minutes': 5,
      };
      final m = Meal.fromSupabaseJson(row);
      expect(m.isPreset, isTrue);
    });

    test('toSupabaseJson does not include id field', () {
      final json = meal.toSupabaseJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['name'], 'Test Meal');
      expect(json['ingredients'], ['eggs', 'butter', 'toast']);
    });

    test('round-trip through JSON string', () {
      final asString = jsonEncode(meal.toJson());
      final restored =
          Meal.fromJson(jsonDecode(asString) as Map<String, dynamic>);
      expect(restored.name, meal.name);
      expect(restored.calories, meal.calories);
    });
  });

  group('WeeklyPlan model', () {
    const meal1 = Meal(
      id: 'm1',
      name: 'Oats',
      ingredients: ['oats', 'milk', 'honey'],
      calories: 380,
      prepMinutes: 5,
    );
    const meal2 = Meal(
      id: 'm2',
      name: 'Salad',
      ingredients: ['lettuce', 'tomato', 'oats'], // 'oats' duplicated
      calories: 200,
      prepMinutes: 10,
    );

    final plan = WeeklyPlan(
      id: 'plan-1',
      userId: 'user-1',
      weekStartDate: DateTime(2026, 3, 3),
      meals: [meal1, meal2],
      createdAt: DateTime(2026, 3, 3),
    );

    test('shoppingList aggregates unique sorted ingredients', () {
      final list = plan.shoppingList;
      // All unique, lowercased, sorted
      expect(list, containsAll(['honey', 'lettuce', 'milk', 'oats', 'tomato']));
      expect(list.toSet().length, list.length); // no duplicates
      expect(list, equals([...list]..sort()));   // sorted
    });

    test('toJson / fromJson round-trip', () {
      final json = plan.toJson();
      final restored = WeeklyPlan.fromJson(json);

      expect(restored.id, plan.id);
      expect(restored.userId, plan.userId);
      expect(restored.meals.length, plan.meals.length);
      expect(restored.meals.first.name, meal1.name);
    });

    test('toSupabaseJson contains required columns', () {
      final row = plan.toSupabaseJson();
      expect(row['user_id'], 'user-1');
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

  group('presetMeals', () {
    test('contains exactly 15 meals', () {
      expect(presetMeals.length, 15);
    });

    test('all presets have isPreset=true and null userId', () {
      for (final meal in presetMeals) {
        expect(meal.isPreset, isTrue, reason: '${meal.name} should be preset');
        expect(meal.userId, isNull, reason: '${meal.name} should have null userId');
      }
    });

    test('all preset ids start with preset_', () {
      for (final meal in presetMeals) {
        expect(meal.id.startsWith('preset_'), isTrue,
            reason: '${meal.name} has unexpected id ${meal.id}');
      }
    });

    test('all presets have non-empty ingredients', () {
      for (final meal in presetMeals) {
        expect(meal.ingredients.isNotEmpty, isTrue,
            reason: '${meal.name} has no ingredients');
      }
    });
  });
}
