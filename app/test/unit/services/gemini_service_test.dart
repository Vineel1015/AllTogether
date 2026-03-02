import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/core/models/app_result.dart';
import 'package:all_together/features/finder/models/meal_plan_model.dart';

const _validPlanJson = '''
{
  "week_start": "2026-02-24",
  "days": [
    {
      "day": "Monday",
      "meals": {
        "breakfast": {"name": "Oats", "ingredients": ["oats","milk"], "calories": 350, "prep_minutes": 5},
        "lunch":     {"name": "Salad", "ingredients": ["lettuce"], "calories": 200, "prep_minutes": 10},
        "dinner":    {"name": "Pasta", "ingredients": ["pasta","sauce"], "calories": 600, "prep_minutes": 20},
        "snack":     {"name": "Apple", "ingredients": ["apple"], "calories": 80, "prep_minutes": 0}
      }
    }
  ],
  "shopping_list": [
    {"item": "Oats", "quantity": "500g", "estimated_cost": 3.5}
  ]
}
''';

void main() {
  group('GeminiService – JSON extraction logic', () {
    test('parses clean JSON directly', () {
      final result = extractJson(_validPlanJson.trim());

      expect(result, isA<AppSuccess<Map<String, dynamic>>>());
      final data = (result as AppSuccess<Map<String, dynamic>>).data;
      expect(data['week_start'], '2026-02-24');
      expect((data['days'] as List).length, 1);
      expect((data['shopping_list'] as List).length, 1);
    });

    test('regex fallback extracts JSON when wrapped in prose', () {
      const withProse =
          'Here is your plan: {"week_start":"2026-02-24","days":[],"shopping_list":[]} Enjoy!';
      final result = extractJson(withProse);

      expect(result, isA<AppSuccess<Map<String, dynamic>>>());
    });

    test('returns AppFailure with meal_plan_parse_error on invalid input', () {
      final result = extractJson('Not JSON at all!');

      expect(result, isA<AppFailure<Map<String, dynamic>>>());
      expect(
        (result as AppFailure<Map<String, dynamic>>).code,
        'meal_plan_parse_error',
      );
    });
  });

  group('MealPlan model', () {
    test('fromClaudeJson parses days and shopping list correctly', () {
      final json = jsonDecode(_validPlanJson.trim()) as Map<String, dynamic>;
      final plan = MealPlan.fromClaudeJson(json, 'user-1', 'fp-abc');

      expect(plan.days.length, 1);
      expect(plan.days.first.day, 'Monday');
      expect(plan.days.first.breakfast.name, 'Oats');
      expect(plan.days.first.breakfast.calories, 350);
      expect(plan.shoppingList.length, 1);
      expect(plan.shoppingList.first.item, 'Oats');
      expect(plan.shoppingList.first.estimatedCost, 3.5);
      expect(plan.prefFingerprint, 'fp-abc');
    });

    test('toJson/fromJson round-trips cleanly', () {
      final json = jsonDecode(_validPlanJson.trim()) as Map<String, dynamic>;
      final plan = MealPlan.fromClaudeJson(json, 'user-1', 'fp-abc');
      final restored = MealPlan.fromJson(plan.toJson());

      expect(restored.days.length, plan.days.length);
      expect(restored.shoppingList.length, plan.shoppingList.length);
      expect(restored.prefFingerprint, plan.prefFingerprint);
    });

    test('totalEstimatedCost sums shopping list correctly', () {
      final json = jsonDecode(_validPlanJson.trim()) as Map<String, dynamic>;
      final plan = MealPlan.fromClaudeJson(json, 'user-1', 'fp-abc');

      expect(plan.totalEstimatedCost, closeTo(3.5, 0.001));
    });
  });
}

/// Mirrors the JSON extraction logic inside [GeminiService] for unit testing.
AppResult<Map<String, dynamic>> extractJson(String text) {
  try {
    return AppSuccess(jsonDecode(text.trim()) as Map<String, dynamic>);
  } catch (_) {}

  final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
  if (match != null) {
    try {
      return AppSuccess(jsonDecode(match.group(0)!) as Map<String, dynamic>);
    } catch (_) {}
  }

  return const AppFailure(
    'Could not extract JSON from Gemini response.',
    code: 'meal_plan_parse_error',
  );
}
