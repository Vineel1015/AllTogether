import 'daily_nutrition_model.dart';
import 'nutrition_summary_model.dart';
import 'sustainability_summary_model.dart';

/// Top-level container for all computed analytics data.
class Analytics {
  final List<DailyNutrition> dailyNutrition;
  final NutritionSummary nutritionSummary;
  final SustainabilitySummary sustainabilitySummary;
  final DateTime generatedAt;

  const Analytics({
    required this.dailyNutrition,
    required this.nutritionSummary,
    required this.sustainabilitySummary,
    required this.generatedAt,
  });

  bool get isEmpty => dailyNutrition.isEmpty;
}
