/// Aggregated nutrition totals for a single calendar day.
class DailyNutrition {
  final DateTime date;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;

  const DailyNutrition({
    required this.date,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
  });
}
