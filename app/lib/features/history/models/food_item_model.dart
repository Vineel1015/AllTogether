/// Nutrition data for a food item, cached locally in Hive.
///
/// Sourced from Open Food Facts. Never synced to Supabase.
class FoodItem {
  /// Open Food Facts product ID or the normalized search term used as key.
  final String id;
  final String name;
  final String? barcode;

  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;

  /// CO₂ equivalent per kg — from Climatiq or hardcoded fallback (V2).
  final double? co2ePerKg;

  /// Water footprint per kg (V2).
  final double? waterPerKg;

  /// Land use per kg (V2).
  final double? landPerKg;

  /// Open Food Facts category tag (e.g. 'en:dairy').
  final String? category;

  final DateTime cachedAt;

  const FoodItem({
    required this.id,
    required this.name,
    this.barcode,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.co2ePerKg,
    this.waterPerKg,
    this.landPerKg,
    this.category,
    required this.cachedAt,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Constructs a [FoodItem] from an Open Food Facts product JSON map.
  factory FoodItem.fromOpenFoodFactsJson(
    Map<String, dynamic> product,
    String searchKey,
  ) {
    final nutriments =
        product['nutriments'] as Map<String, dynamic>? ?? {};

    return FoodItem(
      id: (product['id'] as String?) ?? searchKey,
      name: (product['product_name'] as String?) ?? searchKey,
      barcode: product['code'] as String?,
      caloriesPer100g:
          (nutriments['energy-kcal_100g'] as num?)?.toDouble(),
      proteinPer100g: (nutriments['proteins_100g'] as num?)?.toDouble(),
      carbsPer100g:
          (nutriments['carbohydrates_100g'] as num?)?.toDouble(),
      fatPer100g: (nutriments['fat_100g'] as num?)?.toDouble(),
      fiberPer100g: (nutriments['fiber_100g'] as num?)?.toDouble(),
      category: (product['categories_tags'] as List?)
          ?.whereType<String>()
          .firstOrNull,
      cachedAt: DateTime.now(),
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble(),
        proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
        carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
        fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
        fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
        co2ePerKg: (json['co2ePerKg'] as num?)?.toDouble(),
        waterPerKg: (json['waterPerKg'] as num?)?.toDouble(),
        landPerKg: (json['landPerKg'] as num?)?.toDouble(),
        category: json['category'] as String?,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );

  // ── Serializers ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (barcode != null) 'barcode': barcode,
        if (caloriesPer100g != null) 'caloriesPer100g': caloriesPer100g,
        if (proteinPer100g != null) 'proteinPer100g': proteinPer100g,
        if (carbsPer100g != null) 'carbsPer100g': carbsPer100g,
        if (fatPer100g != null) 'fatPer100g': fatPer100g,
        if (fiberPer100g != null) 'fiberPer100g': fiberPer100g,
        if (co2ePerKg != null) 'co2ePerKg': co2ePerKg,
        if (waterPerKg != null) 'waterPerKg': waterPerKg,
        if (landPerKg != null) 'landPerKg': landPerKg,
        if (category != null) 'category': category,
        'cachedAt': cachedAt.toIso8601String(),
      };
}
