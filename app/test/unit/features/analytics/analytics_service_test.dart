import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/analytics/services/analytics_service.dart';
import 'package:all_together/features/history/models/food_item_model.dart';
import 'package:all_together/features/history/models/receipt_item_model.dart';
import 'package:all_together/features/history/models/receipt_model.dart';

// ── Fake data ──────────────────────────────────────────────────────────────────

final _fakeItems = <String, FoodItem>{
  'whole milk': FoodItem(
    id: 'milk',
    name: 'whole milk',
    caloriesPer100g: 61,
    proteinPer100g: 3.2,
    carbsPer100g: 4.8,
    fatPer100g: 3.3,
    fiberPer100g: 0,
    category: 'en:dairy',
    cachedAt: DateTime(2025),
  ),
  'chicken breast': FoodItem(
    id: 'chicken',
    name: 'chicken breast',
    caloriesPer100g: 165,
    proteinPer100g: 31,
    carbsPer100g: 0,
    fatPer100g: 3.6,
    fiberPer100g: 0,
    category: 'en:poultry',
    cachedAt: DateTime(2025),
  ),
  'beef steak': FoodItem(
    id: 'beef',
    name: 'beef steak',
    caloriesPer100g: 250,
    proteinPer100g: 26,
    carbsPer100g: 0,
    fatPer100g: 17,
    fiberPer100g: 0,
    category: 'en:beef',
    cachedAt: DateTime(2025),
  ),
};

Future<FoodItem?> _fakeLookup(String name) async => _fakeItems[name];

ReceiptItem _item(String name, {double quantity = 1}) => ReceiptItem(
      receiptId: 'r1',
      name: name,
      rawName: name.toUpperCase(),
      quantity: quantity,
    );

Receipt _receipt(List<ReceiptItem> items, {DateTime? scannedAt}) => Receipt(
      userId: 'u1',
      scannedAt: scannedAt ?? DateTime.now(),
      rawOcrText: '',
      items: items,
    );

void main() {
  late AnalyticsService service;

  setUp(() {
    service = AnalyticsService(lookupFoodItem: _fakeLookup);
  });

  // ── compute() ──────────────────────────────────────────────────────────────

  group('AnalyticsService.compute', () {
    test('empty receipts list → Analytics.isEmpty is true', () async {
      final result = await service.compute([]);
      expect(result.isEmpty, isTrue);
      expect(result.dailyNutrition, isEmpty);
      expect(result.nutritionSummary.totalCalories, 0);
      expect(result.sustainabilitySummary.totalCo2eKg, 0);
    });

    test('receipt with matched item → correct calorie and protein totals', () async {
      // 1 unit of whole milk = 61 kcal, 3.2 g protein
      final receipt = _receipt([_item('whole milk')]);
      final result = await service.compute([receipt]);

      expect(result.isEmpty, isFalse);
      expect(result.nutritionSummary.totalCalories, closeTo(61, 0.01));
      expect(result.nutritionSummary.totalProteinG, closeTo(3.2, 0.01));
    });

    test('quantity multiplier scales nutrition linearly', () async {
      // 2 units of whole milk = 2 × 61 = 122 kcal
      final receipt = _receipt([_item('whole milk', quantity: 2)]);
      final result = await service.compute([receipt]);

      expect(result.nutritionSummary.totalCalories, closeTo(122, 0.01));
    });

    test('receipt item with no cache match contributes 0 to all totals', () async {
      final receipt = _receipt([_item('unknown food xyz')]);
      final result = await service.compute([receipt]);

      expect(result.isEmpty, isTrue);
      expect(result.nutritionSummary.totalCalories, 0);
    });

    test('multi-day receipts → dailyNutrition has one entry per day', () async {
      final day1 = DateTime.now().subtract(const Duration(days: 2));
      final day2 = DateTime.now().subtract(const Duration(days: 1));

      final receipts = [
        _receipt([_item('whole milk')], scannedAt: day1),
        _receipt([_item('chicken breast')], scannedAt: day2),
      ];

      final result = await service.compute(receipts);

      expect(result.dailyNutrition.length, 2);
      // Sorted oldest first
      expect(result.dailyNutrition.first.totalCalories, closeTo(61, 0.01));
      expect(result.dailyNutrition.last.totalCalories, closeTo(165, 0.01));
    });

    test('same-day receipts are merged into a single DailyNutrition entry', () async {
      final today = DateTime.now();
      final receipts = [
        _receipt([_item('whole milk')], scannedAt: today),
        _receipt([_item('chicken breast')], scannedAt: today),
      ];

      final result = await service.compute(receipts);

      expect(result.dailyNutrition.length, 1);
      expect(
        result.dailyNutrition.first.totalCalories,
        closeTo(61 + 165, 0.01),
      );
    });

    test('receipts older than 30 days are excluded', () async {
      final old = DateTime.now().subtract(const Duration(days: 31));
      final receipt = _receipt([_item('whole milk')], scannedAt: old);
      final result = await service.compute([receipt]);

      expect(result.isEmpty, isTrue);
    });

    test('avgCaloriesPerDay is computed over days with data only', () async {
      final day1 = DateTime.now().subtract(const Duration(days: 2));
      final day2 = DateTime.now();
      // milk = 61 kcal, chicken = 165 kcal → avg = (61+165)/2 = 113
      final receipts = [
        _receipt([_item('whole milk')], scannedAt: day1),
        _receipt([_item('chicken breast')], scannedAt: day2),
      ];

      final result = await service.compute(receipts);

      expect(result.nutritionSummary.avgCaloriesPerDay, closeTo(113, 0.01));
    });
  });

  // ── Sustainability score ───────────────────────────────────────────────────

  group('SustainabilitySummary.scoreColor', () {
    // dairy co2e = 3.2 kg/kg × 0.1 kg = 0.32 kg CO₂e
    // With 1 day of data: avg = 0.32 → green
    test('avg CO₂e < 2.5 kg/day → scoreColor is green', () async {
      final receipt = _receipt([_item('whole milk')]); // dairy: 0.32 kg CO₂e
      final result = await service.compute([receipt]);

      expect(result.sustainabilitySummary.scoreColor, 'green');
    });

    // beef co2e = 27 kg/kg × 0.1 kg = 2.7 kg CO₂e → yellow (2.5–5.0)
    test('avg CO₂e > 2.5 and ≤ 5.0 kg/day → scoreColor is yellow', () async {
      final receipt = _receipt([_item('beef steak')]); // meat: 2.7 kg CO₂e
      final result = await service.compute([receipt]);

      expect(result.sustainabilitySummary.scoreColor, 'yellow');
    });

    // beef × 2 units = 5.4 kg CO₂e → red (> 5.0)
    test('avg CO₂e > 5.0 kg/day → scoreColor is red', () async {
      final receipt =
          _receipt([_item('beef steak', quantity: 2)]); // 27×0.2 = 5.4
      final result = await service.compute([receipt]);

      expect(result.sustainabilitySummary.scoreColor, 'red');
    });
  });

  // ── mapCategory ────────────────────────────────────────────────────────────

  group('AnalyticsService.mapCategory', () {
    test('en:dairy → dairy', () {
      expect(AnalyticsService.mapCategory('en:dairy'), 'dairy');
    });

    test('en:meats → meat', () {
      expect(AnalyticsService.mapCategory('en:meats'), 'meat');
    });

    test('en:beef → meat', () {
      expect(AnalyticsService.mapCategory('en:beef'), 'meat');
    });

    test('en:pork → meat', () {
      expect(AnalyticsService.mapCategory('en:pork'), 'meat');
    });

    test('en:poultry → poultry', () {
      expect(AnalyticsService.mapCategory('en:poultry'), 'poultry');
    });

    test('en:chicken → poultry', () {
      expect(AnalyticsService.mapCategory('en:chicken'), 'poultry');
    });

    test('en:seafood → seafood', () {
      expect(AnalyticsService.mapCategory('en:seafood'), 'seafood');
    });

    test('en:fish → seafood', () {
      expect(AnalyticsService.mapCategory('en:fish'), 'seafood');
    });

    test('en:milks → dairy', () {
      expect(AnalyticsService.mapCategory('en:milks'), 'dairy');
    });

    test('en:cheeses → dairy', () {
      expect(AnalyticsService.mapCategory('en:cheeses'), 'dairy');
    });

    test('en:eggs → eggs', () {
      expect(AnalyticsService.mapCategory('en:eggs'), 'eggs');
    });

    test('en:cereals → grains', () {
      expect(AnalyticsService.mapCategory('en:cereals'), 'grains');
    });

    test('en:vegetables → vegetables', () {
      expect(AnalyticsService.mapCategory('en:vegetables'), 'vegetables');
    });

    test('en:fruits → fruits', () {
      expect(AnalyticsService.mapCategory('en:fruits'), 'fruits');
    });

    test('en:legumes → legumes', () {
      expect(AnalyticsService.mapCategory('en:legumes'), 'legumes');
    });

    test('en:nuts → nuts', () {
      expect(AnalyticsService.mapCategory('en:nuts'), 'nuts');
    });

    test('unknown tag → default', () {
      expect(AnalyticsService.mapCategory('en:snacks'), 'default');
    });

    test('null → default', () {
      expect(AnalyticsService.mapCategory(null), 'default');
    });
  });
}
