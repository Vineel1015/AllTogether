/// Aggregated totals and daily averages across the full analysis period.
class NutritionSummary {
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;

  /// Average calories per day, computed over days that have data.
  final double avgCaloriesPerDay;

  const NutritionSummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.avgCaloriesPerDay,
  });
}
