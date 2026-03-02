import 'package:flutter/material.dart';

import '../models/sustainability_summary_model.dart';

/// Displays CO₂e, water, and land footprint as three list-tile rows.
class SustainabilityCardWidget extends StatelessWidget {
  final SustainabilitySummary summary;

  const SustainabilityCardWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Carbon footprint'),
            trailing: Text(
              '${summary.totalCo2eKg.toStringAsFixed(1)} kg CO₂e',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Water usage'),
            trailing: Text(
              '${(summary.totalWaterL / 1000).toStringAsFixed(1)} kL',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.landscape_outlined),
            title: const Text('Land use'),
            trailing: Text(
              '${summary.totalLandM2.toStringAsFixed(1)} m²',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
