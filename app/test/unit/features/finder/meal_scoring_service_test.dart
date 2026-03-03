import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/finder/models/meal_model.dart';
import 'package:all_together/features/finder/models/meal_score_model.dart';
import 'package:all_together/features/finder/models/weekly_plan_model.dart';
import 'package:all_together/features/finder/models/preset_meals.dart';
import 'package:all_together/features/finder/services/meal_scoring_service.dart';

void main() {
  const service = MealScoringService();

  // ── Helpers ───────────────────────────────────────────────────────────────

  WeeklyPlan makePlan(List<Meal> meals) => WeeklyPlan(
        userId: 'test-user',
        weekStartDate: DateTime(2025, 1, 6),
        meals: meals,
        createdAt: DateTime(2025, 1, 6),
      );

  // ── scoreUserPlan ──────────────────────────────────────────────────────────

  group('scoreUserPlan', () {
    test('returns null when plan is null', () {
      expect(service.scoreUserPlan(null), isNull);
    });

    test('returns null when plan has no meals', () {
      final plan = makePlan([]);
      expect(service.scoreUserPlan(plan), isNull);
    });

    test('returns average composite for two meals', () {
      // Meal A — all vegetables, low calorie
      const mealA = Meal(
        id: 'a',
        name: 'Veg Bowl',
        ingredients: ['spinach', 'broccoli', 'carrot'],
        calories: 150,
        prepMinutes: 10,
      );
      // Meal B — beef, high calorie
      const mealB = Meal(
        id: 'b',
        name: 'Beef',
        ingredients: ['beef'],
        calories: 900,
        prepMinutes: 10,
      );

      final scoreA = service.scoreMeal(mealA).compositeScore; // 74.5
      final scoreB = service.scoreMeal(mealB).compositeScore; // 16.5
      final expected = (scoreA + scoreB) / 2;

      final plan = makePlan([mealA, mealB]);
      final result = service.scoreUserPlan(plan);

      expect(result, closeTo(expected, 0.01));
    });
  });

  // ── scoreMeal — vegetable-heavy preset ────────────────────────────────────

  group('scoreMeal — Quinoa Buddha Bowl (vegetable-heavy)', () {
    // preset_l4: quinoa, chickpeas, roasted sweet potato, spinach, tahini dressing
    final buddhaBowl = presetMeals.firstWhere((m) => m.id == 'preset_l4');

    test('sustainabilityScore >= 70', () {
      final score = service.scoreMeal(buddhaBowl);
      expect(score.sustainabilityScore, greaterThanOrEqualTo(70));
    });
  });

  // ── scoreMeal — high-calorie meat meal ────────────────────────────────────

  group('scoreMeal — high-calorie meat meal', () {
    const meatMeal = Meal(
      id: 'test-meat',
      name: 'Big Beef Burger',
      ingredients: ['beef', 'butter', 'cheddar cheese'],
      calories: 900,
      prepMinutes: 20,
    );

    test('compositeScore < 50', () {
      final score = service.scoreMeal(meatMeal);
      expect(score.compositeScore, lessThan(50));
    });

    test("grade is 'D' or 'F'", () {
      final score = service.scoreMeal(meatMeal);
      expect(score.grade, anyOf('D', 'F'));
    });
  });

  // ── Grade thresholds ───────────────────────────────────────────────────────

  group('MealScore grade thresholds', () {
    test('composite 80 → A', () {
      final s = MealScore.fromScores(80, 80);
      expect(s.grade, 'A');
    });

    test('composite 65 → B', () {
      final s = MealScore.fromScores(65, 65);
      expect(s.grade, 'B');
    });

    test('composite 50 → C', () {
      final s = MealScore.fromScores(50, 50);
      expect(s.grade, 'C');
    });

    test('composite 35 → D', () {
      final s = MealScore.fromScores(35, 35);
      expect(s.grade, 'D');
    });

    test('composite 34 → F', () {
      final s = MealScore.fromScores(34, 34);
      expect(s.grade, 'F');
    });
  });

  // ── _ingredientCategory (tested via sustainability score) ──────────────────

  group('ingredient category mapping', () {
    // For single-ingredient meals, sustainabilityScore = _co2eToScore(co2eForCategory)

    test('"chicken breast" maps to poultry (co2e=6.9 → score=35)', () {
      const meal = Meal(
        id: 't1',
        name: 'Chicken',
        ingredients: ['chicken breast'],
        calories: 300,
        prepMinutes: 10,
      );
      // poultry = 6.9 → ≤6.9 → score = 35
      expect(service.scoreMeal(meal).sustainabilityScore, equals(35));
    });

    test('"red lentils" maps to legumes (co2e=0.9 → score=100)', () {
      const meal = Meal(
        id: 't2',
        name: 'Lentils',
        ingredients: ['red lentils'],
        calories: 300,
        prepMinutes: 10,
      );
      // legumes = 0.9 → ≤0.9 → score = 100
      expect(service.scoreMeal(meal).sustainabilityScore, equals(100));
    });

    test('"olive oil" maps to default (co2e=2.5 → score=55)', () {
      const meal = Meal(
        id: 't3',
        name: 'Olive Oil',
        ingredients: ['olive oil'],
        calories: 300,
        prepMinutes: 10,
      );
      // default = 2.5, 2.5 > 2.3, 2.5 ≤ 3.2 → score = 55
      expect(service.scoreMeal(meal).sustainabilityScore, equals(55));
    });
  });

  // ── healthScore sub-components ────────────────────────────────────────────

  group('healthScore — calorie tiers', () {
    double healthOf(int calories, int ingredientCount) {
      final meal = Meal(
        id: 'h',
        name: 'Test',
        ingredients: List.generate(ingredientCount, (i) => 'veg$i'),
        calories: calories,
        prepMinutes: 5,
      );
      return service.scoreMeal(meal).healthScore;
    }

    test('≤200 cal gives calorie tier 100', () {
      // diversity=3→30; health = 100*0.7+30*0.3=79
      expect(healthOf(200, 3), closeTo(79, 0.01));
    });

    test('201-350 cal gives calorie tier 85', () {
      // health = 85*0.7+30*0.3=68.5
      expect(healthOf(300, 3), closeTo(68.5, 0.01));
    });

    test('>800 cal gives calorie tier 20', () {
      // health = 20*0.7+30*0.3=23
      expect(healthOf(900, 3), closeTo(23, 0.01));
    });
  });

  group('healthScore — diversity tiers', () {
    double healthOf(int ingredientCount) {
      final meal = Meal(
        id: 'd',
        name: 'Test',
        ingredients: List.generate(ingredientCount, (i) => 'veg$i'),
        calories: 300,
        prepMinutes: 5,
      );
      return service.scoreMeal(meal).healthScore;
    }

    test('1-3 ingredients → diversity 30', () {
      // calorie=300→85; health=85*0.7+30*0.3=68.5
      expect(healthOf(2), closeTo(68.5, 0.01));
    });

    test('10+ ingredients → diversity 100', () {
      // calorie=300→85; health=85*0.7+100*0.3=89.5
      expect(healthOf(10), closeTo(89.5, 0.01));
    });
  });
}
