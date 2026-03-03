import 'package:flutter/material.dart';

import '../models/meal_model.dart';
import '../services/meal_scoring_service.dart';

/// A DoorDash-style food card for the meal catalog.
///
/// Shows a gradient header with a category icon, the meal name, macros,
/// and an Add / Remove button.
class MealCatalogCard extends StatelessWidget {
  final Meal meal;

  /// Whether this meal is already in the user's weekly plan.
  final bool isInPlan;

  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const MealCatalogCard({
    super.key,
    required this.meal,
    required this.isInPlan,
    required this.onAdd,
    this.onRemove,
  });

  static const double cardWidth = 158;
  static const double _imageHeight = 112;

  @override
  Widget build(BuildContext context) {
    final (gradient, icon) = _visualsForMeal(meal);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: cardWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient image area ──────────────────────────────────
            Stack(
              children: [
                Container(
                  height: _imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: gradient),
                  child: Center(
                    child: Icon(icon, size: 46,
                        color: Colors.white.withAlpha(210)),
                  ),
                ),
                // Grade badge (top-left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _GradeBadge(meal: meal),
                ),
                // "In Plan" checkmark badge
                if (isInPlan)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle,
                          size: 16, color: colorScheme.primary),
                    ),
                  ),
              ],
            ),

            // ── Info area ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_outlined,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${meal.calories} kcal',
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${meal.prepMinutes} min',
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add / Remove button
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: isInPlan
                        ? OutlinedButton(
                            onPressed: onRemove,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(
                                  color: colorScheme.error, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              '− Remove',
                              style: TextStyle(
                                  fontSize: 11, color: colorScheme.error),
                            ),
                          )
                        : FilledButton(
                            onPressed: onAdd,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(fontSize: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('+ Add to Plan'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns (gradient, icon) based on the meal's category prefix.
  static (LinearGradient, IconData) _visualsForMeal(Meal meal) {
    if (meal.id.startsWith('preset_b')) {
      return (
        const LinearGradient(
            colors: [Color(0xFFFF9A3C), Color(0xFFFF6B35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        Icons.wb_sunny_outlined,
      );
    }
    if (meal.id.startsWith('preset_l')) {
      return (
        const LinearGradient(
            colors: [Color(0xFF90C253), Color(0xFF5F8A1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        Icons.lunch_dining_outlined,
      );
    }
    if (meal.id.startsWith('preset_d')) {
      return (
        const LinearGradient(
            colors: [Color(0xFF7B2DBF), Color(0xFF4C0089)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        Icons.dinner_dining_outlined,
      );
    }
    if (meal.id.startsWith('preset_s')) {
      return (
        const LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFE67E00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        Icons.apple_outlined,
      );
    }
    // User-created meals
    return (
      const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0277BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      Icons.restaurant_outlined,
    );
  }
}

// ── Grade badge ─────────────────────────────────────────────────────────────

class _GradeBadge extends StatelessWidget {
  final Meal meal;

  const _GradeBadge({required this.meal});

  static const _service = MealScoringService();

  @override
  Widget build(BuildContext context) {
    final score = _service.scoreMeal(meal);
    final color = score.gradeColor(Theme.of(context).colorScheme);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        score.grade,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
