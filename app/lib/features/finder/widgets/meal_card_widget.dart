import 'package:flutter/material.dart';

import '../models/meal_model.dart';

/// Displays a meal as an expandable card showing ingredients.
class MealCardWidget extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onRemove;

  const MealCardWidget({super.key, required this.meal, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    meal.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: colorScheme.onPrimaryContainer),
                    iconSize: 20,
                    tooltip: 'Remove',
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
          // Expand to show ingredients
          ExpansionTile(
            leading: const Icon(Icons.restaurant_outlined, size: 20),
            title: Text(
              '${meal.calories} kcal · ${meal.prepMinutes} min',
              style: textTheme.bodySmall,
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: meal.ingredients.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('No ingredients listed.',
                          style: textTheme.bodySmall),
                    ),
                  ]
                : [
                    ...meal.ingredients.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ingredient,
                                  style: textTheme.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
          ),
        ],
      ),
    );
  }
}
