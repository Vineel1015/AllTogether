import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/core/models/app_result.dart';
import 'package:all_together/features/customizations/models/user_preferences_model.dart';
import 'package:all_together/features/finder/models/meal_plan_model.dart';
import 'package:all_together/services/gemini_service.dart';

// ── Manual fake — no build_runner required ─────────────────────────────────

class _FakeGeminiService extends GeminiService {
  final AppResult<Map<String, dynamic>> response;
  _FakeGeminiService(this.response);

  @override
  Future<AppResult<Map<String, dynamic>>> generateMealPlan(
    UserPreferences prefs,
  ) async =>
      response;
}

// ── Shared fixtures ────────────────────────────────────────────────────────

const _testPrefs = UserPreferences(
  userId: 'user-1',
  dietType: 'omnivore',
  healthGoal: 'maintain',
  dietStyle: 'standard',
  allergies: [],
  householdSize: 2,
  budgetRange: r'$50-$100',
);

const _validPlanMap = <String, dynamic>{
  'week_start': '2026-02-24',
  'days': [
    {
      'day': 'Monday',
      'meals': {
        'breakfast': {
          'name': 'Oats',
          'ingredients': <String>['oats', 'milk'],
          'calories': 350,
          'prep_minutes': 5,
        },
        'lunch': {
          'name': 'Salad',
          'ingredients': <String>['lettuce'],
          'calories': 200,
          'prep_minutes': 10,
        },
        'dinner': {
          'name': 'Pasta',
          'ingredients': <String>['pasta', 'sauce'],
          'calories': 600,
          'prep_minutes': 20,
        },
        'snack': {
          'name': 'Apple',
          'ingredients': <String>['apple'],
          'calories': 80,
          'prep_minutes': 0,
        },
      },
    },
  ],
  'shopping_list': <Map<String, dynamic>>[
    {'item': 'Oats', 'quantity': '500g', 'estimated_cost': 3.5},
  ],
};

void main() {
  group('GeminiService (fake) – result propagation', () {
    test('returns AppSuccess when Gemini responds correctly', () async {
      final service = _FakeGeminiService(const AppSuccess(_validPlanMap));
      final result = await service.generateMealPlan(_testPrefs);

      expect(result, isA<AppSuccess<Map<String, dynamic>>>());
      final data = (result as AppSuccess<Map<String, dynamic>>).data;
      expect(data['week_start'], '2026-02-24');
    });

    test('returns AppFailure with offline code when offline', () async {
      const failure = AppFailure<Map<String, dynamic>>(
        'No internet connection.',
        code: 'offline',
        isRetryable: true,
      );
      final service = _FakeGeminiService(failure);
      final result = await service.generateMealPlan(_testPrefs);

      expect(result, isA<AppFailure<Map<String, dynamic>>>());
      expect((result as AppFailure<Map<String, dynamic>>).code, 'offline');
      expect(result.isRetryable, isTrue);
    });

    test('returns AppFailure on parse error', () async {
      const failure = AppFailure<Map<String, dynamic>>(
        'Could not extract JSON.',
        code: 'meal_plan_parse_error',
      );
      final service = _FakeGeminiService(failure);
      final result = await service.generateMealPlan(_testPrefs);

      expect(result, isA<AppFailure<Map<String, dynamic>>>());
      expect(
        (result as AppFailure<Map<String, dynamic>>).code,
        'meal_plan_parse_error',
      );
    });
  });

  group('MealPlan model', () {
    test('fromClaudeJson preserves fingerprint', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-xyz');
      expect(plan.prefFingerprint, 'fp-xyz');
    });

    test('fromClaudeJson parses days and meals correctly', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-xyz');

      expect(plan.days.length, 1);
      expect(plan.days.first.day, 'Monday');
      expect(plan.days.first.breakfast.name, 'Oats');
      expect(plan.days.first.breakfast.calories, 350);
      expect(plan.days.first.breakfast.ingredients, ['oats', 'milk']);
    });

    test('fromClaudeJson parses shopping list correctly', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-xyz');

      expect(plan.shoppingList.length, 1);
      expect(plan.shoppingList.first.item, 'Oats');
      expect(plan.shoppingList.first.estimatedCost, 3.5);
    });

    test('toSupabaseJson contains required Supabase columns', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-xyz');
      final row = plan.toSupabaseJson();

      expect(row['user_id'], 'user-1');
      expect(row['pref_fingerprint'], 'fp-xyz');
      expect(row.containsKey('week_start_date'), isTrue);
      expect(row.containsKey('plan_data'), isTrue);
    });

    test('round-trip through JSON string preserves structure', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-abc');
      // Simulate Hive string storage
      final asString = jsonEncode(plan.toJson());
      final restored =
          MealPlan.fromJson(jsonDecode(asString) as Map<String, dynamic>);

      expect(restored.days.length, plan.days.length);
      expect(restored.days.first.day, plan.days.first.day);
      expect(restored.shoppingList.length, plan.shoppingList.length);
      expect(restored.prefFingerprint, plan.prefFingerprint);
    });

    test('totalEstimatedCost sums all items', () {
      final plan = MealPlan.fromClaudeJson(_validPlanMap, 'user-1', 'fp-abc');
      expect(plan.totalEstimatedCost, closeTo(3.5, 0.001));
    });
  });
}
