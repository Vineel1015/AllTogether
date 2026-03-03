import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_model.dart';
import '../models/preset_meals.dart';
import '../providers/meal_catalog_provider.dart';
import '../providers/weekly_plan_provider.dart';
import 'create_meal_sheet.dart';

/// Bottom sheet that lets the user pick a meal to add to the weekly plan.
class MealPickerSheet extends ConsumerStatefulWidget {
  const MealPickerSheet({super.key});

  @override
  ConsumerState<MealPickerSheet> createState() => _MealPickerSheetState();
}

class _MealPickerSheetState extends ConsumerState<MealPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allMealsAsync = ref.watch(allMealsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const _SheetHandle(),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Add a Meal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search meals…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            // List
            Expanded(
              child: allMealsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Failed to load meals: $e')),
                data: (meals) {
                  final presets = presetMeals
                      .where((m) =>
                          _query.isEmpty ||
                          m.name.toLowerCase().contains(_query))
                      .toList();
                  final custom = meals
                      .where((m) =>
                          !m.isPreset &&
                          (_query.isEmpty ||
                              m.name.toLowerCase().contains(_query)))
                      .toList();

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (presets.isNotEmpty) ...[
                        const _SectionHeader(title: 'Preset Meals'),
                        ...presets.map((m) => _MealPickerTile(meal: m)),
                      ],
                      if (custom.isNotEmpty) ...[
                        const _SectionHeader(title: 'My Meals'),
                        ...custom.map((m) => _MealPickerTile(meal: m)),
                      ],
                      if (presets.isEmpty && custom.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No meals found.')),
                        ),
                    ],
                  );
                },
              ),
            ),
            // Create new meal button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Meal'),
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const CreateMealSheet(),
                    );
                    // Refresh user meals after creation
                    ref.invalidate(userMealsProvider);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _MealPickerTile extends ConsumerWidget {
  final Meal meal;

  const _MealPickerTile({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: const Icon(Icons.restaurant_outlined),
      title: Text(meal.name),
      subtitle: Text('${meal.calories} kcal · ${meal.prepMinutes} min'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        color: Theme.of(context).colorScheme.primary,
        tooltip: 'Add to plan',
        onPressed: () async {
          await ref
              .read(weeklyPlanNotifierProvider.notifier)
              .addMeal(meal);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      onTap: () async {
        await ref
            .read(weeklyPlanNotifierProvider.notifier)
            .addMeal(meal);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
