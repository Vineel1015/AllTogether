import 'package:flutter/material.dart';

import '../models/meal_model.dart';

/// A compact card showing a single meal with an optional remove button.
class MealTileWidget extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onRemove;

  const MealTileWidget({
    super.key,
    required this.meal,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Meal icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restaurant_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Name + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.calories} kcal · ${meal.prepMinutes} min',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Remove button
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove',
                color: colorScheme.error,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
