import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../providers/stores_provider.dart';
import '../providers/weekly_plan_provider.dart';
import '../widgets/meal_picker_sheet.dart';
import '../widgets/meal_tile_widget.dart';
import '../widgets/store_card_widget.dart';

/// The Finder tab — shows the user's curated weekly meal list and shopping list.
class FinderScreen extends ConsumerWidget {
  const FinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyPlanNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("This Week's Meals"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add meal',
              onPressed: () {
                final container = ProviderScope.containerOf(context);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => UncontrolledProviderScope(
                    container: container,
                    child: const MealPickerSheet(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Meals'),
              Tab(
                  icon: Icon(Icons.shopping_cart_outlined),
                  text: 'Shopping'),
            ],
          ),
        ),
        body: planAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => _ErrorBody(error: error, ref: ref),
          data: (plan) => _PlanBody(
            meals: plan?.meals ?? const [],
            shoppingList: plan?.shoppingList ?? const [],
          ),
        ),
      ),
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorBody({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load your meal plan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => ref.invalidate(weeklyPlanNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main plan body ───────────────────────────────────────────────────────────

class _PlanBody extends ConsumerWidget {
  final List<dynamic> meals;
  final List<String> shoppingList;

  const _PlanBody({required this.meals, required this.shoppingList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return Column(
      children: [
        // Nearby stores strip (hidden when empty)
        storesAsync.maybeWhen(
          data: (stores) => stores.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: stores.length,
                    itemBuilder: (_, i) =>
                        StoreCardWidget(store: stores[i]),
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            children: [
              // Meals tab
              _MealsTab(meals: meals),
              // Shopping tab
              _ShoppingTab(items: shoppingList),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealsTab extends ConsumerWidget {
  final List<dynamic> meals;

  const _MealsTab({required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Tap + to add meals to your week.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: meals.length,
      itemBuilder: (_, i) {
        final meal = meals[i];
        return MealTileWidget(
          meal: meal,
          onRemove: () => ref
              .read(weeklyPlanNotifierProvider.notifier)
              .removeMeal(meal.id),
        );
      },
    );
  }
}

class _ShoppingTab extends StatelessWidget {
  final List<String> items;

  const _ShoppingTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Add meals to see your shopping list.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                items[i],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
