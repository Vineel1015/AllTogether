import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/sustainability_constants.dart';
import '../../../core/utils/cache_utils.dart';
import '../../history/models/food_item_model.dart';
import '../../history/models/receipt_model.dart';
import '../models/analytics_model.dart';
import '../models/daily_nutrition_model.dart';
import '../models/nutrition_summary_model.dart';
import '../models/sustainability_summary_model.dart';

/// Pure computation service — no network calls, no Supabase.
///
/// Accepts an injectable [lookupFoodItem] for unit tests; defaults to
/// reading from the Hive food-item cache.
class AnalyticsService {
  final Future<FoodItem?> Function(String name) _lookupFoodItem;

  AnalyticsService({Future<FoodItem?> Function(String name)? lookupFoodItem})
      : _lookupFoodItem = lookupFoodItem ?? _defaultLookup;

  static Future<FoodItem?> _defaultLookup(String name) async {
    final box = Hive.box<String>(ApiConstants.foodItemCacheBox);
    return getCached(box, name, FoodItem.fromJson);
  }

  /// Computes analytics from [receipts] for the last 30 days.
  ///
  /// Each receipt item is looked up in the food-item cache. If found,
  /// nutrition values (per 100 g) are multiplied by [ReceiptItem.quantity]
  /// (treating each unit as one 100 g serving). Items with no cache match
  /// contribute 0 to all totals.
  Future<Analytics> compute(List<Receipt> receipts) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    final recentReceipts =
        receipts.where((r) => r.scannedAt.isAfter(cutoff)).toList();

    // date key → mutable accumulator
    final dailyMap = <String, _DayAccumulator>{};

    double totalCo2e = 0;
    double totalWater = 0;
    double totalLand = 0;

    for (final receipt in recentReceipts) {
      final dateKey = _dateKey(receipt.scannedAt);

      for (final item in receipt.items) {
        final foodItem = await _lookupFoodItem(item.name);
        final servings = item.quantity; // each unit ≈ 1 serving (100 g)

        if (foodItem != null) {
          final cal = (foodItem.caloriesPer100g ?? 0) * servings;
          final protein = (foodItem.proteinPer100g ?? 0) * servings;
          final carbs = (foodItem.carbsPer100g ?? 0) * servings;
          final fat = (foodItem.fatPer100g ?? 0) * servings;
          final fiber = (foodItem.fiberPer100g ?? 0) * servings;

          dailyMap
              .putIfAbsent(
                dateKey,
                () => _DayAccumulator(receipt.scannedAt),
              )
              .add(cal, protein, carbs, fat, fiber, item.price ?? 0.0);

          // Sustainability: 100 g per serving → 0.1 kg
          final weightKg = servings * 0.1;
          final category = mapCategory(foodItem.category);

          totalCo2e += (SustainabilityConstants.co2ePerKgByCategory[category] ??
                  SustainabilityConstants.co2ePerKgByCategory['default']!) *
              weightKg;
          totalWater +=
              (SustainabilityConstants.waterLitresPerKgByCategory[category] ??
                      SustainabilityConstants
                          .waterLitresPerKgByCategory['default']!) *
                  weightKg;
          totalLand +=
              (SustainabilityConstants.landM2PerKgByCategory[category] ??
                      SustainabilityConstants.landM2PerKgByCategory['default']!) *
                  weightKg;
        }
      }
    }

    final dailyNutrition = dailyMap.values
        .map((acc) => acc.toModel())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final numDays = dailyNutrition.length;

    double totalCal = 0,
        totalProtein = 0,
        totalCarbs = 0,
        totalFat = 0,
        totalFiber = 0,
        totalCost = 0;
    for (final day in dailyNutrition) {
      totalCal += day.totalCalories;
      totalProtein += day.totalProteinG;
      totalCarbs += day.totalCarbsG;
      totalFat += day.totalFatG;
      totalFiber += day.totalFiberG;
      totalCost += day.totalCost;
    }

    final avgCo2ePerDay = numDays > 0 ? totalCo2e / numDays : 0.0;
    final scoreColor = avgCo2ePerDay < 2.5
        ? 'green'
        : (avgCo2ePerDay <= 5.0 ? 'yellow' : 'red');

    return Analytics(
      dailyNutrition: dailyNutrition,
      nutritionSummary: NutritionSummary(
        totalCalories: totalCal,
        totalProteinG: totalProtein,
        totalCarbsG: totalCarbs,
        totalFatG: totalFat,
        totalFiberG: totalFiber,
        totalCost: totalCost,
        avgCaloriesPerDay: numDays > 0 ? totalCal / numDays : 0.0,
        avgCostPerDay: numDays > 0 ? totalCost / numDays : 0.0,
      ),
      sustainabilitySummary: SustainabilitySummary(
        totalCo2eKg: totalCo2e,
        totalWaterL: totalWater,
        totalLandM2: totalLand,
        avgCo2ePerDay: avgCo2ePerDay,
        scoreColor: scoreColor,
      ),
      generatedAt: now,
    );
  }

  /// Maps an Open Food Facts category tag to a [SustainabilityConstants] key.
  @visibleForTesting
  static String mapCategory(String? offTag) {
    if (offTag == null) return 'default';
    const categoryMap = <String, String>{
      'en:meats': 'meat',
      'en:beef': 'meat',
      'en:pork': 'meat',
      'en:poultry': 'poultry',
      'en:chicken': 'poultry',
      'en:seafood': 'seafood',
      'en:fish': 'seafood',
      'en:dairy': 'dairy',
      'en:milks': 'dairy',
      'en:cheeses': 'dairy',
      'en:eggs': 'eggs',
      'en:cereals': 'grains',
      'en:breads': 'grains',
      'en:grains': 'grains',
      'en:pasta': 'grains',
      'en:vegetables': 'vegetables',
      'en:fruits': 'fruits',
      'en:legumes': 'legumes',
      'en:beans': 'legumes',
      'en:nuts': 'nuts',
      'en:seeds': 'nuts',
    };
    return categoryMap[offTag.toLowerCase()] ?? 'default';
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── Private accumulator ────────────────────────────────────────────────────────

class _DayAccumulator {
  final DateTime _date;
  double _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;
  double _fiber = 0;
  double _cost = 0;

  _DayAccumulator(this._date);

  void add(
    double cal,
    double protein,
    double carbs,
    double fat,
    double fiber,
    double cost,
  ) {
    _calories += cal;
    _protein += protein;
    _carbs += carbs;
    _fat += fat;
    _fiber += fiber;
    _cost += cost;
  }

  DailyNutrition toModel() => DailyNutrition(
        date: DateTime(_date.year, _date.month, _date.day),
        totalCalories: _calories,
        totalProteinG: _protein,
        totalCarbsG: _carbs,
        totalFatG: _fat,
        totalFiberG: _fiber,
        totalCost: _cost,
      );
}
