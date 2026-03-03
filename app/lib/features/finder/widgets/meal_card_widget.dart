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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildChip(Icons.local_fire_department_rounded,
                              '${meal.calories} kcal', Colors.orange),
                          const SizedBox(width: 8),
                          _buildChip(Icons.schedule_rounded,
                              '${meal.prepMinutes}m', Colors.blueGrey),
                          if (meal.price != null) ...[
                            const SizedBox(width: 8),
                            _buildChip(Icons.payments_rounded,
                                '\$${meal.price!.toStringAsFixed(2)}', Colors.green),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    iconSize: 22,
                    splashRadius: 24,
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
          // Expand to show ingredients
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              dense: true,
              title: const Text(
                'Ingredients & Preparation',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey),
              ),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: meal.ingredients.isEmpty
                  ? [
                      const Text('No ingredients listed.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]
                  : [
                      ...meal.ingredients.map(
                        (ingredient) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: Colors.green[300]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
