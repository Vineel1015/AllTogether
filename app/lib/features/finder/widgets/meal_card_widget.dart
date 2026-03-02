import 'package:flutter/material.dart';

import '../models/meal_plan_model.dart';

/// Displays one day's worth of meals as an expandable card.
class MealCardWidget extends StatelessWidget {
  final DayPlan dayPlan;

  const MealCardWidget({super.key, required this.dayPlan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              dayPlan.day,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // Meal rows
          _MealRow(label: 'Breakfast', meal: dayPlan.breakfast, icon: Icons.wb_sunny_outlined),
          _MealRow(label: 'Lunch', meal: dayPlan.lunch, icon: Icons.lunch_dining_outlined),
          _MealRow(label: 'Dinner', meal: dayPlan.dinner, icon: Icons.dinner_dining_outlined),
          _MealRow(label: 'Snack', meal: dayPlan.snack, icon: Icons.apple_outlined),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String label;
  final MealEntry meal;
  final IconData icon;

  const _MealRow({
    required this.label,
    required this.meal,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ExpansionTile(
      leading: Icon(icon, size: 20),
      title: Text(
        meal.name.isEmpty ? label : meal.name,
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: meal.calories > 0
          ? Text(
              '${meal.calories} kcal · ${meal.prepMinutes} min',
              style: textTheme.bodySmall,
            )
          : null,
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
          : meal.ingredients
              .map(
                (ingredient) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ingredient, style: textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
