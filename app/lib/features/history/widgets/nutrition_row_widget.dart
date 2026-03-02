import 'package:flutter/material.dart';

import '../models/food_item_model.dart';

/// Compact row showing cal / protein / carbs / fat for a [FoodItem].
///
/// Displays "—" for any null nutriment value.
class NutritionRowWidget extends StatelessWidget {
  final FoodItem item;

  const NutritionRowWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Cell(label: 'Cal', value: item.caloriesPer100g),
          _Cell(label: 'Protein', value: item.proteinPer100g, unit: 'g'),
          _Cell(label: 'Carbs', value: item.carbsPer100g, unit: 'g'),
          _Cell(label: 'Fat', value: item.fatPer100g, unit: 'g'),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _Cell({
    required this.label,
    required this.value,
    this.unit = 'kcal',
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.toStringAsFixed(1)} $unit'
        : '—';

    return Column(
      children: [
        Text(
          display,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
