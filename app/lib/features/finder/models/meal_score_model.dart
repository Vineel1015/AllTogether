import 'package:flutter/material.dart';

/// Composite quality score for a single meal.
///
/// [healthScore] and [sustainabilityScore] are each 0–100.
/// [compositeScore] is their average.
/// [grade] is 'A'–'F' derived from [compositeScore].
class MealScore {
  final double healthScore;
  final double sustainabilityScore;
  final double compositeScore;
  final String grade;

  const MealScore({
    required this.healthScore,
    required this.sustainabilityScore,
    required this.compositeScore,
    required this.grade,
  });

  factory MealScore.fromScores(double health, double sustainability) {
    final composite = (health + sustainability) / 2;
    return MealScore(
      healthScore: health,
      sustainabilityScore: sustainability,
      compositeScore: composite,
      grade: _gradeFromScore(composite),
    );
  }

  static String _gradeFromScore(double score) {
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'F';
  }

  /// Returns a colour appropriate for the grade.
  Color gradeColor(ColorScheme cs) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow.shade700;
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String get gradeDescription {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Good';
      case 'C':
        return 'Fair';
      case 'D':
        return 'Poor';
      default:
        return 'Very Poor';
    }
  }
}
