import '../../../core/constants/sustainability_constants.dart';
import '../models/meal_model.dart';
import '../models/meal_score_model.dart';
import '../models/weekly_plan_model.dart';

/// Pure, stateless service that scores meals and weekly plans.
///
/// No network calls are made — all logic is local.
class MealScoringService {
  const MealScoringService();

  // ── Keyword → SustainabilityConstants category ─────────────────────────────

  static const Map<String, String> _ingredientKeywords = {
    'beef': 'meat',
    'steak': 'meat',
    'lamb': 'meat',
    'pork': 'meat',
    'bacon': 'meat',
    'sausage': 'meat',
    'ham': 'meat',
    'chicken': 'poultry',
    'turkey': 'poultry',
    'duck': 'poultry',
    'salmon': 'seafood',
    'tuna': 'seafood',
    'fish': 'seafood',
    'shrimp': 'seafood',
    'prawn': 'seafood',
    'cod': 'seafood',
    'milk': 'dairy',
    'cheese': 'dairy',
    'butter': 'dairy',
    'cream': 'dairy',
    'yogurt': 'dairy',
    'whey': 'dairy',
    'egg': 'eggs',
    'rice': 'grains',
    'pasta': 'grains',
    'bread': 'grains',
    'oat': 'grains',
    'quinoa': 'grains',
    'flour': 'grains',
    'wheat': 'grains',
    'tortilla': 'grains',
    'wrap': 'grains',
    'spinach': 'vegetables',
    'broccoli': 'vegetables',
    'carrot': 'vegetables',
    'pepper': 'vegetables',
    'onion': 'vegetables',
    'garlic': 'vegetables',
    'tomato': 'vegetables',
    'cucumber': 'vegetables',
    'lettuce': 'vegetables',
    'kale': 'vegetables',
    'mushroom': 'vegetables',
    'zucchini': 'vegetables',
    'cauliflower': 'vegetables',
    'potato': 'vegetables',
    'cabbage': 'vegetables',
    'apple': 'fruits',
    'banana': 'fruits',
    'mango': 'fruits',
    'berry': 'fruits',
    'strawberry': 'fruits',
    'orange': 'fruits',
    'grape': 'fruits',
    'avocado': 'fruits',
    'lemon': 'fruits',
    'lentil': 'legumes',
    'chickpea': 'legumes',
    'bean': 'legumes',
    'pea': 'legumes',
    'tofu': 'legumes',
    'hummus': 'legumes',
    'edamame': 'legumes',
    'almond': 'nuts',
    'cashew': 'nuts',
    'walnut': 'nuts',
    'peanut': 'nuts',
    'pecan': 'nuts',
    'seed': 'nuts',
    'tahini': 'nuts',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Scores a single [meal].
  MealScore scoreMeal(Meal meal) {
    final health = _healthScore(meal);
    final sustainability = _sustainabilityScore(meal);
    return MealScore.fromScores(health, sustainability);
  }

  /// Returns the average composite score for all meals in [plan].
  ///
  /// Returns `null` when [plan] is null or contains no meals.
  double? scoreUserPlan(WeeklyPlan? plan) {
    if (plan == null || plan.meals.isEmpty) return null;
    final total =
        plan.meals.map((m) => scoreMeal(m).compositeScore).reduce((a, b) => a + b);
    return total / plan.meals.length;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  double _healthScore(Meal meal) {
    final calScore = _calorieScore(meal.calories);
    final divScore = _diversityScore(meal.ingredients.length);
    return calScore * 0.7 + divScore * 0.3;
  }

  double _calorieScore(int calories) {
    if (calories <= 200) return 100;
    if (calories <= 350) return 85;
    if (calories <= 500) return 70;
    if (calories <= 650) return 55;
    if (calories <= 800) return 35;
    return 20;
  }

  double _diversityScore(int count) {
    if (count <= 3) return 30;
    if (count <= 6) return 60;
    if (count <= 9) return 80;
    return 100;
  }

  double _sustainabilityScore(Meal meal) {
    if (meal.ingredients.isEmpty) {
      return _co2eToScore(
          SustainabilityConstants.co2ePerKgByCategory['default']!);
    }
    final total = meal.ingredients.fold<double>(0.0, (sum, ingredient) {
      final category = _ingredientCategory(ingredient);
      return sum + (SustainabilityConstants.co2ePerKgByCategory[category] ?? 2.5);
    });
    final avgCo2e = total / meal.ingredients.length;
    return _co2eToScore(avgCo2e);
  }

  /// Maps an ingredient string to a sustainability category via substring keyword match.
  String _ingredientCategory(String ingredient) {
    final lower = ingredient.toLowerCase();
    for (final entry in _ingredientKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'default';
  }

  double _co2eToScore(double avgCo2e) {
    if (avgCo2e <= 0.9) return 100;
    if (avgCo2e <= 1.4) return 85;
    if (avgCo2e <= 2.3) return 70;
    if (avgCo2e <= 3.2) return 55;
    if (avgCo2e <= 6.9) return 35;
    if (avgCo2e <= 10.0) return 20;
    return 10;
  }
}
