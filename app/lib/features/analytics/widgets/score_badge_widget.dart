import 'package:flutter/material.dart';

import '../models/sustainability_summary_model.dart';

/// Colored chip indicating the user's sustainability score.
///
/// Green  → avg CO₂e/day < 2.5 kg  ("Great")
/// Yellow → avg CO₂e/day ≤ 5.0 kg  ("Moderate")
/// Red    → avg CO₂e/day > 5.0 kg  ("High Impact")
class ScoreBadgeWidget extends StatelessWidget {
  final SustainabilitySummary summary;

  const ScoreBadgeWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (summary.scoreColor) {
      'green' => ('Great', Colors.green.shade100, Colors.green.shade800),
      'yellow' => ('Moderate', Colors.amber.shade100, Colors.amber.shade800),
      _ => ('High Impact', Colors.red.shade100, Colors.red.shade800),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          backgroundColor: bgColor,
          label: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'avg ${summary.avgCo2ePerDay.toStringAsFixed(1)} kg CO₂e/day',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
