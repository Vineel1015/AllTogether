/// Aggregated sustainability metrics for the analysis period.
///
/// Uses hardcoded [SustainabilityConstants] fallback values —
/// Climatiq API integration is deferred to Session 6.
///
/// Score thresholds (avg CO₂e/day):
///   green  < 2.5 kg/day
///   yellow ≤ 5.0 kg/day
///   red    > 5.0 kg/day
class SustainabilitySummary {
  final double totalCo2eKg;
  final double totalWaterL;
  final double totalLandM2;
  final double avgCo2ePerDay;

  /// One of `'green'`, `'yellow'`, or `'red'`.
  final String scoreColor;

  const SustainabilitySummary({
    required this.totalCo2eKg,
    required this.totalWaterL,
    required this.totalLandM2,
    required this.avgCo2ePerDay,
    required this.scoreColor,
  });
}
