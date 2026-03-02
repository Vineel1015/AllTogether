/// Hardcoded sustainability fallback values used when Climatiq data is
/// unavailable. Values are per-kg of food item.
///
/// Sources: FAO / OurWorldInData averages (2023).
class SustainabilityConstants {
  SustainabilityConstants._();

  /// CO₂-equivalent emissions (kg CO₂e per kg of food).
  static const Map<String, double> co2ePerKgByCategory = {
    'meat': 27.0,
    'poultry': 6.9,
    'seafood': 6.1,
    'dairy': 3.2,
    'eggs': 4.5,
    'grains': 1.4,
    'vegetables': 2.0,
    'fruits': 1.1,
    'legumes': 0.9,
    'nuts': 2.3,
    'default': 2.5,
  };

  /// Fresh-water usage (litres per kg of food).
  static const Map<String, double> waterLitresPerKgByCategory = {
    'meat': 15400.0,
    'poultry': 4300.0,
    'seafood': 5000.0,
    'dairy': 1000.0,
    'eggs': 3300.0,
    'grains': 1600.0,
    'vegetables': 200.0,
    'fruits': 960.0,
    'legumes': 1800.0,
    'nuts': 9000.0,
    'default': 1000.0,
  };

  /// Land use (m² per kg of food).
  static const Map<String, double> landM2PerKgByCategory = {
    'meat': 164.0,
    'poultry': 7.1,
    'seafood': 3.7,
    'dairy': 8.9,
    'eggs': 5.7,
    'grains': 3.4,
    'vegetables': 0.3,
    'fruits': 0.5,
    'legumes': 2.2,
    'nuts': 7.9,
    'default': 5.0,
  };
}
