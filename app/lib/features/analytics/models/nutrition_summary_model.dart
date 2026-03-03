/// Aggregated totals and daily averages across the full analysis period.
class NutritionSummary {
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;
  final double totalCost;

  /// Average calories per day, computed over days that have data.
  final double avgCaloriesPerDay;
  final double avgCostPerDay;

  const NutritionSummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    required this.totalCost,
    required this.avgCaloriesPerDay,
    required this.avgCostPerDay,
  });
}
